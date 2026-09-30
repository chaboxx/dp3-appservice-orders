from app.errors import DomainError


class NotAuthenticated(DomainError):
    status_code = 401
    headers = {"WWW-Authenticate": "Bearer"}

    def __init__(self) -> None:
        super().__init__("Missing bearer token")


class InvalidToken(DomainError):
    """El motivo exacto (expirado, firma, audience...) va a los logs, no al cliente."""

    status_code = 401
    headers = {"WWW-Authenticate": 'Bearer error="invalid_token"'}

    def __init__(self) -> None:
        super().__init__("Invalid or expired token")


class Forbidden(DomainError):
    status_code = 403

    def __init__(self, detail: str) -> None:
        super().__init__(detail)
