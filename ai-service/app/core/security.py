import secrets
from fastapi import Request
from app.core.exceptions import ProviderFailure


def authenticate(request: Request):
    supplied = request.headers.get("Authorization", "")
    expected = "Bearer " + request.app.state.settings.ai_service_token.get_secret_value()
    if not secrets.compare_digest(supplied.encode(), expected.encode()):
        raise ProviderFailure("unauthorized", 401)
