"""Admin JSON API (used by the admin screens until the web admin replaces them)."""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy import and_, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.errors import not_found
from app.models import CoolerPhoto, PhotoCategory, Sponsor, WaterCooler
from app.schemas import CoolerRead, Message, PhotoRead, SponsorAssign, SponsorCreate, SponsorRead, StatusUpdate
from app.security import require_admin
from app.services import trust
from app.services.coolers import get_cooler, load_fresh
from app.services.images import delete_photo_files, save_photo

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])


async def _get_photo(db: AsyncSession, photo_id: uuid.UUID) -> CoolerPhoto:
    photo = await db.get(CoolerPhoto, photo_id)
    if photo is None:
        raise not_found("photo")
    return photo


async def _get_sponsor(db: AsyncSession, sponsor_id: uuid.UUID) -> Sponsor:
    sponsor = await db.get(Sponsor, sponsor_id)
    if sponsor is None:
        raise not_found("sponsor")
    return sponsor


# ── Moderation queues ────────────────────────────────────────────────────────

@router.get("/coolers/pending", response_model=list[CoolerRead])
async def pending(db: AsyncSession = Depends(get_db)):
    """New submissions, pending status changes, and coolers with unreviewed photos."""
    result = await db.execute(
        select(WaterCooler)
        .where(
            or_(
                and_(WaterCooler.is_approved.is_(False), WaterCooler.is_rejected.is_(False)),
                WaterCooler.pending_status.is_not(None),
                WaterCooler.photos.any(CoolerPhoto.is_approved.is_(False)),
            )
        )
        .order_by(WaterCooler.created_at)
    )
    return result.scalars().all()


@router.get("/coolers/current", response_model=list[CoolerRead])
async def current(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(WaterCooler).where(WaterCooler.is_approved).order_by(WaterCooler.name)
    )
    return result.scalars().all()


@router.patch("/coolers/{cooler_id}/approve", response_model=Message)
async def approve(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """Approves a new cooler (and its photos) and/or its pending status change."""
    cooler = await get_cooler(db, cooler_id)

    if cooler.pending_status is not None:
        if cooler.status != cooler.pending_status:
            await trust.reset_confirmations(db, cooler.id)
        cooler.status = cooler.pending_status
        cooler.pending_status = None
        cooler.pending_status_user_id = None
        cooler.last_verified_at = datetime.now(timezone.utc)

    if not cooler.is_approved and not cooler.is_rejected:
        cooler.is_approved = True
        for photo in cooler.photos:
            photo.is_approved = True
        if cooler.user_id:
            await trust.add_trust(db, cooler.user_id, trust.APPROVE_REWARD)

    await db.commit()
    return Message(message="Approved")


@router.patch("/coolers/{cooler_id}/reject", response_model=Message)
async def reject(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    cooler = await get_cooler(db, cooler_id)
    if not cooler.is_approved and not cooler.is_rejected and cooler.user_id:
        await trust.add_trust(db, cooler.user_id, trust.REJECT_PENALTY)
    cooler.is_rejected = True
    cooler.is_approved = False
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    await db.commit()
    return Message(message="Rejected")


@router.patch("/coolers/{cooler_id}/reject-status", response_model=Message)
async def reject_status(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    cooler = await get_cooler(db, cooler_id)
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    await db.commit()
    return Message(message="Status change rejected")


@router.patch("/coolers/{cooler_id}/force-status", response_model=Message)
async def force_status(cooler_id: uuid.UUID, payload: StatusUpdate, db: AsyncSession = Depends(get_db)):
    cooler = await get_cooler(db, cooler_id)
    if cooler.status != payload.status:
        await trust.reset_confirmations(db, cooler.id)
    cooler.status = payload.status
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    cooler.last_verified_at = datetime.now(timezone.utc)
    await db.commit()
    return Message(message="Status updated")


@router.delete("/coolers/{cooler_id}", response_model=Message)
async def delete_cooler(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    cooler = await get_cooler(db, cooler_id)
    files = [p for photo in cooler.photos for p in (photo.file_path, photo.thumb_path)]
    await db.delete(cooler)
    await db.commit()
    delete_photo_files(*files)
    return Message(message="Deleted")


# ── Photos ───────────────────────────────────────────────────────────────────

@router.get("/coolers/{cooler_id}/photos", response_model=list[PhotoRead])
async def cooler_photos(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    return (await get_cooler(db, cooler_id)).photos


@router.post("/coolers/{cooler_id}/photos", response_model=PhotoRead, status_code=201)
async def upload_photo(
    cooler_id: uuid.UUID,
    file: UploadFile = File(...),
    photo_category: PhotoCategory = Form(PhotoCategory.Cooler),
    db: AsyncSession = Depends(get_db),
):
    cooler = await get_cooler(db, cooler_id)
    file_path, thumb_path = await save_photo(file)
    photo = CoolerPhoto(
        cooler_id=cooler.id,
        file_path=file_path,
        thumb_path=thumb_path,
        photo_category=photo_category,
        is_approved=True,
    )
    db.add(photo)
    await db.commit()
    await db.refresh(photo)
    return photo


@router.patch("/photos/{photo_id}/approve", response_model=Message)
async def approve_photo(photo_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    photo = await _get_photo(db, photo_id)
    photo.is_approved = True
    await db.commit()
    return Message(message="Photo approved")


@router.delete("/photos/{photo_id}", response_model=Message)
async def delete_photo(photo_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    photo = await _get_photo(db, photo_id)
    files = (photo.file_path, photo.thumb_path)
    await db.delete(photo)
    await db.commit()
    delete_photo_files(*files)
    return Message(message="Photo deleted")


# ── Sponsors ─────────────────────────────────────────────────────────────────

@router.post("/sponsors", response_model=SponsorRead, status_code=201)
async def create_sponsor(payload: SponsorCreate, db: AsyncSession = Depends(get_db)):
    sponsor = Sponsor(**payload.model_dump())
    db.add(sponsor)
    await db.commit()
    await db.refresh(sponsor)
    return sponsor


@router.patch("/sponsors/{sponsor_id}/verify", response_model=SponsorRead)
async def verify_sponsor(sponsor_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    sponsor = await _get_sponsor(db, sponsor_id)
    sponsor.verified = True
    await db.commit()
    await db.refresh(sponsor)
    return sponsor


@router.delete("/sponsors/{sponsor_id}", response_model=Message)
async def delete_sponsor(sponsor_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    sponsor = await _get_sponsor(db, sponsor_id)
    await db.execute(
        update(WaterCooler).where(WaterCooler.sponsor_id == sponsor.id).values(sponsor_id=None)
    )
    await db.delete(sponsor)
    await db.commit()
    return Message(message="Sponsor deleted")


@router.patch("/coolers/{cooler_id}/assign-sponsor", response_model=CoolerRead)
async def assign_sponsor(cooler_id: uuid.UUID, payload: SponsorAssign, db: AsyncSession = Depends(get_db)):
    cooler = await get_cooler(db, cooler_id)
    sponsor = await _get_sponsor(db, payload.sponsor_id)
    cooler.sponsor_id = sponsor.id
    await db.commit()
    return await load_fresh(db, cooler.id)


@router.delete("/coolers/{cooler_id}/assign-sponsor", response_model=CoolerRead)
async def remove_sponsor(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    cooler = await get_cooler(db, cooler_id)
    cooler.sponsor_id = None
    await db.commit()
    return await load_fresh(db, cooler.id)
