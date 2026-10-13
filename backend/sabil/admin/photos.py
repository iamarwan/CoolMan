# admin/photos.py
#
# Admin: photo moderation. Mounted under /admin by admin/router.py.

import uuid

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.coolers.models import CoolerPhoto
from sabil.coolers.photos import add_photo
from sabil.coolers.schemas import CoolerPhotoRead
from sabil.core.database import get_db
from sabil.core.lookup import get_or_404
from sabil.media.storage import delete_image

router = APIRouter()


@router.get("/coolers/{cooler_id}/photos", response_model=list[CoolerPhotoRead])
async def get_cooler_photos_admin(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    """All photos of a cooler, approved or not."""
    stmt = select(CoolerPhoto).where(CoolerPhoto.cooler_id == cooler_id)
    return (await db.execute(stmt)).scalars().all()


@router.post("/coolers/{cooler_id}/photos", response_model=CoolerPhotoRead, status_code=201)
async def admin_upload_cooler_photo(
    cooler_id: uuid.UUID,
    file: UploadFile = File(...),
    photo_category: str = Form("Cooler"),
    db: AsyncSession = Depends(get_db),
):
    """Admin-uploaded photos are approved immediately."""
    return await add_photo(db, cooler_id, file, photo_category, approved=True)


@router.patch("/photos/{photo_id}/approve")
async def approve_photo(photo_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    photo = await get_or_404(db, CoolerPhoto, photo_id, "Photo")
    photo.is_approved = True
    await db.commit()
    return {"message": "Photo approved"}


@router.delete("/photos/{photo_id}")
async def delete_photo(photo_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    photo = await get_or_404(db, CoolerPhoto, photo_id, "Photo")
    delete_image(photo.file_path)
    await db.delete(photo)
    await db.commit()
    return {"message": "Photo deleted"}
