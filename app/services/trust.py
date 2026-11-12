"""Trust points, cooldowns and submission limits.

All state lives in the database (user_actions table), so limits survive
restarts and work with several server processes.
"""

import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select, update
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

# Points can be earned for at most this many confirmations/reports per 24 hours.
# Beyond it the action still counts, but earns nothing. This stops a single
# account from confirming every cooler on the map to reach "trusted" in a day.
MAX_REWARDED_ACTIONS_PER_DAY = 20

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


async def lock(db: AsyncSession, key: str) -> None:
    """Serialises concurrent requests for the same key until this transaction
    ends, so two simultaneous taps cannot both pass a check."""
    await db.execute(select(func.pg_advisory_xact_lock(func.hashtext(key))))


async def enforce_cooldown(
    db: AsyncSession,
    user_id: uuid.UUID,
    cooler: WaterCooler,
    action: ActionType,
) -> None:
    await lock(db, f"{action.value}:{user_id}:{cooler.id}")
    window = COOLDOWNS[action]
    since = datetime.now(timezone.utc) - window
    # A status change makes earlier confirmations irrelevant: people may
    # confirm the new state right away.
    if action is ActionType.confirm and cooler.status_changed_at and cooler.status_changed_at > since:
        since = cooler.status_changed_at
    last = await db.scalar(
        select(func.max(UserAction.created_at)).where(
            UserAction.user_id == user_id,
            UserAction.cooler_id == cooler.id,
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


async def record_action(
    db: AsyncSession,
    user_id: uuid.UUID,
    cooler_id: uuid.UUID,
    action: ActionType,
    reward: int = 0,
) -> tuple[int, int | None]:
    """Logs the action and pays `reward` points unless the daily cap is reached.
    Returns (points_awarded, new_score or None if nothing was paid)."""
    points = 0
    if reward > 0:
        await lock(db, f"daily-cap:{user_id}")
        since = datetime.now(timezone.utc) - timedelta(hours=24)
        rewarded = await db.scalar(
            select(func.count(UserAction.id)).where(
                UserAction.user_id == user_id,
                UserAction.points > 0,
                UserAction.created_at > since,
            )
        )
        if (rewarded or 0) < MAX_REWARDED_ACTIONS_PER_DAY:
            points = reward
    db.add(UserAction(user_id=user_id, cooler_id=cooler_id, action=action, points=points))
    score = await add_trust(db, user_id, points) if points else None
    return points, score


def set_status(cooler: WaterCooler, status) -> None:
    """Applies a status and clears any pending report."""
    now = datetime.now(timezone.utc)
    if cooler.status != status:
        cooler.status_changed_at = now
    cooler.status = status
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    cooler.last_verified_at = now


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
