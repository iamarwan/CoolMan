# auth.py

import base64
import hashlib
import hmac
import json
import os
import secrets
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db

# ─────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────

JWT_SECRET = os.getenv("SABIL_JWT_SECRET", "change-me-in-production")
JWT_ISSUER = "sabil-api"

JWT_AUDIENCE_ADMIN = "sabil-admin"
JWT_EXPIRES_ADMIN_MINUTES = int(os.getenv("SABIL_ADMIN_TOKEN_MIN", "480"))

JWT_AUDIENCE_USER = "sabil-user"
JWT_EXPIRES_USER_MINUTES = int(os.getenv("SABIL_USER_TOKEN_MIN", "10080"))  # 7 days

ADMIN_USERNAME = os.getenv("SABIL_ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("SABIL_ADMIN_PASSWORD", "admin123")

_PBKDF2_ITERATIONS = 260_000

bearer_scheme = HTTPBearer(auto_error=False)


# ─────────────────────────────────────────────
# PASSWORD HASHING
# ─────────────────────────────────────────────

def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), _PBKDF2_ITERATIONS)
    return f"{salt}${dk.hex()}"


def verify_password(password: str, hashed: str) -> bool:
    try:
        salt, dk_hex = hashed.split("$", 1)
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), _PBKDF2_ITERATIONS)
        return secrets.compare_digest(dk.hex(), dk_hex)
    except Exception:
        return False


# ─────────────────────────────────────────────
# JWT PRIMITIVES
# ─────────────────────────────────────────────

def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64url_decode(data: str) -> bytes:
    padded = data + "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(padded.encode("ascii"))


def _sign(signing_input: str) -> str:
    digest = hmac.new(
        JWT_SECRET.encode("utf-8"),
        signing_input.encode("ascii"),
        hashlib.sha256,
    ).digest()
    return _b64url_encode(digest)


def _build_token(sub: str, role: str, audience: str, expires_minutes: int) -> str:
    now = datetime.now(timezone.utc)
    exp = now + timedelta(minutes=expires_minutes)
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "sub": sub,
        "role": role,
        "iss": JWT_ISSUER,
        "aud": audience,
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
    }
    encoded_header = _b64url_encode(
        json.dumps(header, separators=(",", ":"), sort_keys=True).encode("utf-8")
    )
    encoded_payload = _b64url_encode(
        json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
    )
    signing_input = f"{encoded_header}.{encoded_payload}"
    return f"{signing_input}.{_sign(signing_input)}"


def _decode_and_validate(token: str, expected_audience: str, expected_role: str) -> dict:
    try:
        header_part, payload_part, signature_part = token.split(".")
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token format.",
        ) from exc

    signing_input = f"{header_part}.{payload_part}"
    if not secrets.compare_digest(_sign(signing_input), signature_part):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token signature.",
        )

    try:
        payload = json.loads(_b64url_decode(payload_part))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload.",
        ) from exc

    now_ts = int(datetime.now(timezone.utc).timestamp())
    if payload.get("exp", 0) < now_ts:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired.")
    if payload.get("iss") != JWT_ISSUER or payload.get("aud") != expected_audience:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token claims.")
    if payload.get("role") != expected_role:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"{expected_role.capitalize()} token required.",
        )
    return payload


# ─────────────────────────────────────────────
# ADMIN AUTH
# ─────────────────────────────────────────────

def create_admin_token(username: str) -> str:
    return _build_token(username, "admin", JWT_AUDIENCE_ADMIN, JWT_EXPIRES_ADMIN_MINUTES)


def authenticate_admin(username: str, password: str) -> bool:
    return secrets.compare_digest(username, ADMIN_USERNAME) and secrets.compare_digest(
        password, ADMIN_PASSWORD
    )


def require_admin(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token.")
    return _decode_and_validate(credentials.credentials, JWT_AUDIENCE_ADMIN, "admin")


# ─────────────────────────────────────────────
# USER AUTH
# ─────────────────────────────────────────────

def create_user_token(user_id: uuid.UUID) -> str:
    return _build_token(str(user_id), "user", JWT_AUDIENCE_USER, JWT_EXPIRES_USER_MINUTES)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
):
    from models import User  # local import avoids circular dependency

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token.")

    payload = _decode_and_validate(credentials.credentials, JWT_AUDIENCE_USER, "user")
    raw_id = payload.get("sub")

    try:
        uid = uuid.UUID(raw_id)
    except (ValueError, TypeError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token subject.")

    stmt = select(User).where(User.id == uid)
    result = await db.execute(stmt)
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found.")
    return user
