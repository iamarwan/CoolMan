# coolers/photos.py
#
# Attaching a photo to a cooler. Used by BOTH the user upload route
# (coolers/router.py) and the admin upload route (admin/photos.py), so the
# validation and saving logic exists only once.

import uuid

from fastapi import HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.coolers.models import CoolerPhoto, PhotoCategory, WaterCooler
from sabil.core.lookup import get_or_404
from sabil.media.storage import save_image


def parse_category(value: str) -> PhotoCategory:
    """Turn the text sent by the app into a PhotoCategory (unknown text -> Cooler)."""
    try:
        return PhotoCategory(value)
    except ValueError:
        return PhotoCategory.Cooler


async def add_photo(
    db: AsyncSession,
    cooler_id: uuid.UUID,
    file: UploadFile,
    photo_category: str,
    *,
    user_id: uuid.UUID | None = None,
    approved: bool = False,
) -> CoolerPhoto:
    """Save the file, create its database row and return it.

    Users' photos start unapproved; pass approved=True for admin uploads.
    """
    cooler = await get_or_404(db, WaterCooler, cooler_id, "Cooler")

    try:
        url_path = save_image(file, str(cooler_id))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    photo = CoolerPhoto(
        cooler_id=cooler.id,
        file_path=url_path,
        photo_category=parse_category(photo_category),
        user_id=user_id,
        is_approved=approved,
    )
    db.add(photo)
    await db.commit()
    await db.refresh(photo)
    return photo
