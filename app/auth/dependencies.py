"""Dependencias de autenticación y autorización para los endpoints.

Uso:
    def endpoint(principal: CurrentPrincipal): ...                  # cualquier token válido
    @router.get(..., dependencies=[Depends(require_scope("Orders.ReadWrite"))])
"""

import logging
from collections.abc import Callable
from typing import Annotated

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.auth.exceptions import Forbidden, InvalidToken, NotAuthenticated
from app.auth.schemas import Principal
from app.auth.validator import TokenValidator

logger = logging.getLogger(__name__)

# auto_error=False: si falta el header respondemos nosotros (401 en Problem Details).
# Además agrega el botón "Authorize" en /docs.
bearer_scheme = HTTPBearer(auto_error=False)


def get_token_validator(request: Request) -> TokenValidator | None:
    # Una instancia por app (se crea en create_app): la caché de claves JWKS se reutiliza
    return request.app.state.token_validator


def get_principal(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    validator: Annotated[TokenValidator | None, Depends(get_token_validator)],
) -> Principal:
    if credentials is None:
        raise NotAuthenticated()
    if validator is None:
        logger.info("Token rejected: Entra External ID not configured (APP_AUTH_*)")
        raise InvalidToken()
    return validator.validate(credentials.credentials)


CurrentPrincipal = Annotated[Principal, Depends(get_principal)]


def require_scope(scope: str) -> Callable[[Principal], Principal]:
    """Exige un scope delegado (claim scp), p. ej. Orders.ReadWrite."""

    def dependency(principal: CurrentPrincipal) -> Principal:
        if scope not in principal.scopes:
            raise Forbidden(f"Missing required scope: {scope}")
        return principal

    return dependency
