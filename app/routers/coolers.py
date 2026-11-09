"""Public and user cooler endpoints."""

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.errors import ApiError
from app.models import ActionType, CoolerPhoto, PhotoCategory, User, WaterCooler
from app.schemas import (
    ConfirmResponse,
    CoolerCreate,
    CoolerPin,
    CoolerRead,
    PhotoRead,
    PinsResponse,
    StatusUpdate,
)
from app.security import get_current_user
from app.services import trust
from app.services.coolers import (
    distance_to,
    get_cooler,
    get_public_cooler,
    load_fresh,
    point,
    to_public,
    within_meters,
)
from app.services.images import save_photo

router = APIRouter(prefix="/coolers", tags=["coolers"])


# ── Read ─────────────────────────────────────────────────────────────────────
# Static paths are declared before /{cooler_id} so they are matched first.

@router.get("/map", response_model=PinsResponse)
async def map_pins(
    min_lat: float = Query(..., ge=-90, le=90),
    min_lng: float = Query(..., ge=-180, le=180),
    max_lat: float = Query(..., ge=-90, le=90),
    max_lng: float = Query(..., ge=-180, le=180),
    limit: int = Query(500, ge=1, le=2000),
    db: AsyncSession = Depends(get_db),
):
    """Approved coolers inside the visible map area, as minimal pins."""
    if min_lat > max_lat or min_lng > max_lng:
        raise ApiError(422, "bbox_invalid", "min values must be smaller than max values.")
    envelope = func.ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)
    rows = (
        await db.execute(
            select(
                WaterCooler.id,
                WaterCooler.latitude,
                WaterCooler.longitude,
                WaterCooler.status,
                WaterCooler.has_cups,
                WaterCooler.sponsor_id,
            )
            .where(WaterCooler.is_approved, WaterCooler.geom.op("&&")(envelope))
            .limit(limit + 1)
        )
    ).all()
    pins = [
        CoolerPin(
            id=r.id,
            lat=float(r.latitude),
            lng=float(r.longitude),
            status=r.status,
            has_cups=r.has_cups,
            sponsored=r.sponsor_id is not None,
        )
        for r in rows[:limit]
    ]
    return PinsResponse(pins=pins, truncated=len(rows) > limit)


@router.get("/nearby", response_model=list[CoolerRead], deprecated=True)
async def nearby(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(5.0, gt=0, le=20),
    db: AsyncSession = Depends(get_db),
):
    """TEMPORARY: kept so the pre-rework app keeps working. Use /coolers/map."""
    result = await db.execute(
        select(WaterCooler)
        .where(WaterCooler.is_approved, within_meters(lat, lng, radius_km * 1000))
        .order_by(distance_to(lat, lng))
        .limit(300)
    )
    return [to_public(c) for c in result.scalars().all()]


@router.get("/search", response_model=list[CoolerRead])
async def search(
    q: str = Query(..., min_length=1, max_length=100),
    lat: float | None = Query(None, ge=-90, le=90),
    lng: float | None = Query(None, ge=-180, le=180),
    db: AsyncSession = Depends(get_db),
):
    """Name search. If lat/lng are given, nearest results come first."""
    escaped = q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    stmt = select(WaterCooler).where(
        WaterCooler.is_approved, WaterCooler.name.ilike(f"%{escaped}%", escape="\\")
    )
    if lat is not None and lng is not None:
        stmt = stmt.order_by(distance_to(lat, lng))
    else:
        stmt = stmt.order_by(WaterCooler.name)
    result = await db.execute(stmt.limit(30))
    return [to_public(c) for c in result.scalars().all()]


@router.get("/my", response_model=list[CoolerRead])
async def my_coolers(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Coolers the user added or has a pending status report on."""
    result = await db.execute(
        select(WaterCooler)
        .where(or_(WaterCooler.user_id == user.id, WaterCooler.pending_status_user_id == user.id))
        .order_by(WaterCooler.created_at.desc())
    )
    return result.scalars().all()


@router.get("/{cooler_id}", response_model=CoolerRead)
async def cooler_detail(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    return to_public(await get_public_cooler(db, cooler_id))


@router.get("/{cooler_id}/photos", response_model=list[PhotoRead])
async def cooler_photos(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    return to_public(await get_public_cooler(db, cooler_id)).photos


# ── Write ────────────────────────────────────────────────────────────────────

@router.post("", response_model=CoolerRead, status_code=201)
async def create_cooler(
    payload: CoolerCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await trust.enforce_submission_limits(db, user.id, photos=False)

    duplicate = await db.scalar(
        select(WaterCooler.id).where(
            WaterCooler.is_rejected.is_(False),
            within_meters(payload.latitude, payload.longitude, trust.DUPLICATE_RADIUS_M),
        )
    )
    if duplicate:
        raise ApiError(
            409,
            "cooler_duplicate",
            "A water cooler is already listed at this spot.",
            existing_id=str(duplicate),
        )

    approved = trust.is_trusted(user)
    cooler = WaterCooler(
        name=payload.name,
        latitude=payload.latitude,
        longitude=payload.longitude,
        geom=point(payload.latitude, payload.longitude),
        status=payload.status,
        has_cups=payload.has_cups,
        cups_type=payload.cups_type,
        is_wheelchair_accessible=payload.is_wheelchair_accessible,
        is_approved=approved,
        user_id=user.id,
    )
    db.add(cooler)
    await db.flush()
    if approved:
        await trust.add_trust(db, user.id, trust.APPROVE_REWARD)
    await db.commit()
    return await load_fresh(db, cooler.id)


@router.patch("/{cooler_id}/status", response_model=CoolerRead)
async def report_status(
    cooler_id: uuid.UUID,
    payload: StatusUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Report Working/Empty/Broken. Trusted users apply it instantly; others
    create a pending change for admin review. Rewarded once per hour per cooler."""
    cooler = await get_public_cooler(db, cooler_id)
    await trust.enforce_cooldown(db, user.id, cooler.id, ActionType.status_report)

    if trust.is_trusted(user):
        if cooler.status != payload.status:
            await trust.reset_confirmations(db, cooler.id)
        cooler.status = payload.status
        cooler.pending_status = None
        cooler.pending_status_user_id = None
        cooler.last_verified_at = datetime.now(timezone.utc)
    else:
        cooler.pending_status = payload.status
        cooler.pending_status_user_id = user.id

    trust.record_action(db, user.id, cooler.id, ActionType.status_report)
    await trust.add_trust(db, user.id, trust.STATUS_REPORT_REWARD)
    await db.commit()
    return to_public(await load_fresh(db, cooler.id))


@router.post("/{cooler_id}/confirm", response_model=ConfirmResponse)
async def confirm_working(
    cooler_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """One-tap "still working" confirmation. Once per hour per cooler."""
    cooler = await get_public_cooler(db, cooler_id)
    await trust.enforce_cooldown(db, user.id, cooler.id, ActionType.confirm)

    cooler.last_verified_at = datetime.now(timezone.utc)
    trust.record_action(db, user.id, cooler.id, ActionType.confirm)
    score = await trust.add_trust(db, user.id, trust.CONFIRM_REWARD)
    verified_at = cooler.last_verified_at
    await db.commit()
    return ConfirmResponse(message="Confirmed", trust_score=score, last_verified_at=verified_at)


@router.post("/{cooler_id}/photos", response_model=PhotoRead, status_code=201)
async def upload_photo(
    cooler_id: uuid.UUID,
    file: UploadFile = File(...),
    photo_category: PhotoCategory = Form(PhotoCategory.Cooler),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cooler = await get_cooler(db, cooler_id)
    if cooler.is_rejected:
        raise ApiError(400, "cooler_rejected", "This cooler was rejected.")
    # Anyone may add photos to approved coolers; only the submitter to pending ones.
    if not cooler.is_approved and cooler.user_id != user.id:
        raise ApiError(404, "cooler_not_found", "Cooler not found.")
    await trust.enforce_submission_limits(db, user.id, photos=True)

    file_path, thumb_path = await save_photo(file)
    photo = CoolerPhoto(
        cooler_id=cooler.id,
        file_path=file_path,
        thumb_path=thumb_path,
        photo_category=photo_category,
        user_id=user.id,
        is_approved=trust.is_trusted(user) and cooler.is_approved,
    )
    db.add(photo)
    await db.commit()
    await db.refresh(photo)
    return photo
