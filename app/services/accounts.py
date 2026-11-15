"""Account login and deletion, shared by the API and the public web pages."""

from fastapi import Request
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.errors import ApiError
from app.models import User
from app.security import (
    burn_time_like_a_real_check,
    hash_password,
    needs_rehash,
    verify_password,
)
from app.services import ratelimit


def _login_buckets(request: Request, username: str) -> tuple[str, str, str]:
    ip = ratelimit.client_ip(request)
    name = username.lower()
    return f"login:user-ip:{name}:{ip}", f"login:user:{name}", f"login:ip:{ip}"


async def _check_login_limits(db: AsyncSession, request: Request, username: str) -> None:
    s = get_settings()
    user_ip, user, ip = _login_buckets(request, username)
    # Per user+address is strict; per user overall is looser so that one
    # attacker cannot easily lock a real user out from their own phone.
    await ratelimit.check(db, user_ip, s.login_failures_per_user_ip)
    await ratelimit.check(db, user, s.login_failures_per_user)
    await ratelimit.check(db, ip, s.login_failures_per_ip)


async def authenticate(db: AsyncSession, request: Request, username: str, password: str) -> User:
    """Returns the user, or raises invalid_credentials / too_many_attempts."""
    await _check_login_limits(db, request, username)

    user = await db.scalar(select(User).where(func.lower(User.username) == username.lower()))
    if user is None:
        await burn_time_like_a_real_check(password)
        ok = False
    else:
        ok = await verify_password(password, user.hashed_password)

    if not ok:
        await ratelimit.record(db, *_login_buckets(request, username))
        raise ApiError(401, "invalid_credentials", "Invalid username or password.")

    if needs_rehash(user.hashed_password):
        user.hashed_password = await hash_password(password)
        await db.commit()
    return user


async def delete_account(db: AsyncSession, request: Request, user: User, password: str) -> None:
    await _check_login_limits(db, request, user.username)
    if not await verify_password(password, user.hashed_password):
        await ratelimit.record(db, *_login_buckets(request, user.username))
        raise ApiError(403, "wrong_password", "Wrong password.")
    # Foreign keys: actions are deleted; coolers and photos keep existing with
    # user_id set to NULL.
    await db.delete(user)
    await db.commit()
