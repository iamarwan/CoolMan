"""Trust points, cooldowns and submission limits.

All state lives in the database (user_actions table), so limits survive
restarts and work with several server processes.
"""

import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import ApiError
from app.models import ActionType, CoolerPhoto, User, UserAction, WaterCooler

AUTO_APPROVE_THRESHOLD = 500
APPROVE_REWARD = 50
REJECT_PENALTY = -100
STATUS_REPORT_REWARD = 10
CONFIRM_REWARD = 5

COOLDOWNS = {
    ActionType.confirm: timedelta(hours=1),
    ActionType.status_report: timedelta(hours=1),
}

MAX_NEW_COOLERS_PER_HOUR = 10
MAX_PHOTOS_PER_HOUR = 30
DUPLICATE_RADIUS_M = 15.0


def is_trusted(user: User) -> bool:
    return user.trust_score >= AUTO_APPROVE_THRESHOLD


async def add_trust(db: AsyncSession, user_id: uuid.UUID, delta: int) -> int:
    """Atomically change a user's score (never below 0). Returns the new score."""
    result = await db.execute(
        update(User)
        .where(User.id == user_id)
        .values(trust_score=func.greatest(0, User.trust_score + delta))
        .returning(User.trust_score)
    )
    return result.scalar_one()


async def enforce_cooldown(
    db: AsyncSession, user_id: uuid.UUID, cooler_id: uuid.UUID, action: ActionType
) -> None:
    window = COOLDOWNS[action]
    since = datetime.now(timezone.utc) - window
    last = await db.scalar(
        select(func.max(UserAction.created_at)).where(
            UserAction.user_id == user_id,
            UserAction.cooler_id == cooler_id,
            UserAction.action == action,
            UserAction.created_at > since,
        )
    )
    if last is not None:
        remaining = (last + window) - datetime.now(timezone.utc)
        minutes = max(1, int(remaining.total_seconds() // 60) + 1)
        raise ApiError(
            429,
            f"{action.value}_cooldown",
            f"You can do this again for this cooler in {minutes} minute(s).",
            retry_after_minutes=minutes,
        )


def record_action(
    db: AsyncSession, user_id: uuid.UUID, cooler_id: uuid.UUID, action: ActionType
) -> None:
    db.add(UserAction(user_id=user_id, cooler_id=cooler_id, action=action))


async def reset_confirmations(db: AsyncSession, cooler_id: uuid.UUID) -> None:
    """When a cooler's status changes, everyone may confirm it again."""
    await db.execute(
        delete(UserAction).where(
            UserAction.cooler_id == cooler_id, UserAction.action == ActionType.confirm
        )
    )


async def enforce_submission_limits(db: AsyncSession, user_id: uuid.UUID, *, photos: bool) -> None:
    since = datetime.now(timezone.utc) - timedelta(hours=1)
    if photos:
        count = await db.scalar(
            select(func.count(CoolerPhoto.id)).where(
                CoolerPhoto.user_id == user_id, CoolerPhoto.uploaded_at > since
            )
        )
        limit, code = MAX_PHOTOS_PER_HOUR, "photo_limit"
    else:
        count = await db.scalar(
            select(func.count(WaterCooler.id)).where(
                WaterCooler.user_id == user_id, WaterCooler.created_at > since
            )
        )
        limit, code = MAX_NEW_COOLERS_PER_HOUR, "cooler_limit"
    if (count or 0) >= limit:
        raise ApiError(429, code, "Too many submissions. Please try again later.")
