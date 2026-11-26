from typing import Literal
from uuid import UUID
from pydantic import Field, field_validator
from app.schemas.clinical import StrictModel


class ExtractionRequest(StrictModel):
    request_id: UUID
    encounter_id: UUID
    language: Literal["id-ID", "en-US"]
    schema_version: Literal["1.0"]
    transcript: str = Field(min_length=1, max_length=8000)

    @field_validator("transcript")
    @classmethod
    def non_blank(cls, value):
        if not value.strip():
            raise ValueError("blank transcript")
        return value
