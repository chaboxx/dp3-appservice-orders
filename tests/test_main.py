import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


def make_client(settings: Settings) -> TestClient:
    return TestClient(create_app(settings))


def test_read_root() -> None:
    client = make_client(Settings(env="dev"))

    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {"message": "Hola desde dp3-appservice-orders", "env": "dev"}


def test_docs_enabled() -> None:
    client = make_client(Settings(docs_enabled=True))

    assert client.get("/docs").status_code == 200
    assert client.get("/openapi.json").status_code == 200


def test_docs_disabled() -> None:
    client = make_client(Settings(env="prod", docs_enabled=False))

    assert client.get("/docs").status_code == 404
    assert client.get("/openapi.json").status_code == 404


def test_settings_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "prod")
    monkeypatch.setenv("APP_DOCS_ENABLED", "false")

    settings = Settings()

    assert settings.env == "prod"
    assert settings.docs_enabled is False
