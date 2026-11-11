"""Database-backed rate limiting (works across restarts and several workers).

Usage:
    await ratelimit.check(db, f"login:ip:{ip}", limit=60)     # raises when over
    await ratelimit.record(db, f"login:ip:{ip}")              # count one event
"""

import random
from datetime import datetime, timedelta, timezone

from fastapi import Request
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import ApiError
from app.models import RateHit

WINDOW = timedelta(minutes=15)
_KEEP = timedelta(days=2)


def client_ip(request: Request) -> str:
    """The caller's address. In production the proxy passes the real one
    (uvicorn --proxy-headers); only the proxy can reach the API container."""
    return request.client.host if request.client else "unknown"


async def check(
    db: AsyncSession,
    bucket: str,
    limit: int,
    window: timedelta = WINDOW,
    code: str = "too_many_attempts",
) -> None:
    since = datetime.now(timezone.utc) - window
    count, oldest = (
        await db.execute(
            select(func.count(RateHit.id), func.min(RateHit.created_at)).where(
                RateHit.bucket == bucket, RateHit.created_at > since
            )
        )
    ).one()
    if count >= limit:
        remaining = (oldest + window) - datetime.now(timezone.utc)
        minutes = max(1, int(remaining.total_seconds() // 60) + 1)
        raise ApiError(
            429,
            code,
            f"Too many attempts. Try again in {minutes} minute(s).",
            retry_after_minutes=minutes,
        )


async def record(db: AsyncSession, *buckets: str) -> None:
    """Counts one event in each bucket and commits immediately, so the count
    survives even if the request then fails."""
    for bucket in buckets:
        db.add(RateHit(bucket=bucket[:200]))
    if random.random() < 0.02:  # occasional clean-up of old rows
        await db.execute(
            delete(RateHit).where(RateHit.created_at < datetime.now(timezone.utc) - _KEEP)
        )
    await db.commit()
