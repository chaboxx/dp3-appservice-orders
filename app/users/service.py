"""Alta automática de usuarios (just-in-time provisioning).

En cada request autenticado: si el usuario del token (tid + oid) no existe en la tabla Users,
se crea; si existe, se verifica que esté activo y se sincronizan sus datos con el token.
No importa nada de FastAPI.
"""

from datetime import timedelta

from app.auth.schemas import Principal
from app.database import utcnow
from app.users.exceptions import EmailClaimRequired, UserInactive
from app.users.models import User
from app.users.repository import UserRepository

# last_login_at no se escribe en cada request (sería un UPDATE por llamada), solo si pasó esto
LAST_LOGIN_REFRESH = timedelta(minutes=15)

# Largos en el DDL: first_name / last_name NVARCHAR(200), city NVARCHAR(128)
NAME_MAX_LENGTH = 200
CITY_MAX_LENGTH = 128


class UserService:
    def __init__(self, repository: UserRepository) -> None:
        self._repository = repository

    def get_or_create(self, principal: Principal) -> User:
        if not principal.email:
            raise EmailClaimRequired()
        now = utcnow()
        user = self._repository.get_by_identity(principal.tenant_id, principal.object_id)
        if user is None:
            return self._repository.add(
                User(
                    entra_tenant_id=principal.tenant_id,
                    entra_object_id=principal.object_id,
                    email=principal.email,
                    first_name=_truncate(principal.given_name, NAME_MAX_LENGTH),
                    last_name=_truncate(principal.family_name, NAME_MAX_LENGTH),
                    city=_truncate(principal.city, CITY_MAX_LENGTH),
                    is_active=True,
                    last_login_at=now,
                )
            )
        if not user.is_active:
            raise UserInactive()

        profile_changed = _sync_profile(user, principal)
        login_is_stale = user.last_login_at is None or now - user.last_login_at > LAST_LOGIN_REFRESH
        if profile_changed or login_is_stale:
            user.last_login_at = now
            self._repository.save(user)
        return user


def _sync_profile(user: User, principal: Principal) -> bool:
    """Copia al usuario los datos del token que cambiaron en Entra. True si hubo cambios."""
    profile = {
        "email": principal.email,
        "first_name": _truncate(principal.given_name, NAME_MAX_LENGTH),
        "last_name": _truncate(principal.family_name, NAME_MAX_LENGTH),
        "city": _truncate(principal.city, CITY_MAX_LENGTH),
    }
    changed = False
    for field, value in profile.items():
        if getattr(user, field) != value:
            setattr(user, field, value)
            changed = True
    return changed


def _truncate(value: str | None, max_length: int) -> str | None:
    return value[:max_length] if value else None
