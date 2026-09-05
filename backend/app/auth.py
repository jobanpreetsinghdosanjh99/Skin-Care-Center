import uuid
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import settings

_JWT_ALGORITHM = "HS256"
_TOKEN_TTL = timedelta(days=7)

_bearer_scheme = HTTPBearer(auto_error=False)


def create_access_token(user_id: uuid.UUID, clinic_id: uuid.UUID, role: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "clinic_id": str(clinic_id),
        "role": role,
        "iat": now,
        "exp": now + _TOKEN_TTL,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=_JWT_ALGORITHM)


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[_JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Session expired"
        ) from None
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session"
        ) from None


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
) -> str:
    """FastAPI dependency: requires a valid bearer token, returns the user id.

    Applied to every data router so the app behaves like a real
    authenticated system with a proper login gate, instead of the old
    fully-open MVP shortcut.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated"
        )
    claims = decode_access_token(credentials.credentials)
    return claims["sub"]


def require_roles(*roles: str):
    """FastAPI dependency factory: requires a valid bearer token AND that the
    user's role is one of `roles`, else 403s. Used to restrict specific
    routes/routers (e.g. creating a prescription, managing clinics/diseases)
    to admin/doctor accounts while leaving read/list access open to more
    restricted roles like 'manager'.
    """

    def _check(
        credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    ) -> str:
        if credentials is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated"
            )
        claims = decode_access_token(credentials.credentials)
        if claims.get("role") not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to perform this action",
            )
        return claims["sub"]

    return _check
