"""Endpoints HTTP de usuarios."""

from fastapi import APIRouter

from app.auth.dependencies import CurrentPrincipal
from app.users.schemas import MeRead

router = APIRouter(tags=["users"])


@router.get("/me")
def read_me(principal: CurrentPrincipal) -> MeRead:
    """Datos del usuario autenticado. Requiere un token válido; hoy salen solo del token
    (todavía no se lee la tabla Users)."""
    return MeRead(
        object_id=principal.object_id,
        tenant_id=principal.tenant_id,
        email=principal.email,
        name=principal.name,
        scopes=sorted(principal.scopes),
    )
