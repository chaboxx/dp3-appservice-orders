"""Acceso a datos de órdenes y productos.

El service depende de los `Protocol`, no de una implementación concreta: con base de datos se
usan las versiones SQL (una por request, con la sesión del request) y sin ella, las de memoria.
Las órdenes borradas (`deleted_at` con fecha) no las devuelve ninguna consulta.
"""

from collections.abc import Iterable
from typing import Protocol
from uuid import UUID, uuid4

from sqlalchemy import func, select, update
from sqlalchemy.orm import Session, selectinload

from app.database import utcnow
from app.orders.models import Order, Product


class OrderRepository(Protocol):
    def add(self, order: Order) -> None: ...

    def get_for_update(self, order_id: UUID, user_id: UUID) -> Order | None:
        """Orden activa del usuario, bloqueada hasta el fin de la transacción (para modificarla)."""
        ...

    def list_page(self, user_id: UUID, offset: int, limit: int) -> list[Order]:
        """Órdenes activas del usuario, de la más nueva a la más antigua."""
        ...

    def count(self, user_id: UUID) -> int: ...

    def save(self, order: Order) -> None: ...


class ProductRepository(Protocol):
    def get_many(self, product_ids: Iterable[UUID]) -> dict[UUID, Product]: ...

    def decrease_stock(self, product_id: UUID, quantity: int) -> bool:
        """Descuenta stock solo si alcanza (atómico). False si no alcanzó."""
        ...

    def increase_stock(self, product_id: UUID, quantity: int) -> None: ...


class InMemoryOrderRepository:
    """Guarda las órdenes en un dict. Se pierde al reiniciar: solo para desarrollo y tests."""

    def __init__(self) -> None:
        self._orders: dict[UUID, Order] = {}

    def add(self, order: Order) -> None:
        # Simula los DEFAULT de la base de datos (NEWSEQUENTIALID, SYSUTCDATETIME)
        now = utcnow()
        for row in (order, *order.items):
            row.id = row.id or uuid4()
            row.created_at = row.created_at or now
            row.updated_at = row.updated_at or now
        self._orders[order.id] = order

    def get_for_update(self, order_id: UUID, user_id: UUID) -> Order | None:
        order = self._orders.get(order_id)
        if order is None or order.user_id != user_id or order.deleted_at is not None:
            return None
        return order

    def list_page(self, user_id: UUID, offset: int, limit: int) -> list[Order]:
        newest_first = sorted(
            self._active(user_id), key=lambda o: (o.created_at, o.id), reverse=True
        )
        return newest_first[offset : offset + limit]

    def count(self, user_id: UUID) -> int:
        return len(self._active(user_id))

    def save(self, order: Order) -> None:
        order.updated_at = utcnow()

    def _active(self, user_id: UUID) -> list[Order]:
        return [o for o in self._orders.values() if o.user_id == user_id and o.deleted_at is None]


class InMemoryProductRepository:
    def __init__(self) -> None:
        self._products: dict[UUID, Product] = {}

    def add(self, product: Product) -> Product:
        """Solo existe en memoria: los productos de la base se cargan con SQL (migrations/)."""
        product.id = product.id or uuid4()
        self._products[product.id] = product
        return product

    def get_many(self, product_ids: Iterable[UUID]) -> dict[UUID, Product]:
        return {pid: self._products[pid] for pid in product_ids if pid in self._products}

    def decrease_stock(self, product_id: UUID, quantity: int) -> bool:
        product = self._products[product_id]
        if product.stock < quantity:
            return False
        product.stock -= quantity
        return True

    def increase_stock(self, product_id: UUID, quantity: int) -> None:
        self._products[product_id].stock += quantity


class SqlOrderRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def add(self, order: Order) -> None:
        self._session.add(order)  # los ítems se guardan en cascada
        self._session.flush()  # obtiene id y timestamps generados por la base

    def get_for_update(self, order_id: UUID, user_id: UUID) -> Order | None:
        # Bloqueo de fila: dos cancelaciones simultáneas no pueden devolver el stock dos veces.
        # Hint explícito porque en SQL Server SQLAlchemy ignora with_for_update()
        return self._session.scalar(
            self._active(user_id)
            .where(Order.id == order_id)
            .with_hint(Order, "WITH (UPDLOCK, ROWLOCK)", dialect_name="mssql")
            .options(selectinload(Order.items))
        )

    def list_page(self, user_id: UUID, offset: int, limit: int) -> list[Order]:
        # Usa el índice ix_orders_user_created_at (user_id, created_at)
        query = (
            self._active(user_id)
            .options(selectinload(Order.items))
            .order_by(Order.created_at.desc(), Order.id.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(self._session.scalars(query))

    def count(self, user_id: UUID) -> int:
        query = (
            select(func.count())
            .select_from(Order)
            .where(Order.user_id == user_id, Order.deleted_at.is_(None))
        )
        return self._session.scalar(query) or 0

    def save(self, order: Order) -> None:
        self._session.flush()  # updated_at lo pone la base (onupdate=SYSUTCDATETIME())

    @staticmethod
    def _active(user_id: UUID):
        return select(Order).where(Order.user_id == user_id, Order.deleted_at.is_(None))


class SqlProductRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def get_many(self, product_ids: Iterable[UUID]) -> dict[UUID, Product]:
        products = self._session.scalars(select(Product).where(Product.id.in_(list(product_ids))))
        return {product.id: product for product in products}

    def decrease_stock(self, product_id: UUID, quantity: int) -> bool:
        # UPDATE condicional: si otro request se llevó el stock, no actualiza ninguna fila
        result = self._session.execute(
            update(Product)
            .where(Product.id == product_id, Product.stock >= quantity)
            .values(stock=Product.stock - quantity)
        )
        return result.rowcount == 1

    def increase_stock(self, product_id: UUID, quantity: int) -> None:
        self._session.execute(
            update(Product).where(Product.id == product_id).values(stock=Product.stock + quantity)
        )
