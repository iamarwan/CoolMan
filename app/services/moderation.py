"""Admin moderation actions (used by the web admin panel)."""

import uuid
from datetime import datetime, timezone

from fastapi import UploadFile
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import not_found
from app.models import CoolerPhoto, CoolerStatus, PhotoCategory, Sponsor, SponsorType, WaterCooler
from app.services import trust
from app.services.coolers import get_cooler
from app.services.images import delete_photo_files, save_photo


async def get_photo(db: AsyncSession, photo_id: uuid.UUID) -> CoolerPhoto:
    photo = await db.get(CoolerPhoto, photo_id)
    if photo is None:
        raise not_found("photo")
    return photo


async def get_sponsor(db: AsyncSession, sponsor_id: uuid.UUID) -> Sponsor:
    sponsor = await db.get(Sponsor, sponsor_id)
    if sponsor is None:
        raise not_found("sponsor")
    return sponsor


def _apply_status(cooler: WaterCooler, status: CoolerStatus) -> None:
    cooler.status = status
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    cooler.last_verified_at = datetime.now(timezone.utc)


async def approve_cooler(db: AsyncSession, cooler_id: uuid.UUID) -> None:
    """Approves a new cooler (with its photos, rewarding the submitter) and/or
    applies its pending status change."""
    cooler = await get_cooler(db, cooler_id)
    if cooler.pending_status is not None:
        if cooler.status != cooler.pending_status:
            await trust.reset_confirmations(db, cooler.id)
        _apply_status(cooler, cooler.pending_status)
    if not cooler.is_approved and not cooler.is_rejected:
        cooler.is_approved = True
        for photo in cooler.photos:
            photo.is_approved = True
        if cooler.user_id:
            await trust.add_trust(db, cooler.user_id, trust.APPROVE_REWARD)
    await db.commit()


async def reject_cooler(db: AsyncSession, cooler_id: uuid.UUID) -> None:
    """Hides a cooler. Penalises the submitter if it was never approved."""
    cooler = await get_cooler(db, cooler_id)
    if not cooler.is_approved and not cooler.is_rejected and cooler.user_id:
        await trust.add_trust(db, cooler.user_id, trust.REJECT_PENALTY)
    cooler.is_rejected = True
    cooler.is_approved = False
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    await db.commit()


async def restore_cooler(db: AsyncSession, cooler_id: uuid.UUID) -> None:
    """Undo a rejection (no trust changes)."""
    cooler = await get_cooler(db, cooler_id)
    cooler.is_rejected = False
    cooler.is_approved = True
    await db.commit()


async def reject_status_change(db: AsyncSession, cooler_id: uuid.UUID) -> None:
    cooler = await get_cooler(db, cooler_id)
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    await db.commit()


async def force_status(db: AsyncSession, cooler_id: uuid.UUID, status: CoolerStatus) -> None:
    cooler = await get_cooler(db, cooler_id)
    if cooler.status != status:
        await trust.reset_confirmations(db, cooler.id)
    _apply_status(cooler, status)
    await db.commit()


async def delete_cooler(db: AsyncSession, cooler_id: uuid.UUID) -> None:
    cooler = await get_cooler(db, cooler_id)
    files = [p for photo in cooler.photos for p in (photo.file_path, photo.thumb_path)]
    await db.delete(cooler)
    await db.commit()
    delete_photo_files(*files)


async def set_sponsor(db: AsyncSession, cooler_id: uuid.UUID, sponsor_id: uuid.UUID | None) -> None:
    cooler = await get_cooler(db, cooler_id)
    cooler.sponsor_id = (await get_sponsor(db, sponsor_id)).id if sponsor_id else None
    await db.commit()


async def upload_photo(
    db: AsyncSession, cooler_id: uuid.UUID, file: UploadFile, category: PhotoCategory
) -> None:
    cooler = await get_cooler(db, cooler_id)
    file_path, thumb_path = await save_photo(file)
    db.add(
        CoolerPhoto(
            cooler_id=cooler.id,
            file_path=file_path,
            thumb_path=thumb_path,
            photo_category=category,
            is_approved=True,
        )
    )
    await db.commit()


async def approve_photo(db: AsyncSession, photo_id: uuid.UUID) -> None:
    (await get_photo(db, photo_id)).is_approved = True
    await db.commit()


async def delete_photo(db: AsyncSession, photo_id: uuid.UUID) -> None:
    photo = await get_photo(db, photo_id)
    files = (photo.file_path, photo.thumb_path)
    await db.delete(photo)
    await db.commit()
    delete_photo_files(*files)


async def create_sponsor(
    db: AsyncSession, name: str, sponsor_type: SponsorType, contact: str | None
) -> Sponsor:
    sponsor = Sponsor(name=name, sponsor_type=sponsor_type, contact=contact or None)
    db.add(sponsor)
    await db.commit()
    return sponsor


async def verify_sponsor(db: AsyncSession, sponsor_id: uuid.UUID, verified: bool = True) -> None:
    (await get_sponsor(db, sponsor_id)).verified = verified
    await db.commit()


async def delete_sponsor(db: AsyncSession, sponsor_id: uuid.UUID) -> None:
    sponsor = await get_sponsor(db, sponsor_id)
    await db.execute(
        update(WaterCooler).where(WaterCooler.sponsor_id == sponsor.id).values(sponsor_id=None)
    )
    await db.delete(sponsor)
    await db.commit()
