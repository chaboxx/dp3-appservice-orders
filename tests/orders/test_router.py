"""Tests HTTP del módulo de órdenes: auth, validaciones del contrato y respuestas."""

from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app
from app.orders.models import Product
from tests.auth.tokens import make_token, make_validator

URL = "/api/v1/orders"
ANA = {"Authorization": f"Bearer {make_token()}"}
LUIS = {"Authorization": f"Bearer {make_token(oid=str(uuid4()), email='luis@example.com')}"}


@pytest.fixture
def client() -> TestClient:
    app = create_app(Settings())
    app.state.token_validator = make_validator()  # claves locales en vez de Entra
    return TestClient(app)


@pytest.fixture
def product(client: TestClient) -> Product:
    """Producto con stock 10 en el repositorio en memoria de la app del test."""
    repository = client.app.state.product_repository
    return repository.add(Product(name="Teclado", price=Decimal("10.50"), stock=10, category="x"))


def create_order(client: TestClient, product: Product, quantity: int = 1, headers=ANA) -> dict:
    body = {
        "payment_type": "card",
        "items": [{"product_id": str(product.id), "quantity": quantity}],
    }
    response = client.post(URL, json=body, headers=headers)
    assert response.status_code == 201
    return response.json()


def test_create_order(client: TestClient, product: Product) -> None:
    body = create_order(client, product, quantity=2)

    me = client.get("/api/v1/me", headers=ANA).json()
    assert body["user_id"] == me["id"]  # el dueño sale del token, no del body
    assert body["total"] == "21.00"
    assert body["status"] == "pending"
    assert body["payment_type"] == "card"
    assert body["items"] == [
        {
            "id": body["items"][0]["id"],
            "product_id": str(product.id),
            "unit_price": "10.50",
            "quantity": 2,
        }
    ]


@pytest.mark.parametrize(
    "method, path",
    [("POST", URL), ("GET", URL), ("PATCH", f"{URL}/{uuid4()}"), ("DELETE", f"{URL}/{uuid4()}")],
)
def test_every_endpoint_requires_token_and_scope(
    client: TestClient, method: str, path: str
) -> None:
    without_token = client.request(method, path)
    without_scope = client.request(
        method, path, headers={"Authorization": f"Bearer {make_token(scp='')}"}
    )

    assert without_token.status_code == 401
    assert without_scope.status_code == 403


@pytest.mark.parametrize(
    "body",
    [
        {"items": []},  # al menos un ítem
        {"items": [{"product_id": "PRODUCT", "quantity": 0}]},  # ck_order_item_quantity
        {"items": [{"product_id": "PRODUCT", "quantity": 1}] * 2},  # producto repetido
        {"items": [{"product_id": "PRODUCT", "quantity": 1}], "payment_type": "x" * 101},
        {"items": [{"product_id": "PRODUCT", "quantity": 1}], "user_id": str(uuid4())},
        {"items": [{"product_id": "PRODUCT", "quantity": 1, "unit_price": "0.01"}]},
    ],
    ids=["no-items", "quantity-0", "duplicate", "payment-type-too-long", "user-id", "unit-price"],
)
def test_create_order_validation(client: TestClient, product: Product, body: dict) -> None:
    for item in body["items"]:
        item["product_id"] = str(product.id)

    response = client.post(URL, json=body, headers=ANA)

    assert response.status_code == 422
    assert response.headers["content-type"] == "application/problem+json"


def test_create_order_with_insufficient_stock(client: TestClient, product: Product) -> None:
    body = {"items": [{"product_id": str(product.id), "quantity": 11}]}

    response = client.post(URL, json=body, headers=ANA)

    assert response.status_code == 409
    assert response.json()["detail"] == f"Insufficient stock for product {product.id}"


def test_list_orders_is_paginated_newest_first(client: TestClient, product: Product) -> None:
    ids = [create_order(client, product)["id"] for _ in range(3)]
    create_order(client, product, headers=LUIS)  # de otro usuario: no aparece
    # el reloj de Windows puede repetir valores: fechas explícitas para un orden estable
    orders = client.app.state.order_repository._orders
    for day, order_id in enumerate(ids, start=1):
        orders[UUID(order_id)].created_at = datetime(2026, 1, day)

    response = client.get(URL, params={"page": 1, "page_size": 2}, headers=ANA)

    assert response.status_code == 200
    body = response.json()
    assert [o["id"] for o in body["items"]] == [ids[2], ids[1]]
    assert {k: body[k] for k in ("page", "page_size", "total")} == {
        "page": 1,
        "page_size": 2,
        "total": 3,
    }


@pytest.mark.parametrize("params", [{"page": 0}, {"page_size": 0}, {"page_size": 101}])
def test_list_orders_rejects_invalid_pagination(client: TestClient, params: dict) -> None:
    assert client.get(URL, params=params, headers=ANA).status_code == 422


def test_cancel_order(client: TestClient, product: Product) -> None:
    order = create_order(client, product, quantity=3)

    response = client.patch(f"{URL}/{order['id']}", json={"status": "cancelled"}, headers=ANA)

    assert response.status_code == 200
    assert response.json()["status"] == "cancelled"
    assert product.stock == 10

    again = client.patch(f"{URL}/{order['id']}", json={"payment_type": "cash"}, headers=ANA)
    assert again.status_code == 409


@pytest.mark.parametrize(
    "body",
    [{}, {"status": "confirmed"}, {"total": "1.00"}],
    ids=["empty", "status-not-allowed", "total-not-editable"],
)
def test_update_order_validation(client: TestClient, product: Product, body: dict) -> None:
    order = create_order(client, product)

    response = client.patch(f"{URL}/{order['id']}", json=body, headers=ANA)

    assert response.status_code == 422


def test_orders_of_other_users_are_not_found(client: TestClient, product: Product) -> None:
    order = create_order(client, product, headers=LUIS)

    patch = client.patch(f"{URL}/{order['id']}", json={"payment_type": "cash"}, headers=ANA)
    delete = client.delete(f"{URL}/{order['id']}", headers=ANA)

    assert patch.status_code == 404
    assert delete.status_code == 404
    assert patch.headers["content-type"] == "application/problem+json"


def test_delete_order_is_soft_delete(client: TestClient, product: Product) -> None:
    order = create_order(client, product, quantity=2)

    response = client.delete(f"{URL}/{order['id']}", headers=ANA)

    assert response.status_code == 204
    assert product.stock == 10
    assert client.get(URL, headers=ANA).json()["total"] == 0
    assert client.delete(f"{URL}/{order['id']}", headers=ANA).status_code == 404
    # la fila sigue existiendo, solo marcada como borrada
    stored = next(iter(client.app.state.order_repository._orders.values()))
    assert stored.deleted_at is not None
