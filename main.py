# main.py

import os
import shutil
import time
from collections import defaultdict
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from fastapi import FastAPI, Depends, HTTPException, Query, Request, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from sqlalchemy import select, func, text, cast, String, or_, and_
from sqlalchemy.ext.asyncio import AsyncSession

from geoalchemy2 import Geography
from geoalchemy2.functions import ST_DWithin, ST_MakePoint, ST_SetSRID
from geoalchemy2.elements import WKTElement

from auth import (
    authenticate_admin,
    create_admin_token,
    create_user_token,
    get_current_user,
    hash_password,
    require_admin,
    verify_password,
)
from database import engine, Base, get_db
from models import User, WaterCooler, CoolerPhoto, Sponsor
from schemas import (
    WaterCoolerCreate,
    WaterCoolerRead,
    CoolerPhotoRead,
    SponsorCreate,
    SponsorRead,
    SponsorReadWithCount,
    UserAuthResponse,
)

# ─────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────

UPLOAD_DIR = "uploads/photos"
os.makedirs(UPLOAD_DIR, exist_ok=True)

_TRUST_AUTO_APPROVE_THRESHOLD = 500
_TRUST_APPROVE_REWARD = 50
_TRUST_REJECT_PENALTY = -100
_STATUS_UPDATE_REWARD = 10
_CONFIRM_REWARD = 5
_CONFIRM_COOLDOWN = 3600.0  # 1 hour

# In-memory cooldown tracker: (user_id, cooler_id) -> last confirm timestamp
_confirm_store: dict[tuple[str, str], float] = {}

# ─────────────────────────────────────────────
# RATE LIMITER (submission-only — 3 per minute per IP)
# ─────────────────────────────────────────────

_rate_limit_store: dict[str, list[float]] = defaultdict(list)
_RATE_LIMIT_MAX = 3
_RATE_LIMIT_WINDOW = 60.0


async def rate_limiter(request: Request) -> None:
    host = request.client.host if request.client else "unknown"
    now = time.time()
    window_start = now - _RATE_LIMIT_WINDOW
    _rate_limit_store[host] = [t for t in _rate_limit_store[host] if t > window_start]
    if len(_rate_limit_store[host]) >= _RATE_LIMIT_MAX:
        raise HTTPException(
            status_code=429,
            detail="Too many requests. Please wait before submitting again.",
        )
    _rate_limit_store[host].append(now)


# ─────────────────────────────────────────────
# LIFESPAN
# ─────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)
    yield


# ─────────────────────────────────────────────
# APP SETUP
# ─────────────────────────────────────────────

app = FastAPI(title="Sabil / CoolMan", version="2.0.0", lifespan=lifespan)

# CORS — allow Flutter web + Android emulator + local dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


# ─────────────────────────────────────────────
# INLINE REQUEST / RESPONSE SCHEMAS
# ─────────────────────────────────────────────

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


class StatusUpdate(BaseModel):
    status: str


class SponsorAssign(BaseModel):
    sponsor_id: str


# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────

def _cooler_by_id_stmt(cooler_id: str):
    return select(WaterCooler).where(cast(WaterCooler.id, String) == cooler_id)


async def _get_cooler_or_404(cooler_id: str, db: AsyncSession) -> WaterCooler:
    result = await db.execute(_cooler_by_id_stmt(cooler_id))
    cooler = result.scalars().first()
    if not cooler:
        raise HTTPException(status_code=404, detail="Cooler not found")
    return cooler


async def _get_user_or_404(user_id, db: AsyncSession) -> User:
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


# ─────────────────────────────────────────────
# AUTH ENDPOINTS
# ─────────────────────────────────────────────

@app.post("/auth/admin/login")
async def admin_login(payload: AdminLoginRequest):
    if not authenticate_admin(payload.username, payload.password):
        raise HTTPException(status_code=401, detail="Invalid credentials.")
    return {"access_token": create_admin_token(payload.username)}


@app.post("/auth/register", response_model=UserAuthResponse, status_code=201)
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


@app.post("/auth/login", response_model=UserAuthResponse)
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


@app.get("/auth/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": str(current_user.id),
        "username": current_user.username,
        "trust_score": current_user.trust_score,
    }


# ─────────────────────────────────────────────
# LEADERBOARD
# ─────────────────────────────────────────────

@app.get("/users/leaderboard")
async def get_leaderboard(db: AsyncSession = Depends(get_db)):
    stmt = select(User).order_by(User.trust_score.desc()).limit(10)
    result = await db.execute(stmt)
    users = result.scalars().all()
    return [
        {"rank": i + 1, "username": u.username, "trust_score": u.trust_score}
        for i, u in enumerate(users)
    ]


# ─────────────────────────────────────────────
# USER — MY COOLERS
# ─────────────────────────────────────────────

@app.get("/coolers/my", response_model=list[WaterCoolerRead])
async def get_my_coolers(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(WaterCooler)
        .where(
            or_(
                WaterCooler.user_id == current_user.id,
                WaterCooler.pending_status_user_id == current_user.id,
            )
        )
        .order_by(WaterCooler.last_verified_at.desc())
    )
    result = await db.execute(stmt)
    coolers = result.scalars().all()
    # Deduplicate: a cooler might match both conditions
    seen: set = set()
    unique = []
    for c in coolers:
        if c.id not in seen:
            seen.add(c.id)
            unique.append(c)
    return unique


# ─────────────────────────────────────────────
# PUBLIC COOLER ENDPOINTS
# ─────────────────────────────────────────────

@app.get("/coolers/nearby", response_model=list[WaterCoolerRead])
async def get_nearby_coolers(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(5.0, gt=0, le=50),
    db: AsyncSession = Depends(get_db),
):
    target = ST_SetSRID(ST_MakePoint(lng, lat), 4326)
    radius_m = radius_km * 1000

    stmt = select(WaterCooler).where(
        WaterCooler.is_approved == True,
        ST_DWithin(
            cast(WaterCooler.geom, Geography(geometry_type="POINT", srid=4326)),
            cast(target, Geography(geometry_type="POINT", srid=4326)),
            radius_m,
            use_spheroid=True,
        ),
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@app.get("/coolers/search", response_model=list[WaterCoolerRead])
async def search_coolers(
    q: str = Query(..., min_length=1, max_length=100),
    db: AsyncSession = Depends(get_db),
):
    term = f"%{q.strip()}%"
    stmt = (
        select(WaterCooler)
        .where(WaterCooler.is_approved == True, WaterCooler.name.ilike(term))
        .limit(30)
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@app.get("/coolers/{cooler_id}", response_model=WaterCoolerRead)
async def get_cooler(cooler_id: str, db: AsyncSession = Depends(get_db)):
    cooler = await _get_cooler_or_404(cooler_id, db)
    return cooler


# Public photo endpoint (approved photos only) — used by Flutter to show gallery
@app.get("/coolers/{cooler_id}/photos", response_model=list[CoolerPhotoRead])
async def get_cooler_photos_public(cooler_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(CoolerPhoto).where(
        cast(CoolerPhoto.cooler_id, String) == cooler_id,
        CoolerPhoto.is_approved == True,
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@app.patch("/coolers/{cooler_id}/status", response_model=WaterCoolerRead)
async def update_cooler_status(
    cooler_id: str,
    payload: StatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    valid_statuses = {"Working", "Empty", "Broken"}
    if payload.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")

    cooler = await _get_cooler_or_404(cooler_id, db)

    if current_user.trust_score >= _TRUST_AUTO_APPROVE_THRESHOLD:
        cooler.status = payload.status
        cooler.pending_status = None
        cooler.pending_status_user_id = None
        cooler.last_verified_at = datetime.now(timezone.utc)
        keys_to_delete = [k for k in _confirm_store if k[1] == cooler_id]
        for k in keys_to_delete:
            del _confirm_store[k]
    else:
        cooler.pending_status = payload.status
        cooler.pending_status_user_id = current_user.id

    current_user.trust_score = current_user.trust_score + _STATUS_UPDATE_REWARD

    await db.commit()
    await db.refresh(cooler)
    return cooler


@app.post("/coolers/{cooler_id}/confirm")
async def confirm_cooler_working(
    cooler_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    key = (str(current_user.id), cooler_id)
    now = time.time()
    last = _confirm_store.get(key, 0.0)

    if now - last < _CONFIRM_COOLDOWN:
        remaining_minutes = int((_CONFIRM_COOLDOWN - (now - last)) / 60)
        raise HTTPException(
            status_code=429,
            detail=f"You can confirm this cooler again in {remaining_minutes} minute{'s' if remaining_minutes != 1 else ''}.",
        )

    cooler = await _get_cooler_or_404(cooler_id, db)
    if not cooler.is_approved:
        raise HTTPException(status_code=400, detail="Cooler is not yet approved.")

    cooler.last_verified_at = datetime.now(timezone.utc)
    current_user.trust_score = current_user.trust_score + _CONFIRM_REWARD
    _confirm_store[key] = now

    await db.commit()
    await db.refresh(current_user)
    return {"message": "Confirmed", "trust_score": current_user.trust_score}


@app.post(
    "/coolers",
    response_model=WaterCoolerRead,
    status_code=201,
    dependencies=[Depends(rate_limiter)],
)
async def create_cooler(
    payload: WaterCoolerCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    target = ST_SetSRID(ST_MakePoint(payload.longitude, payload.latitude), 4326)

    dup_result = await db.execute(
        select(WaterCooler).where(
            ST_DWithin(
                cast(WaterCooler.geom, Geography(geometry_type="POINT", srid=4326)),
                cast(target, Geography(geometry_type="POINT", srid=4326)),
                15.0,
                use_spheroid=True,
            )
        )
    )
    if dup_result.scalars().first() is not None:
        raise HTTPException(
            status_code=400,
            detail="A water cooler has already been reported at this exact location.",
        )

    is_auto_approved = current_user.trust_score >= _TRUST_AUTO_APPROVE_THRESHOLD

    cooler = WaterCooler(
        name=payload.name,
        latitude=payload.latitude,
        longitude=payload.longitude,
        geom=WKTElement(f"POINT({payload.longitude} {payload.latitude})", srid=4326),
        status=payload.status,
        is_approved=is_auto_approved,
        has_cups=payload.has_cups,
        cups_type=payload.cups_type,
        user_id=current_user.id,
    )
    db.add(cooler)

    if is_auto_approved:
        current_user.trust_score = current_user.trust_score + _TRUST_APPROVE_REWARD

    await db.commit()
    await db.refresh(cooler)
    return cooler


@app.post(
    "/coolers/{cooler_id}/photos",
    response_model=CoolerPhotoRead,
    status_code=201,
    dependencies=[Depends(rate_limiter)],
)
async def upload_cooler_photo(
    cooler_id: str,
    file: UploadFile = File(...),
    photo_category: str = Form("Cooler"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from models import PhotoCategory as PC

    cooler = await _get_cooler_or_404(cooler_id, db)

    allowed = {"image/jpeg", "image/png", "image/webp"}
    if file.content_type not in allowed:
        raise HTTPException(status_code=400, detail="Invalid file type. Use JPEG, PNG, or WebP.")

    try:
        category = PC(photo_category)
    except ValueError:
        category = PC.Cooler

    ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
    filename = f"{cooler_id}_{datetime.now(timezone.utc).timestamp():.0f}.{ext}"
    dest = os.path.join(UPLOAD_DIR, filename)

    with open(dest, "wb") as buf:
        shutil.copyfileobj(file.file, buf)

    photo = CoolerPhoto(
        cooler_id=cooler.id,
        file_path=f"/uploads/photos/{filename}",
        photo_category=category,
        user_id=current_user.id,
    )
    db.add(photo)
    await db.commit()
    await db.refresh(photo)
    return photo


# ─────────────────────────────────────────────
# ADMIN — COOLER MANAGEMENT
# ─────────────────────────────────────────────

@app.get(
    "/admin/coolers/pending",
    response_model=list[WaterCoolerRead],
    dependencies=[Depends(require_admin)],
)
async def get_pending_coolers(db: AsyncSession = Depends(get_db)):
    stmt = select(WaterCooler).where(
        or_(
            and_(WaterCooler.is_approved == False, WaterCooler.is_rejected == False),
            WaterCooler.pending_status.is_not(None),
            WaterCooler.photos.any(CoolerPhoto.is_approved == False),
        )
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@app.get(
    "/admin/coolers/current",
    response_model=list[WaterCoolerRead],
    dependencies=[Depends(require_admin)],
)
async def get_current_coolers(db: AsyncSession = Depends(get_db)):
    stmt = select(WaterCooler).where(WaterCooler.is_approved == True)
    result = await db.execute(stmt)
    return result.scalars().all()


@app.patch("/admin/coolers/{cooler_id}/approve", dependencies=[Depends(require_admin)])
async def approve_cooler(cooler_id: str, db: AsyncSession = Depends(get_db)):
    cooler = await _get_cooler_or_404(cooler_id, db)

    if cooler.pending_status:
        cooler.status = cooler.pending_status
        cooler.pending_status = None
        cooler.pending_status_user_id = None
        keys_to_delete = [k for k in _confirm_store if k[1] == cooler_id]
        for k in keys_to_delete:
            del _confirm_store[k]

    if not cooler.is_approved and not cooler.is_rejected:
        cooler.is_approved = True
        for photo in cooler.photos:
            photo.is_approved = True
        if cooler.user_id:
            submitter = await _get_user_or_404(cooler.user_id, db)
            submitter.trust_score = submitter.trust_score + _TRUST_APPROVE_REWARD

    await db.commit()
    return {"message": "Approved"}


@app.patch("/admin/coolers/{cooler_id}/reject", dependencies=[Depends(require_admin)])
async def reject_cooler(cooler_id: str, db: AsyncSession = Depends(get_db)):
    cooler = await _get_cooler_or_404(cooler_id, db)

    if not cooler.is_approved and not cooler.is_rejected and cooler.user_id:
        submitter = await _get_user_or_404(cooler.user_id, db)
        submitter.trust_score = max(0, submitter.trust_score + _TRUST_REJECT_PENALTY)

    cooler.is_rejected = True
    cooler.is_approved = False
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    await db.commit()
    return {"message": "Rejected"}


@app.patch("/admin/coolers/{cooler_id}/reject-status", dependencies=[Depends(require_admin)])
async def reject_status_change(cooler_id: str, db: AsyncSession = Depends(get_db)):
    cooler = await _get_cooler_or_404(cooler_id, db)
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    await db.commit()
    return {"message": "Status change rejected"}


@app.patch("/admin/coolers/{cooler_id}/force-status", dependencies=[Depends(require_admin)])
async def admin_force_status(
    cooler_id: str,
    payload: StatusUpdate,
    db: AsyncSession = Depends(get_db),
):
    cooler = await _get_cooler_or_404(cooler_id, db)
    cooler.status = payload.status
    cooler.pending_status = None
    cooler.pending_status_user_id = None
    cooler.last_verified_at = datetime.now(timezone.utc)
    keys_to_delete = [k for k in _confirm_store if k[1] == cooler_id]
    for k in keys_to_delete:
        del _confirm_store[k]
    await db.commit()
    return {"message": "Status forcefully updated"}


@app.delete("/admin/coolers/{cooler_id}", dependencies=[Depends(require_admin)])
async def delete_cooler(cooler_id: str, db: AsyncSession = Depends(get_db)):
    cooler = await _get_cooler_or_404(cooler_id, db)
    await db.delete(cooler)
    await db.commit()
    return {"message": "Deleted"}


# ─────────────────────────────────────────────
# ADMIN — PHOTO MANAGEMENT
# ─────────────────────────────────────────────

@app.get(
    "/admin/coolers/{cooler_id}/photos",
    response_model=list[CoolerPhotoRead],
    dependencies=[Depends(require_admin)],
)
async def get_cooler_photos_admin(cooler_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(CoolerPhoto).where(cast(CoolerPhoto.cooler_id, String) == cooler_id)
    result = await db.execute(stmt)
    return result.scalars().all()


@app.post(
    "/admin/coolers/{cooler_id}/photos",
    response_model=CoolerPhotoRead,
    status_code=201,
    dependencies=[Depends(require_admin)],
)
async def admin_upload_cooler_photo(
    cooler_id: str,
    file: UploadFile = File(...),
    photo_category: str = Form("Cooler"),
    db: AsyncSession = Depends(get_db),
):
    from models import PhotoCategory as PC

    cooler = await _get_cooler_or_404(cooler_id, db)

    allowed = {"image/jpeg", "image/png", "image/webp"}
    if file.content_type not in allowed:
        raise HTTPException(status_code=400, detail="Invalid file type.")

    try:
        category = PC(photo_category)
    except ValueError:
        category = PC.Cooler

    ext = file.filename.rsplit(".", 1)[-1] if "." in file.filename else "jpg"
    filename = f"{cooler_id}_{datetime.now(timezone.utc).timestamp():.0f}_admin.{ext}"
    dest = os.path.join(UPLOAD_DIR, filename)

    with open(dest, "wb") as buf:
        shutil.copyfileobj(file.file, buf)

    photo = CoolerPhoto(
        cooler_id=cooler.id,
        file_path=f"/uploads/photos/{filename}",
        photo_category=category,
        is_approved=True,  # Admin-uploaded photos auto-approved
    )
    db.add(photo)
    await db.commit()
    await db.refresh(photo)
    return photo


@app.patch("/admin/photos/{photo_id}/approve", dependencies=[Depends(require_admin)])
async def approve_photo(photo_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(CoolerPhoto).where(cast(CoolerPhoto.id, String) == photo_id)
    result = await db.execute(stmt)
    photo = result.scalars().first()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    photo.is_approved = True
    await db.commit()
    return {"message": "Photo approved"}


@app.delete("/admin/photos/{photo_id}", dependencies=[Depends(require_admin)])
async def delete_photo(photo_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(CoolerPhoto).where(cast(CoolerPhoto.id, String) == photo_id)
    result = await db.execute(stmt)
    photo = result.scalars().first()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    full_path = photo.file_path.lstrip("/")
    if os.path.exists(full_path):
        os.remove(full_path)
    await db.delete(photo)
    await db.commit()
    return {"message": "Photo deleted"}


# ─────────────────────────────────────────────
# SPONSOR ENDPOINTS — PUBLIC
# ─────────────────────────────────────────────

@app.get("/sponsors", response_model=list[SponsorReadWithCount])
async def list_sponsors(db: AsyncSession = Depends(get_db)):
    count_subq = (
        select(
            WaterCooler.sponsor_id,
            func.count(WaterCooler.id).label("cooler_count"),
        )
        .where(WaterCooler.is_approved == True, WaterCooler.sponsor_id.is_not(None))
        .group_by(WaterCooler.sponsor_id)
        .subquery()
    )

    stmt = (
        select(Sponsor, func.coalesce(count_subq.c.cooler_count, 0).label("cooler_count"))
        .outerjoin(count_subq, Sponsor.id == count_subq.c.sponsor_id)
        .order_by(Sponsor.name)
    )
    rows = (await db.execute(stmt)).all()

    return [
        SponsorReadWithCount(
            id=sponsor.id,
            name=sponsor.name,
            sponsor_type=sponsor.sponsor_type,
            contact=sponsor.contact,
            verified=sponsor.verified,
            created_at=sponsor.created_at,
            cooler_count=count,
        )
        for sponsor, count in rows
    ]


@app.get("/sponsors/{sponsor_id}", response_model=SponsorReadWithCount)
async def get_sponsor(sponsor_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Sponsor).where(cast(Sponsor.id, String) == sponsor_id)
    )
    sponsor = result.scalars().first()
    if not sponsor:
        raise HTTPException(status_code=404, detail="Sponsor not found")

    count_result = await db.execute(
        select(func.count(WaterCooler.id)).where(
            WaterCooler.sponsor_id == sponsor.id,
            WaterCooler.is_approved == True,
        )
    )
    count = count_result.scalar() or 0
    return SponsorReadWithCount(
        id=sponsor.id,
        name=sponsor.name,
        sponsor_type=sponsor.sponsor_type,
        contact=sponsor.contact,
        verified=sponsor.verified,
        created_at=sponsor.created_at,
        cooler_count=count,
    )


# ─────────────────────────────────────────────
# SPONSOR ENDPOINTS — ADMIN
# ─────────────────────────────────────────────

@app.post(
    "/admin/sponsors",
    response_model=SponsorRead,
    status_code=201,
    dependencies=[Depends(require_admin)],
)
async def create_sponsor(payload: SponsorCreate, db: AsyncSession = Depends(get_db)):
    sponsor = Sponsor(
        name=payload.name,
        sponsor_type=payload.sponsor_type,
        contact=payload.contact,
    )
    db.add(sponsor)
    await db.commit()
    await db.refresh(sponsor)
    return sponsor


@app.patch(
    "/admin/sponsors/{sponsor_id}/verify",
    response_model=SponsorRead,
    dependencies=[Depends(require_admin)],
)
async def verify_sponsor(sponsor_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Sponsor).where(cast(Sponsor.id, String) == sponsor_id))
    sponsor = result.scalars().first()
    if not sponsor:
        raise HTTPException(status_code=404, detail="Sponsor not found")
    sponsor.verified = True
    await db.commit()
    await db.refresh(sponsor)
    return sponsor


@app.delete("/admin/sponsors/{sponsor_id}", dependencies=[Depends(require_admin)])
async def delete_sponsor(sponsor_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Sponsor).where(cast(Sponsor.id, String) == sponsor_id))
    sponsor = result.scalars().first()
    if not sponsor:
        raise HTTPException(status_code=404, detail="Sponsor not found")
    cooler_result = await db.execute(
        select(WaterCooler).where(WaterCooler.sponsor_id == sponsor.id)
    )
    for cooler in cooler_result.scalars().all():
        cooler.sponsor_id = None
    await db.delete(sponsor)
    await db.commit()
    return {"message": "Sponsor deleted"}


@app.patch(
    "/admin/coolers/{cooler_id}/assign-sponsor",
    response_model=WaterCoolerRead,
    dependencies=[Depends(require_admin)],
)
async def assign_sponsor(
    cooler_id: str,
    payload: SponsorAssign,
    db: AsyncSession = Depends(get_db),
):
    cooler = await _get_cooler_or_404(cooler_id, db)

    sponsor_result = await db.execute(
        select(Sponsor).where(cast(Sponsor.id, String) == payload.sponsor_id)
    )
    sponsor = sponsor_result.scalars().first()
    if not sponsor:
        raise HTTPException(status_code=404, detail="Sponsor not found")

    cooler.sponsor_id = sponsor.id
    await db.commit()
    await db.refresh(cooler)
    return cooler


@app.delete(
    "/admin/coolers/{cooler_id}/assign-sponsor",
    response_model=WaterCoolerRead,
    dependencies=[Depends(require_admin)],
)
async def remove_sponsor(cooler_id: str, db: AsyncSession = Depends(get_db)):
    cooler = await _get_cooler_or_404(cooler_id, db)
    cooler.sponsor_id = None
    await db.commit()
    await db.refresh(cooler)
    return cooler
