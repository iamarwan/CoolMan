# users/phone.py
#
# Sign in (or sign up) with an Egyptian mobile number and a texted code.
#
#   POST /auth/phone/request   send a 6-digit code to the number
#   POST /auth/phone/verify    enter the code: logs in, or creates the account
#                              (a new number must also send a username)
#   POST /auth/phone/attach    a logged-in user links a number to their account,
#                              so they can sign in by phone later (also account recovery)
#
# Safety rules (all numbers are in core/config.py):
#   - only a keyed hash of the code is stored, never the code
#   - a code works for 5 minutes, and is burned after 5 wrong tries
#   - one code per number per minute, 5 per hour (SMS costs money)
#   - the request route answers the same whether or not the number has an account
#   - per-IP login limit applies too

import logging
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from sabil.core.config import (
    PHONE_CODE_LENGTH,
    PHONE_CODE_MAX_WRONG_TRIES,
    PHONE_CODE_RESEND_SECONDS,
    PHONE_CODE_TTL_SECONDS,
    PHONE_CODES_PER_HOUR,
)
from sabil.core.database import get_db
from sabil.core.dependencies import get_current_user
from sabil.core.phone import normalize_digits, normalize_egyptian_mobile
from sabil.core.rate_limit import auth_rate_limiter
from sabil.core.security import (
    generate_one_time_code,
    hash_one_time_code,
    hash_password,
)
from sabil.core.sms import get_sms_sender, phone_login_enabled
from sabil.users.models import PhoneCode, User
from sabil.users.schemas import PhoneAuthResponse, PhoneRequest, PhoneVerify
from sabil.users.tokens import auth_response

router = APIRouter(tags=["phone sign-in"])
log = logging.getLogger("sabil")


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _require_enabled() -> None:
    if not phone_login_enabled():
        raise HTTPException(status_code=503, detail="Phone sign-in is not available right now.")


def _clean_phone(raw: str) -> str:
    phone = normalize_egyptian_mobile(raw)
    if phone is None:
        raise HTTPException(
            status_code=422,
            detail="Enter an Egyptian mobile number, for example 01012345678.",
        )
    return phone


async def _check_code(db: AsyncSession, phone: str, raw_code: str) -> PhoneCode:
    """Return the matching, still-valid code row, or answer 400."""
    code = normalize_digits(raw_code)
    result = await db.execute(
        select(PhoneCode)
        .where(PhoneCode.phone == phone, PhoneCode.used.is_(False), PhoneCode.expires_at > _now())
        .order_by(PhoneCode.created_at.desc())
        .limit(1)
    )
    row = result.scalars().first()
    if row is None:
        raise HTTPException(status_code=400, detail="This code has expired. Request a new one.")
    if not secrets.compare_digest(row.code_hash, hash_one_time_code(phone, code)):
        row.wrong_tries += 1
        if row.wrong_tries >= PHONE_CODE_MAX_WRONG_TRIES:
            row.used = True
        await db.commit()  # keep the count even though we answer with an error
        if row.used:
            raise HTTPException(status_code=400, detail="Too many wrong tries. Request a new code.")
        raise HTTPException(status_code=400, detail="Wrong code.")
    return row


@router.post("/auth/phone/request", status_code=202, dependencies=[Depends(auth_rate_limiter)])
async def request_code(payload: PhoneRequest, db: AsyncSession = Depends(get_db)):
    _require_enabled()
    phone = _clean_phone(payload.phone)
    now = _now()

    recent = (
        await db.execute(
            select(PhoneCode)
            .where(PhoneCode.phone == phone, PhoneCode.created_at > now - timedelta(hours=1))
            .order_by(PhoneCode.created_at.desc())
        )
    ).scalars().all()
    if recent:
        wait = PHONE_CODE_RESEND_SECONDS - (now - recent[0].created_at).total_seconds()
        if wait > 0:
            raise HTTPException(
                status_code=429,
                detail=f"Wait {int(wait) + 1} seconds before asking for a new code.",
            )
    if len(recent) >= PHONE_CODES_PER_HOUR:
        raise HTTPException(
            status_code=429,
            detail="Too many codes requested for this number. Try again in an hour.",
        )

    # Only the newest code works.
    await db.execute(
        update(PhoneCode).where(PhoneCode.phone == phone, PhoneCode.used.is_(False)).values(used=True)
    )
    code = generate_one_time_code(PHONE_CODE_LENGTH)
    row = PhoneCode(
        phone=phone,
        code_hash=hash_one_time_code(phone, code),
        expires_at=now + timedelta(seconds=PHONE_CODE_TTL_SECONDS),
    )
    db.add(row)
    await db.commit()

    minutes = PHONE_CODE_TTL_SECONDS // 60
    text = f"Sabil code: {code}. Valid for {minutes} minutes. Do not share it."
    try:
        await get_sms_sender().send(phone, text)
    except Exception:
        log.exception("Could not send the SMS code")
        row.used = True
        await db.commit()
        raise HTTPException(status_code=502, detail="Could not send the code. Try again later.")
    return {"expires_in": PHONE_CODE_TTL_SECONDS, "resend_in": PHONE_CODE_RESEND_SECONDS}


@router.post(
    "/auth/phone/verify",
    response_model=PhoneAuthResponse,
    dependencies=[Depends(auth_rate_limiter)],
)
async def verify_code(payload: PhoneVerify, db: AsyncSession = Depends(get_db)):
    _require_enabled()
    phone = _clean_phone(payload.phone)
    row = await _check_code(db, phone, payload.code)

    user = (await db.execute(select(User).where(User.phone == phone))).scalars().first()
    is_new = user is None
    if is_new:
        if not payload.username:
            # The code stays valid so the app can ask for a username and resend.
            raise HTTPException(status_code=400, detail="Choose a username to finish creating your account.")
        taken = await db.execute(select(User).where(User.username == payload.username))
        if taken.scalars().first():
            raise HTTPException(status_code=409, detail="Username already taken.")
        user = User(
            username=payload.username,
            # Phone accounts have no password; this random hash can never be guessed.
            hashed_password=hash_password(secrets.token_urlsafe(32)),
            phone=phone,
            trust_score=0,
        )
        db.add(user)

    row.used = True
    await db.commit()
    await db.refresh(user)
    return {**auth_response(user), "is_new": is_new}


@router.post("/auth/phone/attach", dependencies=[Depends(auth_rate_limiter)])
async def attach_phone(
    payload: PhoneVerify,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Link a verified number to the logged-in account."""
    _require_enabled()
    phone = _clean_phone(payload.phone)
    row = await _check_code(db, phone, payload.code)

    owner = (await db.execute(select(User).where(User.phone == phone))).scalars().first()
    if owner is not None and owner.id != current_user.id:
        raise HTTPException(status_code=409, detail="This number is already used by another account.")

    current_user.phone = phone
    row.used = True
    await db.commit()
    return {"phone": phone}
