import time

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


def test_starts_without_database(caplog: pytest.LogCaptureFixture) -> None:
    # `with` ejecuta el arranque (lifespan), que es donde se prueba la conexión
    app = create_app(Settings())
    with TestClient(app) as client:
        assert client.get("/health").status_code == 200
        app.state.db_check.join(timeout=5)  # la prueba corre en segundo plano

    assert "Database not configured" in caplog.text


def test_slow_database_does_not_delay_startup(monkeypatch: pytest.MonkeyPatch) -> None:
    # Una base que no responde no puede retrasar el arranque: App Service mataría el contenedor
    monkeypatch.setattr("app.main.check_database", lambda engine: time.sleep(3))
    started = time.monotonic()

    with TestClient(create_app(Settings())) as client:
        assert client.get("/health").status_code == 200
        assert time.monotonic() - started < 1
