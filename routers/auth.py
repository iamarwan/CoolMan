from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, Field

from database import get_db
from models import User
from schemas import UserAuthResponse
from auth import (
    authenticate_admin,
    create_admin_token,
    create_user_token,
    get_current_user,
    hash_password,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])

class AdminLoginRequest(BaseModel):
    username: str
    password: str

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=64, pattern=r"^[a-zA-Z0-9_]+$")
    password: str = Field(..., min_length=8, max_length=128)

class UserRead(BaseModel):
    id: str
    username: str
    trust_score: int

@router.post("/admin/login")
async def admin_login(payload: AdminLoginRequest):
    if not authenticate_admin(payload.username, payload.password):
        raise HTTPException(status_code=401, detail="Invalid credentials.")
    return {"access_token": create_admin_token(payload.username)}

@router.post("/register", response_model=UserAuthResponse, status_code=201)
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
    token = create_user_token(user.id)
    return {
        "id": str(user.id),
        "username": user.username,
        "trust_score": user.trust_score,
        "access_token": token,
    }

@router.post("/login", response_model=UserAuthResponse)
async def user_login(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.username == payload.username))
    user = result.scalars().first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials.")
    return {
        "access_token": create_user_token(user.id),
        "id": str(user.id),
        "username": user.username,
        "trust_score": user.trust_score,
    }

@router.get("/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": str(current_user.id),
        "username": current_user.username,
        "trust_score": current_user.trust_score,
    }
