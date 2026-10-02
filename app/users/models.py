from datetime import datetime
from uuid import UUID

from sqlalchemy import Index, PrimaryKeyConstraint, Unicode, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base, DateTime2, TimestampMixin


class User(TimestampMixin, Base):
    """Usuario de la app, vinculado a su identidad de Entra por (tid, oid) del token."""

    __tablename__ = "Users"
    __table_args__ = (
        PrimaryKeyConstraint("id", name="pk_users"),
        Index("ux_users_entra_identity", "entra_tenant_id", "entra_object_id", unique=True),
        Index("ix_users_email", "email"),
    )

    id: Mapped[UUID] = mapped_column(server_default=text("NEWSEQUENTIALID()"))
    entra_tenant_id: Mapped[UUID]  # claim tid
    entra_object_id: Mapped[UUID]  # claim oid
    email: Mapped[str] = mapped_column(Unicode(320))
    # Cifrados con Always Encrypted (migrations/05). El driver los cifra y descifra: aquí son str
    first_name: Mapped[str | None] = mapped_column(Unicode(200, collation="Latin1_General_BIN2"))
    last_name: Mapped[str | None] = mapped_column(Unicode(200, collation="Latin1_General_BIN2"))
    is_active: Mapped[bool] = mapped_column(server_default=text("1"))
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime2)
    city: Mapped[str | None] = mapped_column(Unicode(128))  # claim city (migrations/06), legible
