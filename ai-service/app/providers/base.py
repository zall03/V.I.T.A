from typing import Protocol
from app.schemas.clinical import Extraction


class Provider(Protocol):
    name: str
    model: str

    async def extract(self, transcript: str, language: str) -> Extraction: ...
    async def close(self) -> None: ...
