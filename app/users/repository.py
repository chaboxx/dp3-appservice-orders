"""Acceso a datos de usuarios: Protocol + implementaciones en memoria (tests) y SQL."""

from typing import Protocol
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import utcnow
from app.users.models import User


class UserRepository(Protocol):
    def get_by_identity(self, tenant_id: UUID, object_id: UUID) -> User | None: ...

    def add(self, user: User) -> User:
        """Guarda el usuario; si otro request lo creó antes (mismo tid + oid), devuelve ese."""
        ...

    def save(self, user: User) -> None: ...


class InMemoryUserRepository:
    """Guarda los usuarios en un dict. Se pierde al reiniciar: solo para desarrollo y tests."""

    def __init__(self) -> None:
        self._users: dict[tuple[UUID, UUID], User] = {}

    def get_by_identity(self, tenant_id: UUID, object_id: UUID) -> User | None:
        return self._users.get((tenant_id, object_id))

    def add(self, user: User) -> User:
        key = (user.entra_tenant_id, user.entra_object_id)
        if key in self._users:
            return self._users[key]
        # Simula los DEFAULT de la base de datos (NEWSEQUENTIALID, SYSUTCDATETIME)
        now = utcnow()
        user.id = user.id or uuid4()
        user.created_at = user.created_at or now
        user.updated_at = user.updated_at or now
        self._users[key] = user
        return user

    def save(self, user: User) -> None:
        user.updated_at = utcnow()


class SqlUserRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def get_by_identity(self, tenant_id: UUID, object_id: UUID) -> User | None:
        return self._session.scalar(
            select(User).where(User.entra_tenant_id == tenant_id, User.entra_object_id == object_id)
        )

    def add(self, user: User) -> User:
        # Dos primeros requests simultáneos del mismo usuario: el segundo choca con el índice
        # único ux_users_entra_identity. El savepoint deja seguir la transacción del request.
        try:
            with self._session.begin_nested():
                self._session.add(user)
        except IntegrityError:
            existing = self.get_by_identity(user.entra_tenant_id, user.entra_object_id)
            if existing is None:
                raise
            return existing
        return user

    def save(self, user: User) -> None:
        self._session.flush()  # updated_at lo pone la base (onupdate=SYSUTCDATETIME())
