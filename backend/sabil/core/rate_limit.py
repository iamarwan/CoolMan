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
    CONFIRM_COOLDOWN_SECONDS,
    RATE_LIMIT_MAX_REQUESTS,
    RATE_LIMIT_WINDOW_SECONDS,
)

# ─────────────────────────────────────────────
# 1) SUBMISSION RATE LIMIT  (per IP address)
#    Use it on a route with: dependencies=[Depends(rate_limiter)]
# ─────────────────────────────────────────────

_requests_by_ip: dict[str, list[float]] = defaultdict(list)


async def rate_limiter(request: Request) -> None:
    host = request.client.host if request.client else "unknown"
    now = time.time()
    window_start = now - RATE_LIMIT_WINDOW_SECONDS
    _requests_by_ip[host] = [t for t in _requests_by_ip[host] if t > window_start]
    if len(_requests_by_ip[host]) >= RATE_LIMIT_MAX_REQUESTS:
        raise HTTPException(
            status_code=429,
            detail="Too many requests. Please wait before submitting again.",
        )
    _requests_by_ip[host].append(now)


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
