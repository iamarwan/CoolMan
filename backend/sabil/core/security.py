# core/security.py
#
# PURE security logic: password hashing and login tokens (JWT).
#
# "Pure" means this file knows nothing about FastAPI or the database, so you can
# copy it into any other Python project unchanged. The part that plugs this into
# FastAPI ("who is the logged-in user for this request?") is in core/dependencies.py.

import base64
import hashlib
import hmac
import json
import secrets
import uuid
from datetime import datetime, timedelta, timezone

from sabil.core.config import (
    ADMIN_PASSWORD,
    ADMIN_USERNAME,
    JWT_AUDIENCE_ADMIN,
    JWT_AUDIENCE_USER,
    JWT_EXPIRES_ADMIN_MINUTES,
    JWT_EXPIRES_USER_MINUTES,
    JWT_ISSUER,
    JWT_SECRET,
    PASSWORD_HASH_ITERATIONS,
)


class TokenError(Exception):
    """Raised when a token is missing, forged, expired or of the wrong kind.

    wrong_role=True means "the token is genuine, but it is not an <admin/user>
    token" (the API answers 403 for that case instead of 401).
    """

    def __init__(self, detail: str, wrong_role: bool = False):
        super().__init__(detail)
        self.detail = detail
        self.wrong_role = wrong_role


# ─────────────────────────────────────────────
# PASSWORD HASHING
# ─────────────────────────────────────────────

def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), PASSWORD_HASH_ITERATIONS)
    return f"{salt}${dk.hex()}"


def verify_password(password: str, hashed: str) -> bool:
    try:
        salt, dk_hex = hashed.split("$", 1)
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), PASSWORD_HASH_ITERATIONS)
        return secrets.compare_digest(dk.hex(), dk_hex)
    except Exception:
        return False


# ─────────────────────────────────────────────
# JWT PRIMITIVES
# A JWT is three base64 pieces joined by dots: header.payload.signature
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


def decode_token(token: str, expected_audience: str, expected_role: str) -> dict:
    """Check a token and return its payload, or raise TokenError."""
    try:
        header_part, payload_part, signature_part = token.split(".")
    except ValueError as exc:
        raise TokenError("Invalid token format.") from exc

    signing_input = f"{header_part}.{payload_part}"
    if not secrets.compare_digest(_sign(signing_input), signature_part):
        raise TokenError("Invalid token signature.")

    try:
        payload = json.loads(_b64url_decode(payload_part))
    except Exception as exc:
        raise TokenError("Invalid token payload.") from exc

    now_ts = int(datetime.now(timezone.utc).timestamp())
    if payload.get("exp", 0) < now_ts:
        raise TokenError("Token expired.")
    if payload.get("iss") != JWT_ISSUER or payload.get("aud") != expected_audience:
        raise TokenError("Invalid token claims.")
    if payload.get("role") != expected_role:
        raise TokenError(f"{expected_role.capitalize()} token required.", wrong_role=True)
    return payload


# ─────────────────────────────────────────────
# ADMIN / USER TOKENS
# ─────────────────────────────────────────────

def create_admin_token(username: str) -> str:
    return _build_token(username, "admin", JWT_AUDIENCE_ADMIN, JWT_EXPIRES_ADMIN_MINUTES)


def create_user_token(user_id: uuid.UUID) -> str:
    return _build_token(str(user_id), "user", JWT_AUDIENCE_USER, JWT_EXPIRES_USER_MINUTES)


def decode_admin_token(token: str) -> dict:
    return decode_token(token, JWT_AUDIENCE_ADMIN, "admin")


def decode_user_token(token: str) -> dict:
    return decode_token(token, JWT_AUDIENCE_USER, "user")


def authenticate_admin(username: str, password: str) -> bool:
    return secrets.compare_digest(username, ADMIN_USERNAME) and secrets.compare_digest(
        password, ADMIN_PASSWORD
    )
