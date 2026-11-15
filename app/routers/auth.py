from datetime import timedelta

from fastapi import APIRouter, Depends, Request, Response
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import get_db
from app.errors import ApiError
from app.models import User
from app.schemas import AuthResponse, Credentials, UserRead
from app.security import create_user_token, get_current_user, hash_password
from app.services import accounts, ratelimit

router = APIRouter(prefix="/auth", tags=["auth"])


def _auth_response(user: User) -> AuthResponse:
    return AuthResponse(
        id=user.id,
        username=user.username,
        trust_score=user.trust_score,
        access_token=create_user_token(user.id),
    )


@router.post("/register", response_model=AuthResponse, status_code=201)
async def register(payload: Credentials, request: Request, db: AsyncSession = Depends(get_db)):
    bucket = f"register:ip:{ratelimit.client_ip(request)}"
    await ratelimit.check(
        db,
        bucket,
        get_settings().registrations_per_ip_per_hour,
        window=timedelta(hours=1),
        code="rate_limited",
    )
    taken = await db.scalar(
        select(User.id).where(func.lower(User.username) == payload.username.lower())
    )
    if taken:
        raise ApiError(409, "username_taken", "Username already taken.")
    user = User(username=payload.username, hashed_password=await hash_password(payload.password))
    db.add(user)
    try:
        await db.commit()
    except IntegrityError:  # two sign-ups with the same name at the same moment
        await db.rollback()
        raise ApiError(409, "username_taken", "Username already taken.")
    await ratelimit.record(db, bucket)
    return _auth_response(user)


@router.post("/login", response_model=AuthResponse)
async def login(payload: Credentials, request: Request, db: AsyncSession = Depends(get_db)):
    user = await accounts.authenticate(db, request, payload.username, payload.password)
    return _auth_response(user)


@router.get("/me", response_model=UserRead)
async def me(user: User = Depends(get_current_user)):
    return user


class DeleteAccount(BaseModel):
    password: str = Field(..., max_length=128)


@router.delete("/me", status_code=204)
async def delete_me(
    payload: DeleteAccount,
    request: Request,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Permanently deletes the account (required by app-store rules). The
    user's coolers and photos stay on the map without a link to the account."""
    await accounts.delete_account(db, request, user, payload.password)
    return Response(status_code=204)
