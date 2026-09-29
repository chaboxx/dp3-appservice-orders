from uuid import UUID

from app.errors import DomainError


class OrderNotFound(DomainError):
    status_code = 404

    def __init__(self, order_id: UUID) -> None:
        super().__init__(f"Order {order_id} not found")
