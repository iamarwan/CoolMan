from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.errors import ApiError
from app.models import User
from app.schemas import AuthResponse, Credentials, UserRead
from app.security import (
    create_user_token,
    get_current_user,
    hash_password,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


def _auth_response(user: User) -> AuthResponse:
    return AuthResponse(
        id=user.id,
        username=user.username,
        trust_score=user.trust_score,
        access_token=create_user_token(user.id),
    )


@router.post("/register", response_model=AuthResponse, status_code=201)
async def register(payload: Credentials, db: AsyncSession = Depends(get_db)):
    taken = await db.scalar(select(User.id).where(User.username == payload.username))
    if taken:
        raise ApiError(409, "username_taken", "Username already taken.")
    user = User(username=payload.username, hashed_password=await hash_password(payload.password))
    db.add(user)
    try:
        await db.commit()
    except IntegrityError:  # two sign-ups with the same name at the same moment
        await db.rollback()
        raise ApiError(409, "username_taken", "Username already taken.")
    return _auth_response(user)


@router.post("/login", response_model=AuthResponse)
async def login(payload: Credentials, db: AsyncSession = Depends(get_db)):
    user = await db.scalar(select(User).where(User.username == payload.username))
    if user is None or not await verify_password(payload.password, user.hashed_password):
        raise ApiError(401, "invalid_credentials", "Invalid username or password.")
    return _auth_response(user)


@router.get("/me", response_model=UserRead)
async def me(user: User = Depends(get_current_user)):
    return user
