from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


def test_unhandled_error_returns_problem_details() -> None:
    app = create_app(Settings())

    # Ruta solo para el test: simula un bug que nadie capturó
    @app.get("/boom")
    def boom() -> None:
        raise RuntimeError("database password is 1234")

    # Sin esto, TestClient relanza la excepción en vez de devolver la respuesta
    client = TestClient(app, raise_server_exceptions=False)

    response = client.get("/boom")

    assert response.status_code == 500
    assert response.headers["content-type"] == "application/problem+json"
    assert response.json() == {
        "type": "about:blank",
        "title": "Internal Server Error",
        "status": 500,
        "detail": "An unexpected error occurred.",
        "instance": "/boom",
    }
    # El detalle interno queda en los logs, nunca en la respuesta
    assert "1234" not in response.text


def test_not_found_returns_problem_details() -> None:
    client = TestClient(create_app(Settings()))

    response = client.get("/no-existe")

    assert response.status_code == 404
    assert response.headers["content-type"] == "application/problem+json"
    assert response.json() == {
        "type": "about:blank",
        "title": "Not Found",
        "status": 404,
        "detail": "Not Found",
        "instance": "/no-existe",
    }
