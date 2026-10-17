# users/router.py
#
# Registering, logging in, "who am I", and the leaderboard.

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.core.database import get_db
from sabil.core.dependencies import get_current_user
from sabil.core.rate_limit import auth_rate_limiter
from sabil.core.security import hash_password, verify_password
from sabil.users.models import User
from sabil.users.schemas import UserAuthResponse, UserCreate, UserRead
from sabil.users.tokens import auth_response

router = APIRouter(tags=["users"])


@router.post(
    "/auth/register",
    response_model=UserAuthResponse,
    status_code=201,
    dependencies=[Depends(auth_rate_limiter)],
)
async def register(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.username == payload.username))
    if existing.scalars().first():
        raise HTTPException(status_code=409, detail="Username already taken.")
    user = User(
        username=payload.username,
        hashed_password=hash_password(payload.password),
        trust_score=0,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return auth_response(user)


@router.post(
    "/auth/login",
    response_model=UserAuthResponse,
    dependencies=[Depends(auth_rate_limiter)],
)
async def user_login(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.username == payload.username))
    user = result.scalars().first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials.")
    return auth_response(user)


@router.get("/auth/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": str(current_user.id),
        "username": current_user.username,
        "trust_score": current_user.trust_score,
        "phone": current_user.phone,
    }


@router.get("/users/leaderboard")
async def get_leaderboard(db: AsyncSession = Depends(get_db)):
    """Top 10 users by trust score."""
    stmt = select(User).order_by(User.trust_score.desc()).limit(10)
    users = (await db.execute(stmt)).scalars().all()
    return [
        {"rank": i + 1, "username": u.username, "trust_score": u.trust_score}
        for i, u in enumerate(users)
    ]
