"""Public web pages the app stores require: privacy policy and a way to
delete an account without installing the app."""

from pathlib import Path

from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.errors import ApiError
from app.services import accounts

router = APIRouter(include_in_schema=False)
templates = Jinja2Templates(directory=Path(__file__).parent / "templates")


@router.get("/privacy", response_class=HTMLResponse)
async def privacy(request: Request):
    return templates.TemplateResponse(request, "privacy.html", {})


@router.get("/account/delete", response_class=HTMLResponse)
async def delete_account_page(request: Request):
    return templates.TemplateResponse(request, "delete_account.html", {"error": None, "done": False})


@router.post("/account/delete", response_class=HTMLResponse)
async def delete_account_submit(
    request: Request,
    username: str = Form(..., max_length=64),
    password: str = Form(..., max_length=128),
    db: AsyncSession = Depends(get_db),
):
    try:
        user = await accounts.authenticate(db, request, username, password)
        await accounts.delete_account(db, request, user, password)
    except ApiError as e:
        message = (
            "Wrong username or password."
            if e.code == "invalid_credentials"
            else e.detail
        )
        return templates.TemplateResponse(
            request, "delete_account.html", {"error": message, "done": False}, status_code=e.status_code
        )
    return templates.TemplateResponse(request, "delete_account.html", {"error": None, "done": True})
