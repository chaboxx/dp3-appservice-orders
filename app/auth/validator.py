"""Validación de access tokens (JWT) emitidos por Entra External ID.

La API no llama a Entra en cada request: verifica la firma con las claves públicas del tenant
(JWKS, que PyJWKClient descarga y guarda en caché) y luego los claims.
"""

import logging
from typing import Protocol
from uuid import UUID

import jwt

from app.auth.config import AuthSettings
from app.auth.exceptions import InvalidToken
from app.auth.schemas import Principal

logger = logging.getLogger(__name__)

# Margen para diferencias de reloj entre Entra y el servidor
CLOCK_SKEW_SECONDS = 60


class SigningKeys(Protocol):
    """Lo que necesitamos de PyJWKClient; en los tests se reemplaza por claves locales."""

    def get_signing_key_from_jwt(self, token: str) -> jwt.PyJWK: ...


class TokenValidator:
    def __init__(self, issuer: str, audience: str, keys: SigningKeys) -> None:
        self._issuer = issuer
        self._audience = audience
        self._keys = keys

    def validate(self, token: str) -> Principal:
        try:
            signing_key = self._keys.get_signing_key_from_jwt(token)
            claims = jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256"],
                issuer=self._issuer,
                audience=self._audience,
                leeway=CLOCK_SKEW_SECONDS,
                options={"require": ["exp", "iss", "aud", "tid", "oid"]},
            )
        except jwt.PyJWTError as exc:
            logger.info("Token rejected: %s", exc)
            raise InvalidToken() from exc

        return Principal(
            tenant_id=UUID(claims["tid"]),
            object_id=UUID(claims["oid"]),
            email=claims.get("email"),
            name=claims.get("name"),
            scopes=frozenset(claims.get("scp", "").split()),
        )


def build_token_validator(settings: AuthSettings) -> TokenValidator | None:
    """Arma el validador del tenant configurado. None si no hay configuración:
    en ese caso la API arranca, pero rechaza todos los tokens."""
    values = (settings.issuer, settings.jwks_uri, settings.audience)
    if not any(values):
        logger.warning("Entra External ID not configured (APP_AUTH_*): every token is rejected")
        return None
    if not all(values):
        raise ValueError("APP_AUTH_ISSUER, APP_AUTH_JWKS_URI and APP_AUTH_AUDIENCE are required")
    return TokenValidator(settings.issuer, settings.audience, jwt.PyJWKClient(settings.jwks_uri))
