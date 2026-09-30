from uuid import UUID

from pydantic import BaseModel


class MeRead(BaseModel):
    """El usuario autenticado, tal como lo describe su token de Entra External ID."""

    object_id: UUID  # claim oid: id estable del usuario en el tenant
    tenant_id: UUID  # claim tid
    email: str | None
    name: str | None
    scopes: list[str]  # permisos que el usuario le dio a la app cliente (claim scp)
