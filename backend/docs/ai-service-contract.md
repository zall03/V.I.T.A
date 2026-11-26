# Internal AI contract

`POST /internal/v1/clinical/extract`, Authorization `Bearer <AI_SERVICE_TOKEN>`.
Constant-time credential comparison. No browser access, no published Compose port.

Request fields: request_id UUID, encounter_id UUID, language id-ID/en-US,
schema_version exactly 1.0, transcript 1–8000 characters (nonblank).
Correlation IDs stay within Go/FastAPI, never passed to Gemini.

Response fields: request_id, status=success, schema_version=1.0,
prompt_version=clinical_extraction_v1, provider, model_name, data, evidence,
missing_fields, warnings, requires_verification=true.

Errors use `{error:{code,message},request_id}`. 401 internal credential invalid;
422 request invalid; 413 size limit; 502 malformed/provider credential failure;
503 rate-limited/unavailable provider; 504 timeout. Errors contain no transcript,
validation input, provider response or credentials. Health readiness checks local
configuration/startup, not live Gemini availability.

Generate complete FastAPI OpenAPI: `python export_openapi.py` in ai-service.
Go validates bounded response, strict fields, correlation ID, versions, required
verification flag and clinical units/availability before persistence.
