import time
from collections import defaultdict
from fastapi import Request, HTTPException, Depends
from sqlalchemy import select, cast, String
from sqlalchemy.ext.asyncio import AsyncSession
from database import get_db
from models import WaterCooler, User

# Cooldown tracking
_confirm_store: dict[tuple[str, str], float] = {}

# Rate limit tracking
_rate_limit_store: dict[str, list[float]] = defaultdict(list)
_RATE_LIMIT_MAX = 3
_RATE_LIMIT_WINDOW = 60.0

async def rate_limiter(request: Request) -> None:
    host = request.client.host if request.client else "unknown"
    now = time.time()
    window_start = now - _RATE_LIMIT_WINDOW
    _rate_limit_store[host] = [t for t in _rate_limit_store[host] if t > window_start]
    if len(_rate_limit_store[host]) >= _RATE_LIMIT_MAX:
        raise HTTPException(
            status_code=429,
            detail="Too many requests. Please wait before submitting again.",
        )
    _rate_limit_store[host].append(now)

async def get_cooler_or_404(cooler_id: str, db: AsyncSession = Depends(get_db)) -> WaterCooler:
    result = await db.execute(select(WaterCooler).where(cast(WaterCooler.id, String) == cooler_id))
    cooler = result.scalars().first()
    if not cooler:
        raise HTTPException(status_code=404, detail="Cooler not found")
    return cooler

async def get_user_or_404(user_id: str, db: AsyncSession) -> User:
    result = await db.execute(select(User).where(cast(User.id, String) == str(user_id)))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
