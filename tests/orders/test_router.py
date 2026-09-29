"""Tests HTTP del módulo de órdenes."""

from uuid import uuid4

from fastapi.testclient import TestClient

URL = "/api/v1/orders"


def test_create_and_get_order(client: TestClient) -> None:
    created = client.post(URL, json={"customer_id": "c-1", "total": "10.50"})

    assert created.status_code == 201
    body = created.json()
    assert body["customer_id"] == "c-1"
    assert body["total"] == "10.50"
    assert body["status"] == "pending"

    fetched = client.get(f"{URL}/{body['id']}")

    assert fetched.status_code == 200
    assert fetched.json() == body


def test_list_orders(client: TestClient) -> None:
    client.post(URL, json={"customer_id": "c-1", "total": "1.00"})
    client.post(URL, json={"customer_id": "c-2", "total": "2.00"})

    response = client.get(URL)

    assert response.status_code == 200
    assert [o["customer_id"] for o in response.json()] == ["c-1", "c-2"]


def test_get_missing_order_returns_problem_details(client: TestClient) -> None:
    order_id = uuid4()

    response = client.get(f"{URL}/{order_id}")

    assert response.status_code == 404
    assert response.headers["content-type"] == "application/problem+json"
    assert response.json() == {
        "type": "about:blank",
        "title": "Not Found",
        "status": 404,
        "detail": f"Order {order_id} not found",
        "instance": f"{URL}/{order_id}",
    }


def test_create_order_rejects_invalid_total(client: TestClient) -> None:
    response = client.post(URL, json={"customer_id": "c-1", "total": "-5"})

    assert response.status_code == 422
    assert response.headers["content-type"] == "application/problem+json"
