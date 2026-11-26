import asyncio
from pathlib import Path
import httpx
from google import genai
from google.genai import errors, types
from pydantic import ValidationError
from app.core.exceptions import ProviderFailure
from app.schemas.clinical import Extraction


class GeminiProvider:
    name = "gemini"

    def __init__(self, settings, client=None):
        self.model = settings.gemini_model
        self.timeout = settings.gemini_timeout_seconds
        self.client = client or genai.Client(
            api_key=settings.gemini_api_key.get_secret_value(),
            http_options=types.HttpOptions(timeout=int(self.timeout * 1000),
                                          retry_options=types.HttpRetryOptions(attempts=1)),
        )
        self.prompt = (Path(__file__).parents[1] / "prompts" / "clinical_extraction_v1.txt").read_text(encoding="utf-8")

    async def extract(self, transcript, language):
        try:
            async with asyncio.timeout(self.timeout):
                response = await self.client.aio.models.generate_content(
                    model=self.model,
                    contents=types.Content(role="user", parts=[types.Part.from_text(text=transcript)]),
                    config=types.GenerateContentConfig(
                        system_instruction=self.prompt, response_mime_type="application/json",
                        response_json_schema=Extraction.model_json_schema(),
                        automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True),
                    ),
                )
            if not response.text:
                raise ProviderFailure("provider_empty_response")
            if len(response.text.encode("utf-8")) > 128 * 1024:
                raise ProviderFailure("provider_response_too_large")
            return Extraction.model_validate_json(response.text)
        except (TimeoutError, httpx.TimeoutException):
            raise ProviderFailure("provider_timeout", 504, True) from None
        except httpx.TransportError:
            raise ProviderFailure("provider_unavailable", 503, True) from None
        except ValidationError:
            raise ProviderFailure("provider_invalid_schema") from None
        except errors.APIError as exc:
            code = int(exc.code or 500)
            if code in (401, 403):
                raise ProviderFailure("provider_credentials_invalid", 502) from None
            retry_after = 0
            response = getattr(exc, "response", None)
            if response is not None:
                try:
                    retry_after = max(0, float(response.headers.get("Retry-After", 0)))
                except (ValueError, TypeError):
                    pass
            raise ProviderFailure("provider_rate_limited" if code == 429 else "provider_failed",
                                  503 if code == 429 or code >= 500 else 502,
                                  code == 429 or code >= 500, retry_after) from None

    async def close(self):
        await self.client.aio.aclose()
        self.client.close()
