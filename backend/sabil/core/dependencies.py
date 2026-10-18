# core/dependencies.py
#
# FastAPI "dependencies": small functions that FastAPI runs BEFORE a route.
# A route lists them with Depends(...), for example:
#
#     async def create_cooler(user: User = Depends(get_current_user)): ...
#
# FastAPI calls get_current_user first and passes the result in. If it raises an
# error the route never runs.

import uuid
from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.core.database import get_db
from sabil.core.security import TokenError, decode_admin_token, decode_user_token
from sabil.users.models import User

# Reads the "Authorization: Bearer <token>" header. auto_error=False lets us
# send our own error message when it is missing.
bearer_scheme = HTTPBearer(auto_error=False)


def _bearer_token(credentials: HTTPAuthorizationCredentials | None) -> str:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token.")
    return credentials.credentials


def _http_error(exc: TokenError) -> HTTPException:
    code = status.HTTP_403_FORBIDDEN if exc.wrong_role else status.HTTP_401_UNAUTHORIZED
    return HTTPException(status_code=code, detail=exc.detail)


def require_admin(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    """Allow the request only if it carries a valid ADMIN token."""
    token = _bearer_token(credentials)
    try:
        return decode_admin_token(token)
    except TokenError as exc:
        raise _http_error(exc) from exc


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Return the logged-in User for this request, or answer 401."""
    token = _bearer_token(credentials)
    try:
        payload = decode_user_token(token)
    except TokenError as exc:
        raise _http_error(exc) from exc

    try:
        user_id = uuid.UUID(payload.get("sub"))
    except (ValueError, TypeError, AttributeError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token subject.") from None

    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found.")
    return user


# ─────────────────────────────────────────────
# "WHO IS ASKING?" (for pages that anyone may open, but show more to some people)
# ─────────────────────────────────────────────

@dataclass
class Viewer:
    """The person making a request. Both fields empty = an anonymous visitor."""

    user_id: uuid.UUID | None = None
    is_admin: bool = False


def get_viewer(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> Viewer:
    """Identify the caller if a valid token was sent. Never raises: a missing
    or bad token simply means "anonymous"."""
    if credentials is None or credentials.scheme.lower() != "bearer":
        return Viewer()
    token = credentials.credentials
    try:
        decode_admin_token(token)
        return Viewer(is_admin=True)
    except TokenError:
        pass
    try:
        return Viewer(user_id=uuid.UUID(decode_user_token(token).get("sub")))
    except (TokenError, ValueError, TypeError, AttributeError):
        return Viewer()
