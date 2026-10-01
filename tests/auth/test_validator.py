import time
from uuid import UUID

import pytest

from app.auth.config import AuthSettings
from app.auth.exceptions import InvalidToken
from app.auth.validator import TokenValidator, build_token_validator
from tests.auth.tokens import OTHER_KEY, USER_OID, make_token, make_validator


def test_valid_token() -> None:
    principal = make_validator().validate(make_token())

    assert principal.object_id == UUID(USER_OID)
    assert principal.email == "ana@example.com"
    assert "Orders.ReadWrite" in principal.scopes


@pytest.mark.parametrize(
    ("claims", "expected"),
    [
        pytest.param({"name": "Ana Pérez"}, "Ana Pérez", id="name-from-entra"),
        pytest.param(
            {"name": "unknown", "given_name": "RODRIGO", "family_name": "CUEVA PASTOR"},
            "RODRIGO CUEVA PASTOR",
            id="unknown-uses-given-and-family-name",
        ),
        pytest.param({"given_name": "Ana"}, "Ana", id="missing-name-uses-given-name"),
        pytest.param({"name": "unknown"}, None, id="unknown-without-names-is-null"),
    ],
)
def test_display_name(claims: dict[str, str], expected: str | None) -> None:
    principal = make_validator().validate(make_token(**claims))

    assert principal.name == expected


@pytest.mark.parametrize(
    "token",
    [
        pytest.param(make_token(exp=int(time.time()) - 3600), id="expired"),
        pytest.param(make_token(aud="otra-api"), id="wrong-audience"),
        pytest.param(make_token(iss="https://evil.example.com/v2.0"), id="wrong-issuer"),
        pytest.param(make_token(key=OTHER_KEY), id="wrong-signature"),
        pytest.param(make_token(oid=None), id="missing-oid"),
        pytest.param("no-es-un-jwt", id="malformed"),
    ],
)
def test_invalid_tokens_are_rejected(token: str) -> None:
    with pytest.raises(InvalidToken):
        make_validator().validate(token)


def test_build_without_config_returns_none() -> None:
    assert build_token_validator(AuthSettings()) is None


def test_build_with_config() -> None:
    settings = AuthSettings(
        issuer="https://tenant.ciamlogin.com/tenant/v2.0",
        jwks_uri="https://tenant.ciamlogin.com/tenant/discovery/v2.0/keys",
        audience="api-client-id",
    )

    assert isinstance(build_token_validator(settings), TokenValidator)


def test_build_with_incomplete_config_fails() -> None:
    with pytest.raises(ValueError, match="APP_AUTH_AUDIENCE"):
        build_token_validator(AuthSettings(issuer="https://tenant.ciamlogin.com/tenant/v2.0"))
