# admin/coolers.py
#
# Admin: the review queue and cooler moderation.
# Mounted under /admin by admin/router.py, which also requires an admin token.

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.coolers.models import CoolerPhoto, WaterCooler
from sabil.coolers.schemas import StatusUpdate, WaterCoolerRead
from sabil.core.database import get_db
from sabil.core.lookup import get_or_404
from sabil.core.rate_limit import reset_confirm_cooldown
from sabil.users.models import User
from sabil.users.trust import APPROVE_REWARD, REJECT_PENALTY, reward

router = APIRouter()


@router.get("/coolers/pending", response_model=list[WaterCoolerRead])
async def get_pending_coolers(db: AsyncSession = Depends(get_db)):
    """Review queue: new coolers, proposed status changes, and coolers with unreviewed photos."""
    stmt = select(WaterCooler).where(
        or_(
            and_(WaterCooler.is_approved == False, WaterCooler.is_rejected == False),  # noqa: E712
            WaterCooler.pending_status.is_not(None),
            WaterCooler.photos.any(CoolerPhoto.is_approved == False),  # noqa: E712
        )
    )
    return (await db.execute(stmt)).scalars().all()


@router.get("/coolers/current", response_model=list[WaterCoolerRead])
async def get_current_coolers(db: AsyncSession = Depends(get_db)):
    """Every approved (live) cooler."""
    stmt = select(WaterCooler).where(WaterCooler.is_approved == True)  # noqa: E712
    return (await db.execute(stmt)).scalars().all()


@router.patch("/coolers/{cooler_id}/approve")
async def approve_cooler(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Approve a new cooler and/or a proposed status change."""
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")

    if cooler.pending_status:
        cooler.status = cooler.pending_status
        cooler.pending_status = None
        cooler.pending_status_user_id = None
        reset_confirm_cooldown(cooler_id)

    if not cooler.is_approved and not cooler.is_rejected:
        cooler.is_approved = True
        for photo in cooler.photos:
            photo.is_approved = True
        if cooler.user_id:
            submitter = await get_or_404(db, User, cooler.user_id, "User")
            reward(submitter, APPROVE_REWARD)

    await db.commit()
    return {"message": "Approved"}


@router.patch("/coolers/{cooler_id}/reject")
async def reject_cooler(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")

    if not cooler.is_approved and not cooler.is_rejected and cooler.user_id:
        submitter = await get_or_404(db, User, cooler.user_id, "User")
        reward(submitter, REJECT_PENALTY)

    cooler.is_rejected = True
    cooler.is_approved = False
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    await db.commit()
    return {"message": "Rejected"}


@router.patch("/coolers/{cooler_id}/reject-status")
async def reject_status_change(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Throw away a user's proposed status change."""
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    await db.commit()
    return {"message": "Status change rejected"}


@router.patch("/coolers/{cooler_id}/force-status")
async def admin_force_status(
    cooler_id: uuid.UUID,
    payload: StatusUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Set the status directly, with no review."""
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    cooler.status = payload.status
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    cooler.last_verified_at = datetime.now(timezone.utc)
    reset_confirm_cooldown(cooler_id)
    await db.commit()
    return {"message": "Status forcefully updated"}


@router.delete("/coolers/{cooler_id}")
async def delete_cooler(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")
    await db.delete(cooler)
    await db.commit()
    return {"message": "Deleted"}
