# V.I.T.A. AI service

Stateless internal FastAPI service. No database connection. Default provider is a
conservative synthetic fixture mock, not a clinical model. Go owns persistence,
authorization, redaction, job lifecycle and human verification.

Python 3.13 container; Python 3.14 used for local tests.

```sh
python -m venv .venv
# Activate virtual environment using your shell's activation command.
python -m pip install -r requirements.txt
# Export AI_SERVICE_TOKEN (random, at least 32 characters).
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --no-access-log
python -m pytest -q
python evaluate.py
python export_openapi.py
```

Compose configuration lives in `../backend/docker-compose.yml`. FastAPI has no
published port. Swagger UI and OpenAPI HTTP routes are disabled. Generate the
internal contract with `export_openapi.py`; keep it within internal tooling.

Gemini requires `AI_PROVIDER=gemini`, `EXTERNAL_AI_ENABLED=true`, `GEMINI_API_KEY`
and an explicitly selected `GEMINI_MODEL` supporting structured JSON output.
No model is presumed to be the latest. SDK methods follow official documentation:
https://googleapis.github.io/python-genai/ . Actual model availability and access
must be checked with the provider. No live Gemini test has been performed.

See backend `docs/security-and-privacy.md` before external processing. Use synthetic
data by default. Never enable external processing of real patient data without
institutional approval and appropriate privacy/provider/contractual review.
