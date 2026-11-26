from typing import Literal
from uuid import UUID
from app.schemas.clinical import Extraction


class ExtractionResponse(Extraction):
    request_id: UUID
    status: Literal["success"] = "success"
    schema_version: Literal["1.0"] = "1.0"
    prompt_version: Literal["clinical_extraction_v1"] = "clinical_extraction_v1"
    provider: Literal["mock", "gemini"]
    model_name: str
