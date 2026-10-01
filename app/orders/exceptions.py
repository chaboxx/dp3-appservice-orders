from uuid import UUID

from app.errors import DomainError


class OrderNotFound(DomainError):
    """También para órdenes de otro usuario o borradas: no se revela que existen."""

    status_code = 404

    def __init__(self, order_id: UUID) -> None:
        super().__init__(f"Order {order_id} not found")


class OrderNotEditable(DomainError):
    status_code = 409

    def __init__(self, order_id: UUID, status: str) -> None:
        super().__init__(f"Order {order_id} is {status} and can't be modified")


class ProductNotFound(DomainError):
    status_code = 422

    def __init__(self, product_id: UUID) -> None:
        super().__init__(f"Product {product_id} not found")


class InsufficientStock(DomainError):
    status_code = 409

    def __init__(self, product_id: UUID) -> None:
        super().__init__(f"Insufficient stock for product {product_id}")


class OrderTotalTooLarge(DomainError):
    status_code = 422

    def __init__(self) -> None:
        super().__init__("Order total exceeds the maximum allowed")
