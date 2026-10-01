from decimal import Decimal
from enum import StrEnum

# Scope delegado que exige todo el módulo (Expose an API de la app registration "orders")
ORDERS_SCOPE = "Orders.ReadWrite"

# Límites que vienen del DDL
MAX_ORDER_TOTAL = Decimal("9999999999.99")  # DECIMAL(12,2)
SQL_INT_MAX = 2_147_483_647  # INT (OrderItem.quantity)

# Límites de la API
MAX_ITEMS_PER_ORDER = 50
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100


class OrderStatus(StrEnum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"
