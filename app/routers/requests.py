"""Build-a-sabil requests sent from the app. Each becomes a lead the team
follows up from the admin panel (/admin/requests)."""

from datetime import timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.models import SabilRequest, User
from app.schemas import SabilRequestCreate, SabilRequestRead
from app.security import get_current_user
from app.services import ratelimit

router = APIRouter(prefix="/sabil-requests", tags=["requests"])

# A real customer sends one or two; this only stops a script filling the list.
REQUESTS_PER_DAY = 5


@router.post("", response_model=SabilRequestRead, status_code=201)
async def create_request(
    body: SabilRequestCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    bucket = f"sabil-request:user:{user.id}"
    await ratelimit.check(db, bucket, REQUESTS_PER_DAY, window=timedelta(days=1), code="too_many_requests")
    data = body.model_dump()
    data["extras"] = ",".join(data["extras"])
    req = SabilRequest(user_id=user.id, **data)
    db.add(req)
    await ratelimit.record(db, bucket)  # commits the request too
    await db.refresh(req)
    return req


@router.get("/mine", response_model=list[SabilRequestRead])
async def my_requests(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    rows = await db.execute(
        select(SabilRequest).where(SabilRequest.user_id == user.id).order_by(SabilRequest.created_at.desc())
    )
    return rows.scalars().all()
