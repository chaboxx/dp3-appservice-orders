"""Tests HTTP: cómo responde un endpoint protegido según el token."""

import pytest
from fastapi import Depends
from fastapi.testclient import TestClient

from app.auth.dependencies import CurrentPrincipal, require_scope
from app.config import Settings
from app.main import create_app
from tests.auth.tokens import USER_OID, make_token, make_validator


@pytest.fixture
def client() -> TestClient:
    app = create_app(Settings())
    app.state.token_validator = make_validator()  # claves locales en vez de Entra

    # Rutas solo para el test
    @app.get("/me")
    def me(principal: CurrentPrincipal) -> dict[str, str]:
        return {"oid": str(principal.object_id)}

    @app.get("/orders-scope", dependencies=[Depends(require_scope("Orders.ReadWrite"))])
    def with_scope() -> None: ...

    return TestClient(app)


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_valid_token(client: TestClient) -> None:
    response = client.get("/me", headers=bearer(make_token()))

    assert response.status_code == 200
    assert response.json() == {"oid": USER_OID}


def test_missing_token_returns_401(client: TestClient) -> None:
    response = client.get("/me")

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"
    assert response.headers["content-type"] == "application/problem+json"


def test_invalid_token_returns_401(client: TestClient) -> None:
    response = client.get("/me", headers=bearer("no-es-un-jwt"))

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == 'Bearer error="invalid_token"'


def test_scope_check(client: TestClient) -> None:
    with_scope = bearer(make_token())
    without_scope = bearer(make_token(scp=""))

    assert client.get("/orders-scope", headers=with_scope).status_code == 200
    assert client.get("/orders-scope", headers=without_scope).status_code == 403


def test_without_auth_config_every_token_is_rejected(client: TestClient) -> None:
    client.app.state.token_validator = None  # sin APP_AUTH_* configuradas

    response = client.get("/me", headers=bearer(make_token()))

    assert response.status_code == 401
