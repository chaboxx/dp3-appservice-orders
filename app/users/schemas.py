from uuid import UUID

from pydantic import BaseModel


class MeRead(BaseModel):
    """El usuario autenticado: su id en la base y los datos de su token de Entra External ID."""

    id: UUID  # Users.id: el dueño de las órdenes
    object_id: UUID  # claim oid: id estable del usuario en el tenant
    tenant_id: UUID  # claim tid
    email: str | None
    name: str | None
    given_name: str | None
    family_name: str | None
    city: str | None
    scopes: list[str]  # permisos que el usuario le dio a la app cliente (claim scp)
