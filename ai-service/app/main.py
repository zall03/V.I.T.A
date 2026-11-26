from contextlib import asynccontextmanager
import json
import logging
import time
from uuid import uuid4
from fastapi import Depends, FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from app.core.config import Settings
from app.core.exceptions import ProviderFailure
from app.core.security import authenticate
from app.providers.mock import MockProvider
from app.schemas.request import ExtractionRequest
from app.schemas.response import ExtractionResponse
from app.services.extraction_service import ExtractionService


def create_app(settings=None, provider=None):
    @asynccontextmanager
    async def lifespan(app):
        config = settings or Settings()
        selected = provider
        if selected is None:
            if config.ai_provider == "gemini":
                from app.providers.gemini import GeminiProvider
                selected = GeminiProvider(config)
            else:
                selected = MockProvider()
        app.state.settings = config
        app.state.provider = selected
        app.state.service = ExtractionService(selected, config)
        # SDK/httpx informational logs may contain URLs. Only application metadata is logged.
        for name in ("httpx", "httpcore", "google"):
            logging.getLogger(name).setLevel(logging.CRITICAL)
        try:
            yield
        finally:
            await selected.close()

    app = FastAPI(title="V.I.T.A. Internal AI", version="1.0.0", lifespan=lifespan,
                  docs_url=None, redoc_url=None, openapi_url=None)

    def error(request, status, code):
        return JSONResponse(status_code=status, content={"error": {"code": code, "message": code},
                            "request_id": getattr(request.state, "request_id", str(uuid4()))})

    @app.middleware("http")
    async def guard(request, call_next):
        request.state.request_id = str(uuid4())
        started = time.monotonic()
        size = 0
        chunks = []
        async for chunk in request.stream():
            size += len(chunk)
            if size > 48 * 1024:
                return error(request, 413, "request_too_large")
            chunks.append(chunk)
        request._body = b"".join(chunks)
        try:
            response = await call_next(request)
        except Exception:
            response = error(request, 500, "internal_error")
        logging.getLogger("vita.ai").info(json.dumps({"event": "http_request", "request_id": request.state.request_id,
             "status": response.status_code, "duration_ms": round((time.monotonic() - started) * 1000)}))
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Request-ID"] = request.state.request_id
        return response

    @app.exception_handler(ProviderFailure)
    async def provider_error(request, exc):
        return error(request, exc.status, exc.code)

    @app.exception_handler(RequestValidationError)
    async def validation_error(request, exc):
        return error(request, 422, "invalid_request")

    @app.get("/health/live")
    async def live():
        return {"status": "alive"}

    @app.get("/health/ready")
    async def ready():
        return {"status": "ready"}

    @app.post("/internal/v1/clinical/extract", response_model=ExtractionResponse,
              dependencies=[Depends(authenticate)])
    async def extract(body: ExtractionRequest, request: Request):
        if len(body.transcript) > request.app.state.settings.ai_max_transcript_length:
            raise ProviderFailure("transcript_too_long", 422)
        result = await request.app.state.service.extract(body)
        selected = request.app.state.provider
        return ExtractionResponse(**result.model_dump(), request_id=body.request_id,
                                  provider=selected.name, model_name=selected.model)

    return app


app = create_app()
