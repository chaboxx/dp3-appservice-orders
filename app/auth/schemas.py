from dataclasses import dataclass, field
from uuid import UUID


@dataclass(frozen=True)
class Principal:
    """Quién hace el request, según el token ya validado. No toca la base de datos."""

    tenant_id: UUID  # claim tid
    object_id: UUID  # claim oid: id estable del usuario dentro del tenant
    email: str | None = None
    name: str | None = None  # si Entra manda "unknown", se arma con given_name + family_name
    given_name: str | None = None
    family_name: str | None = None
    city: str | None = None  # solo si se agrega como claim en Entra (Attributes & Claims)
    scopes: frozenset[str] = field(default_factory=frozenset)  # claim scp
