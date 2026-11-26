import asyncio
import random
from app.core.exceptions import ProviderFailure
from app.validators.clinical_validator import validate_evidence


class ExtractionService:
    def __init__(self, provider, settings):
        self.provider = provider
        self.settings = settings

    async def extract(self, request):
        for attempt in range(self.settings.gemini_max_attempts):
            try:
                result = await self.provider.extract(request.transcript, request.language)
                return validate_evidence(result, request.transcript)
            except ProviderFailure as exc:
                if not exc.retryable or attempt + 1 >= self.settings.gemini_max_attempts:
                    raise
                delay = max(exc.retry_after, 0.5 * 2 ** attempt + random.uniform(0, 0.25))
                if delay > 5:
                    raise
                await asyncio.sleep(delay)
