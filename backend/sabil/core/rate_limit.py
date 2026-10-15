# core/rate_limit.py
#
# Two small in-memory abuse limiters.
#
# NOTE: both keep their state in a Python dictionary, so it is forgotten when
# the server restarts and is NOT shared between several server processes. That
# is fine for one server; for several, move this state into Redis or the database.

import time
import uuid
from collections import defaultdict

from fastapi import HTTPException, Request

from sabil.core.config import (
    AUTH_RATE_LIMIT_MAX_ATTEMPTS,
    AUTH_RATE_LIMIT_WINDOW_SECONDS,
    CONFIRM_COOLDOWN_SECONDS,
    RATE_LIMIT_MAX_REQUESTS,
    RATE_LIMIT_WINDOW_SECONDS,
)

# ─────────────────────────────────────────────
# 1) SUBMISSION RATE LIMIT  (per IP address)
#    Use it on a route with: dependencies=[Depends(rate_limiter)]
# ─────────────────────────────────────────────

_requests_by_ip: dict[str, list[float]] = defaultdict(list)

# Login / register attempts (per IP). Separate from the submission limit so a
# person adding a cooler is never blocked from logging in, and vice versa.
_auth_attempts_by_ip: dict[str, list[float]] = defaultdict(list)


def _check_ip_limit(
    store: dict[str, list[float]],
    request: Request,
    max_requests: int,
    window_seconds: float,
    message: str,
) -> None:
    host = request.client.host if request.client else "unknown"
    now = time.time()
    window_start = now - window_seconds
    store[host] = [t for t in store[host] if t > window_start]
    if len(store[host]) >= max_requests:
        raise HTTPException(status_code=429, detail=message)
    store[host].append(now)


async def rate_limiter(request: Request) -> None:
    _check_ip_limit(
        _requests_by_ip,
        request,
        RATE_LIMIT_MAX_REQUESTS,
        RATE_LIMIT_WINDOW_SECONDS,
        "Too many requests. Please wait before submitting again.",
    )


async def auth_rate_limiter(request: Request) -> None:
    """Use on login/register routes to slow down password guessing."""
    _check_ip_limit(
        _auth_attempts_by_ip,
        request,
        AUTH_RATE_LIMIT_MAX_ATTEMPTS,
        AUTH_RATE_LIMIT_WINDOW_SECONDS,
        "Too many login attempts. Please wait a minute and try again.",
    )


# ─────────────────────────────────────────────
# 2) "STILL WORKING" CONFIRM COOLDOWN  (per user + cooler)
# ─────────────────────────────────────────────

# (user id, cooler id) -> time of that user's last confirmation of that cooler
_last_confirm: dict[tuple[uuid.UUID, uuid.UUID], float] = {}


def check_confirm_cooldown(user_id: uuid.UUID, cooler_id: uuid.UUID) -> None:
    """Raise 429 if this user confirmed this cooler too recently."""
    elapsed = time.time() - _last_confirm.get((user_id, cooler_id), 0.0)
    if elapsed < CONFIRM_COOLDOWN_SECONDS:
        remaining_minutes = int((CONFIRM_COOLDOWN_SECONDS - elapsed) / 60)
        raise HTTPException(
            status_code=429,
            detail=(
                f"You can confirm this cooler again in {remaining_minutes} "
                f"minute{'s' if remaining_minutes != 1 else ''}."
            ),
        )


def record_confirm(user_id: uuid.UUID, cooler_id: uuid.UUID) -> None:
    _last_confirm[(user_id, cooler_id)] = time.time()


def reset_confirm_cooldown(cooler_id: uuid.UUID) -> None:
    """Forget every confirmation of a cooler (its status just changed)."""
    for key in [k for k in _last_confirm if k[1] == cooler_id]:
        del _last_confirm[key]
