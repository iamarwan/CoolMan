"""Password hashing, JWT tokens and auth dependencies."""

import base64
import hashlib
import hmac
import json
import secrets
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import Depends
from fastapi.concurrency import run_in_threadpool
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import get_db
from app.errors import ApiError
from app.models import User

_ISSUER = "sabil-api"
_AUD_USER = "sabil-user"
_AUD_ADMIN = "sabil-admin"
_PBKDF2_ITERATIONS = 260_000

_bearer = HTTPBearer(auto_error=False)


# ── Passwords ────────────────────────────────────────────────────────────────
# PBKDF2 is deliberately slow (~0.2 s); run it in a thread so it never blocks
# other requests.

def _hash_sync(password: str) -> str:
    salt = secrets.token_hex(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), _PBKDF2_ITERATIONS)
    return f"{salt}${dk.hex()}"


def _verify_sync(password: str, hashed: str) -> bool:
    try:
        salt, dk_hex = hashed.split("$", 1)
    except ValueError:
        return False
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), _PBKDF2_ITERATIONS)
    return secrets.compare_digest(dk.hex(), dk_hex)


async def hash_password(password: str) -> str:
    return await run_in_threadpool(_hash_sync, password)


async def verify_password(password: str, hashed: str) -> bool:
    return await run_in_threadpool(_verify_sync, password, hashed)


# ── JWT (HS256) ──────────────────────────────────────────────────────────────

def _b64e(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64d(data: str) -> bytes:
    return base64.urlsafe_b64decode((data + "=" * (-len(data) % 4)).encode("ascii"))


def _sign(signing_input: str) -> str:
    key = get_settings().jwt_secret.encode()
    return _b64e(hmac.new(key, signing_input.encode("ascii"), hashlib.sha256).digest())


def _encode(sub: str, role: str, audience: str, minutes: int) -> str:
    now = datetime.now(timezone.utc)
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "sub": sub,
        "role": role,
        "iss": _ISSUER,
        "aud": audience,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=minutes)).timestamp()),
    }
    h = _b64e(json.dumps(header, separators=(",", ":")).encode())
    p = _b64e(json.dumps(payload, separators=(",", ":")).encode())
    return f"{h}.{p}.{_sign(f'{h}.{p}')}"


def _unauthorized(code: str, detail: str) -> ApiError:
    return ApiError(401, code, detail)


def decode_token(token: str, audience: str, role: str) -> dict:
    try:
        h, p, sig = token.split(".")
    except ValueError:
        raise _unauthorized("token_invalid", "Invalid token.")
    if not secrets.compare_digest(_sign(f"{h}.{p}"), sig):
        raise _unauthorized("token_invalid", "Invalid token.")
    try:
        payload = json.loads(_b64d(p))
    except Exception:
        raise _unauthorized("token_invalid", "Invalid token.")
    if payload.get("exp", 0) < int(datetime.now(timezone.utc).timestamp()):
        raise _unauthorized("token_expired", "Session expired. Please log in again.")
    if payload.get("iss") != _ISSUER or payload.get("aud") != audience or payload.get("role") != role:
        raise _unauthorized("token_invalid", "Invalid token.")
    return payload


def create_user_token(user_id: uuid.UUID) -> str:
    return _encode(str(user_id), "user", _AUD_USER, get_settings().user_token_minutes)


def create_admin_token(username: str) -> str:
    return _encode(username, "admin", _AUD_ADMIN, get_settings().admin_token_minutes)


def authenticate_admin(username: str, password: str) -> bool:
    s = get_settings()
    # Compare both, always, to avoid leaking which one was wrong via timing.
    ok_user = secrets.compare_digest(username.encode(), s.admin_username.encode())
    ok_pass = secrets.compare_digest(password.encode(), s.admin_password.encode())
    return ok_user and ok_pass


# ── Dependencies ─────────────────────────────────────────────────────────────

def _bearer_token(credentials: HTTPAuthorizationCredentials | None) -> str:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise _unauthorized("auth_required", "Please log in to do this.")
    return credentials.credentials


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = decode_token(_bearer_token(credentials), _AUD_USER, "user")
    try:
        uid = uuid.UUID(payload.get("sub"))
    except (TypeError, ValueError):
        raise _unauthorized("token_invalid", "Invalid token.")
    user = await db.get(User, uid)
    if user is None:
        raise _unauthorized("token_invalid", "Account no longer exists.")
    return user


def require_admin(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> dict:
    return decode_token(_bearer_token(credentials), _AUD_ADMIN, "admin")
