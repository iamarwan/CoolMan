from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.models import ActionType, CoolerPhoto, User, UserAction, WaterCooler
from app.schemas import LeaderboardEntry
from app.security import get_current_user
from app.services.trust import AUTO_APPROVE_THRESHOLD

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/leaderboard", response_model=list[LeaderboardEntry])
async def leaderboard(db: AsyncSession = Depends(get_db)):
    rows = await db.execute(
        select(User.username, User.trust_score)
        .order_by(User.trust_score.desc(), User.created_at)
        .limit(10)
    )
    return [
        LeaderboardEntry(rank=i + 1, username=u, trust_score=s)
        for i, (u, s) in enumerate(rows.all())
    ]


class UserStats(BaseModel):
    trust_score: int
    trusted_threshold: int
    coolers_added: int
    coolers_approved: int
    confirmations: int
    photos: int
    rank: int


@router.get("/me/stats", response_model=UserStats)
async def my_stats(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    added = await db.scalar(select(func.count()).where(WaterCooler.user_id == user.id))
    approved = await db.scalar(
        select(func.count()).where(WaterCooler.user_id == user.id, WaterCooler.is_approved)
    )
    confirms = await db.scalar(
        select(func.count()).where(
            UserAction.user_id == user.id, UserAction.action == ActionType.confirm
        )
    )
    photos = await db.scalar(select(func.count()).where(CoolerPhoto.user_id == user.id))
    # Rank: people with more points, then earlier sign-ups among equals.
    ahead = await db.scalar(
        select(func.count(User.id)).where(
            (User.trust_score > user.trust_score)
            | ((User.trust_score == user.trust_score) & (User.created_at < user.created_at))
        )
    )
    return UserStats(
        trust_score=user.trust_score,
        trusted_threshold=AUTO_APPROVE_THRESHOLD,
        coolers_added=added or 0,
        coolers_approved=approved or 0,
        confirmations=confirms or 0,
        photos=photos or 0,
        rank=(ahead or 0) + 1,
    )
