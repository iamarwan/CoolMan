"""Web admin panel (server-rendered HTML).  Open http://<server>:8000/admin"""

import asyncio
import math
import uuid
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlencode

from fastapi import APIRouter, Depends, File, Form, Query, Request, UploadFile
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import get_db
from app.errors import ApiError
from app.models import (
    CoolerPhoto,
    CoolerStatus,
    PhotoCategory,
    Sponsor,
    SponsorType,
    User,
    WaterCooler,
)
from app.schemas import clean_text
from app.security import authenticate_admin, create_admin_token
from app.services import moderation
from app.services.coolers import get_cooler

from .auth import COOKIE, admin_action, admin_page, csrf_for, safe_next

router = APIRouter(prefix="/admin", include_in_schema=False)
templates = Jinja2Templates(directory=Path(__file__).parent / "templates")

PAGE_SIZE = 50


def _ago(value: datetime | None) -> str:
    if value is None:
        return "-"
    secs = (datetime.now(timezone.utc) - value).total_seconds()
    if secs < 60:
        return "just now"
    if secs < 3600:
        return f"{int(secs // 60)} min ago"
    if secs < 86400:
        return f"{int(secs // 3600)} h ago"
    return f"{int(secs // 86400)} d ago"


templates.env.filters["ago"] = _ago


def _back(next_url: str | None, msg: str, error: bool = False) -> RedirectResponse:
    url = safe_next(next_url)
    sep = "&" if "?" in url else "?"
    query = urlencode({"msg": msg, **({"error": "1"} if error else {})})
    return RedirectResponse(f"{url}{sep}{query}", status_code=303)


async def _run(action, next_url: str | None, ok_msg: str) -> RedirectResponse:
    try:
        await action
    except ApiError as e:
        return _back(next_url, e.detail, error=True)
    return _back(next_url, ok_msg)


async def _usernames(db: AsyncSession, ids) -> dict[uuid.UUID, tuple[str, int]]:
    ids = {i for i in ids if i}
    if not ids:
        return {}
    rows = await db.execute(select(User.id, User.username, User.trust_score).where(User.id.in_(ids)))
    return {r.id: (r.username, r.trust_score) for r in rows}


async def _queue_counts(db: AsyncSession) -> dict[str, int]:
    new = await db.scalar(
        select(func.count()).where(WaterCooler.is_approved.is_(False), WaterCooler.is_rejected.is_(False))
    )
    status = await db.scalar(
        select(func.count()).where(WaterCooler.is_approved, WaterCooler.pending_status.is_not(None))
    )
    photos = await db.scalar(
        select(func.count(CoolerPhoto.id))
        .join(WaterCooler, CoolerPhoto.cooler_id == WaterCooler.id)
        .where(CoolerPhoto.is_approved.is_(False), WaterCooler.is_approved)
    )
    return {"new": new or 0, "status": status or 0, "photos": photos or 0}


def _render(request: Request, name: str, csrf: str, counts: dict, **ctx) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        name,
        {
            "csrf": csrf,
            "counts": counts,
            "msg": request.query_params.get("msg"),
            "is_error": request.query_params.get("error") == "1",
            "here": request.url.path + (f"?{request.url.query}" if request.url.query else ""),
            "statuses": list(CoolerStatus),
            **ctx,
        },
    )


# ── Login ────────────────────────────────────────────────────────────────────

@router.get("", response_class=HTMLResponse)
async def root():
    return RedirectResponse("/admin/queue", status_code=303)


@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request, next: str | None = None):
    return templates.TemplateResponse(request, "login.html", {"next": safe_next(next), "error": None})


@router.post("/login", response_class=HTMLResponse)
async def login(
    request: Request,
    username: str = Form(..., max_length=128),
    password: str = Form(..., max_length=256),
    next: str | None = Form(None),
):
    if not authenticate_admin(username, password):
        await asyncio.sleep(1)  # slow down password guessing
        return templates.TemplateResponse(
            request,
            "login.html",
            {"next": safe_next(next), "error": "Wrong username or password."},
            status_code=401,
        )
    settings = get_settings()
    response = RedirectResponse(safe_next(next), status_code=303)
    response.set_cookie(
        COOKIE,
        create_admin_token(username),
        max_age=settings.admin_token_minutes * 60,
        httponly=True,
        secure=settings.is_production,
        samesite="strict",
        path="/admin",
    )
    return response


@router.post("/logout", dependencies=[Depends(admin_action)])
async def logout():
    response = RedirectResponse("/admin/login", status_code=303)
    response.delete_cookie(COOKIE, path="/admin")
    return response


# ── Review queue ─────────────────────────────────────────────────────────────

@router.get("/queue", response_class=HTMLResponse)
async def queue(request: Request, csrf: str = Depends(admin_page), db: AsyncSession = Depends(get_db)):
    new = (
        await db.execute(
            select(WaterCooler)
            .where(WaterCooler.is_approved.is_(False), WaterCooler.is_rejected.is_(False))
            .order_by(WaterCooler.created_at)
        )
    ).scalars().all()
    status_changes = (
        await db.execute(
            select(WaterCooler)
            .where(WaterCooler.is_approved, WaterCooler.pending_status.is_not(None))
            .order_by(WaterCooler.last_verified_at)
        )
    ).scalars().all()
    photos = (
        await db.execute(
            select(CoolerPhoto, WaterCooler.name)
            .join(WaterCooler, CoolerPhoto.cooler_id == WaterCooler.id)
            .where(CoolerPhoto.is_approved.is_(False), WaterCooler.is_approved)
            .order_by(CoolerPhoto.uploaded_at)
        )
    ).all()
    users = await _usernames(
        db,
        [c.user_id for c in new]
        + [c.pending_status_user_id for c in status_changes]
        + [p.user_id for p, _ in photos],
    )
    return _render(
        request, "queue.html", csrf, await _queue_counts(db),
        new=new, status_changes=status_changes, photos=photos, users=users,
    )


# ── Coolers ──────────────────────────────────────────────────────────────────

@router.get("/coolers", response_class=HTMLResponse)
async def coolers(
    request: Request,
    q: str = Query("", max_length=100),
    status: str = Query(""),
    state: str = Query("live"),
    page: int = Query(1, ge=1),
    csrf: str = Depends(admin_page),
    db: AsyncSession = Depends(get_db),
):
    conds = []
    if state == "live":
        conds.append(WaterCooler.is_approved)
    elif state == "rejected":
        conds.append(WaterCooler.is_rejected)
    elif state == "pending":
        conds.append(and_(WaterCooler.is_approved.is_(False), WaterCooler.is_rejected.is_(False)))
    if status in {s.value for s in CoolerStatus}:
        conds.append(WaterCooler.status == CoolerStatus(status))
    if q.strip():
        escaped = q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        conds.append(WaterCooler.name.ilike(f"%{escaped}%", escape="\\"))

    total = await db.scalar(select(func.count(WaterCooler.id)).where(*conds)) or 0
    rows = (
        await db.execute(
            select(WaterCooler)
            .where(*conds)
            .order_by(WaterCooler.created_at.desc())
            .offset((page - 1) * PAGE_SIZE)
            .limit(PAGE_SIZE)
        )
    ).scalars().all()
    return _render(
        request, "coolers.html", csrf, await _queue_counts(db),
        coolers=rows, total=total, page=page, pages=max(1, math.ceil(total / PAGE_SIZE)),
        q=q, status=status, state=state,
    )


@router.get("/coolers/{cooler_id}", response_class=HTMLResponse)
async def cooler_detail(
    request: Request,
    cooler_id: uuid.UUID,
    csrf: str = Depends(admin_page),
    db: AsyncSession = Depends(get_db),
):
    try:
        cooler = await get_cooler(db, cooler_id)
    except ApiError:
        return _back("/admin/coolers", "Cooler not found.", error=True)
    sponsors = (await db.execute(select(Sponsor).order_by(Sponsor.name))).scalars().all()
    users = await _usernames(db, [cooler.user_id, cooler.pending_status_user_id])
    return _render(
        request, "cooler.html", csrf, await _queue_counts(db),
        cooler=cooler, sponsors=sponsors, users=users, categories=list(PhotoCategory),
    )


@router.post("/coolers/{cooler_id}/approve", dependencies=[Depends(admin_action)])
async def approve(cooler_id: uuid.UUID, next: str | None = Form(None), db: AsyncSession = Depends(get_db)):
    return await _run(moderation.approve_cooler(db, cooler_id), next, "Approved.")


@router.post("/coolers/{cooler_id}/reject", dependencies=[Depends(admin_action)])
async def reject(cooler_id: uuid.UUID, next: str | None = Form(None), db: AsyncSession = Depends(get_db)):
    return await _run(moderation.reject_cooler(db, cooler_id), next, "Rejected.")


@router.post("/coolers/{cooler_id}/restore", dependencies=[Depends(admin_action)])
async def restore(cooler_id: uuid.UUID, next: str | None = Form(None), db: AsyncSession = Depends(get_db)):
    return await _run(moderation.restore_cooler(db, cooler_id), next, "Restored and live again.")


@router.post("/coolers/{cooler_id}/reject-status", dependencies=[Depends(admin_action)])
async def reject_status(cooler_id: uuid.UUID, next: str | None = Form(None), db: AsyncSession = Depends(get_db)):
    return await _run(moderation.reject_status_change(db, cooler_id), next, "Status change rejected.")


@router.post("/coolers/{cooler_id}/status", dependencies=[Depends(admin_action)])
async def set_status(
    cooler_id: uuid.UUID,
    status: CoolerStatus = Form(...),
    next: str | None = Form(None),
    db: AsyncSession = Depends(get_db),
):
    return await _run(moderation.force_status(db, cooler_id, status), next, f"Status set to {status.value}.")


@router.post("/coolers/{cooler_id}/sponsor", dependencies=[Depends(admin_action)])
async def set_sponsor(
    cooler_id: uuid.UUID,
    sponsor_id: str = Form(""),
    next: str | None = Form(None),
    db: AsyncSession = Depends(get_db),
):
    try:
        sid = uuid.UUID(sponsor_id) if sponsor_id else None
    except ValueError:
        return _back(next, "Unknown sponsor.", error=True)
    return await _run(
        moderation.set_sponsor(db, cooler_id, sid), next, "Sponsor updated." if sid else "Sponsor removed."
    )


@router.post("/coolers/{cooler_id}/delete", dependencies=[Depends(admin_action)])
async def delete(cooler_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    return await _run(moderation.delete_cooler(db, cooler_id), "/admin/coolers", "Cooler deleted.")


@router.post("/coolers/{cooler_id}/photos", dependencies=[Depends(admin_action)])
async def upload_photo(
    cooler_id: uuid.UUID,
    file: UploadFile = File(...),
    photo_category: PhotoCategory = Form(PhotoCategory.Cooler),
    next: str | None = Form(None),
    db: AsyncSession = Depends(get_db),
):
    return await _run(moderation.upload_photo(db, cooler_id, file, photo_category), next, "Photo added.")


# ── Photos ───────────────────────────────────────────────────────────────────

@router.post("/photos/{photo_id}/approve", dependencies=[Depends(admin_action)])
async def approve_photo(photo_id: uuid.UUID, next: str | None = Form(None), db: AsyncSession = Depends(get_db)):
    return await _run(moderation.approve_photo(db, photo_id), next, "Photo approved.")


@router.post("/photos/{photo_id}/delete", dependencies=[Depends(admin_action)])
async def delete_photo(photo_id: uuid.UUID, next: str | None = Form(None), db: AsyncSession = Depends(get_db)):
    return await _run(moderation.delete_photo(db, photo_id), next, "Photo deleted.")


# ── Sponsors ─────────────────────────────────────────────────────────────────

@router.get("/sponsors", response_class=HTMLResponse)
async def sponsors(request: Request, csrf: str = Depends(admin_page), db: AsyncSession = Depends(get_db)):
    counts_q = (
        select(WaterCooler.sponsor_id, func.count(WaterCooler.id).label("n"))
        .where(WaterCooler.sponsor_id.is_not(None))
        .group_by(WaterCooler.sponsor_id)
        .subquery()
    )
    rows = (
        await db.execute(
            select(Sponsor, func.coalesce(counts_q.c.n, 0))
            .outerjoin(counts_q, Sponsor.id == counts_q.c.sponsor_id)
            .order_by(Sponsor.name)
        )
    ).all()
    return _render(
        request, "sponsors.html", csrf, await _queue_counts(db),
        sponsors=rows, types=list(SponsorType),
    )


@router.post("/sponsors", dependencies=[Depends(admin_action)])
async def create_sponsor(
    name: str = Form(..., min_length=1, max_length=255),
    sponsor_type: SponsorType = Form(...),
    contact: str = Form("", max_length=255),
    db: AsyncSession = Depends(get_db),
):
    try:
        clean_name, clean_contact = clean_text(name), clean_text(contact)
    except ValueError as e:
        return _back("/admin/sponsors", str(e), error=True)
    await moderation.create_sponsor(db, clean_name, sponsor_type, clean_contact)
    return _back("/admin/sponsors", f"Sponsor '{clean_name}' added.")


@router.post("/sponsors/{sponsor_id}/verify", dependencies=[Depends(admin_action)])
async def verify_sponsor(
    sponsor_id: uuid.UUID, verified: bool = Form(True), db: AsyncSession = Depends(get_db)
):
    return await _run(
        moderation.verify_sponsor(db, sponsor_id, verified),
        "/admin/sponsors",
        "Sponsor verified." if verified else "Verification removed.",
    )


@router.post("/sponsors/{sponsor_id}/delete", dependencies=[Depends(admin_action)])
async def delete_sponsor(sponsor_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    return await _run(moderation.delete_sponsor(db, sponsor_id), "/admin/sponsors", "Sponsor deleted.")
