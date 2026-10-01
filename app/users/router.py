"""Endpoints HTTP de usuarios."""

from fastapi import APIRouter

from app.auth.dependencies import CurrentPrincipal
from app.users.dependencies import CurrentUser
from app.users.schemas import MeRead

router = APIRouter(tags=["users"])


@router.get("/me")
def read_me(principal: CurrentPrincipal, user: CurrentUser) -> MeRead:
    """Datos del usuario autenticado. Requiere un token válido (no exige scope).

    Es lo primero que llama un cliente después del login: si el usuario todavía no existe en
    la tabla Users, se crea aquí."""
    return MeRead(
        id=user.id,
        object_id=principal.object_id,
        tenant_id=principal.tenant_id,
        email=principal.email,
        name=principal.name,
        given_name=principal.given_name,
        family_name=principal.family_name,
        city=principal.city,
        scopes=sorted(principal.scopes),
    )
