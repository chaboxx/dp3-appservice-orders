"""Tokens de prueba firmados con una clave RSA local (sin Entra ni red)."""

import time

import jwt
from cryptography.hazmat.primitives.asymmetric import rsa
from jwt.algorithms import RSAAlgorithm

from app.auth.validator import TokenValidator

ISSUER = "https://11111111-1111-1111-1111-111111111111.ciamlogin.com/11111111-1111-1111-1111-111111111111/v2.0"
AUDIENCE = "api-client-id"
TENANT_ID = "11111111-1111-1111-1111-111111111111"
USER_OID = "22222222-2222-2222-2222-222222222222"

PRIVATE_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
OTHER_KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)


class LocalKeys:
    """Reemplaza a PyJWKClient: siempre devuelve la clave pública de PRIVATE_KEY."""

    def __init__(self) -> None:
        self._jwk = jwt.PyJWK(RSAAlgorithm.to_jwk(PRIVATE_KEY.public_key(), as_dict=True))

    def get_signing_key_from_jwt(self, token: str) -> jwt.PyJWK:
        return self._jwk


def make_token(key: rsa.RSAPrivateKey = PRIVATE_KEY, **claims: object) -> str:
    """Token válido; cualquier claim se puede cambiar con **claims."""
    now = int(time.time())
    payload = {
        "iss": ISSUER,
        "aud": AUDIENCE,
        "tid": TENANT_ID,
        "oid": USER_OID,
        "iat": now,
        "exp": now + 3600,
        "scp": "Orders.ReadWrite",
        "email": "ana@example.com",
    }
    payload.update(claims)
    return jwt.encode(payload, key, algorithm="RS256")


def make_validator() -> TokenValidator:
    return TokenValidator(ISSUER, AUDIENCE, LocalKeys())
