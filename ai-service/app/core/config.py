from typing import Literal
from pydantic import Field, SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=None, extra="ignore")
    ai_provider: Literal["mock", "gemini"] = "mock"
    ai_service_token: SecretStr
    ai_schema_version: Literal["1.0"] = "1.0"
    ai_prompt_version: Literal["clinical_extraction_v1"] = "clinical_extraction_v1"
    ai_max_transcript_length: int = Field(default=8000, ge=1, le=8000)
    external_ai_enabled: bool = False
    gemini_api_key: SecretStr = SecretStr("")
    gemini_model: str = ""
    gemini_timeout_seconds: float = Field(default=20, gt=0, le=25)
    gemini_max_attempts: int = Field(default=2, ge=1, le=2)

    @model_validator(mode="after")
    def credentials(self):
        if len(self.ai_service_token.get_secret_value()) < 32:
            raise ValueError("service credential must contain at least 32 characters")
        if self.ai_provider == "gemini" and (
            not self.external_ai_enabled
            or not self.gemini_api_key.get_secret_value()
            or not self.gemini_model.strip()
        ):
            raise ValueError("external AI requires explicit enablement, key and model")
        return self
