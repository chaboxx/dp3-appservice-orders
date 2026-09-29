import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


@pytest.fixture
def client() -> TestClient:
    """Cliente contra una app nueva: cada test arranca con el repositorio vacío."""
    return TestClient(create_app(Settings()))
