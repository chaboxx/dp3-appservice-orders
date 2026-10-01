"""Tests HTTP de /api/v1/me."""

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app
from tests.auth.tokens import TENANT_ID, USER_OID, make_token, make_validator

URL = "/api/v1/me"


@pytest.fixture
def client() -> TestClient:
    app = create_app(Settings())
    app.state.token_validator = make_validator()  # claves locales en vez de Entra
    return TestClient(app)


def test_me_returns_the_user_from_the_token(client: TestClient) -> None:
    token = make_token(name="Ana Pérez", given_name="Ana", family_name="Pérez", city="Lima")

    response = client.get(URL, headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert response.json() == {
        "id": response.json()["id"],
        "object_id": USER_OID,
        "tenant_id": TENANT_ID,
        "email": "ana@example.com",
        "name": "Ana Pérez",
        "given_name": "Ana",
        "family_name": "Pérez",
        "city": "Lima",
        "scopes": ["Orders.ReadWrite"],
    }


def test_me_creates_the_user_once(client: TestClient) -> None:
    headers = {"Authorization": f"Bearer {make_token()}"}

    first = client.get(URL, headers=headers).json()["id"]
    second = client.get(URL, headers=headers).json()["id"]

    assert first == second
    assert len(client.app.state.user_repository._users) == 1


def test_me_requires_the_email_claim(client: TestClient) -> None:
    response = client.get(URL, headers={"Authorization": f"Bearer {make_token(email=None)}"})

    assert response.status_code == 403
    assert response.json()["detail"] == "The access token must include the email claim"


def test_me_requires_a_token(client: TestClient) -> None:
    response = client.get(URL)

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


def test_me_optional_claims_are_null_when_missing(client: TestClient) -> None:
    response = client.get(URL, headers={"Authorization": f"Bearer {make_token()}"})

    body = response.json()
    assert body["given_name"] is None
    assert body["family_name"] is None
    assert body["city"] is None
