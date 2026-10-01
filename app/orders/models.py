"""Tablas Products, Orders y OrderItem (reflejan el DDL de SQL Server)."""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    ForeignKey,
    Index,
    Numeric,
    PrimaryKeyConstraint,
    String,
    Unicode,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base, DateTime2, TimestampMixin


class Product(TimestampMixin, Base):
    __tablename__ = "Products"
    __table_args__ = (
        PrimaryKeyConstraint("id", name="pk_products"),
        CheckConstraint("price > 0", name="ck_products_price"),
        CheckConstraint("stock >= 0", name="ck_products_stock"),
        Index("ix_products_category", "category"),
    )

    id: Mapped[UUID] = mapped_column(server_default=text("NEWSEQUENTIALID()"))
    name: Mapped[str] = mapped_column(Unicode(400))
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    stock: Mapped[int]
    category: Mapped[str] = mapped_column(String(100))


class Order(TimestampMixin, Base):
    __tablename__ = "Orders"
    __table_args__ = (
        PrimaryKeyConstraint("id", name="pk_orders"),
        CheckConstraint("total > 0", name="ck_orders_total"),
        Index("ix_orders_user_created_at", "user_id", "created_at"),
    )

    id: Mapped[UUID] = mapped_column(server_default=text("NEWSEQUENTIALID()"))
    user_id: Mapped[UUID] = mapped_column(ForeignKey("Users.id", name="fk_orders_users"))
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    payment_type: Mapped[str | None] = mapped_column(String(100))
    status: Mapped[str | None] = mapped_column(String(100))  # valores de OrderStatus
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime2)  # soft delete: NULL = activa

    items: Mapped[list[OrderItem]] = relationship(back_populates="order")


class OrderItem(TimestampMixin, Base):
    __tablename__ = "OrderItem"
    __table_args__ = (
        PrimaryKeyConstraint("id", name="pk_order_item"),
        CheckConstraint("unit_price > 0", name="ck_order_item_unit_price"),
        CheckConstraint("quantity > 0", name="ck_order_item_quantity"),
        Index("ix_order_item_order_id", "order_id"),
        Index("ix_order_item_product_id", "product_id"),
    )

    id: Mapped[UUID] = mapped_column(server_default=text("NEWSEQUENTIALID()"))
    product_id: Mapped[UUID] = mapped_column(
        ForeignKey("Products.id", name="fk_order_item_products")
    )
    order_id: Mapped[UUID] = mapped_column(ForeignKey("Orders.id", name="fk_order_item_orders"))
    unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2))  # precio al momento de la compra
    quantity: Mapped[int]

    order: Mapped[Order] = relationship(back_populates="items")
