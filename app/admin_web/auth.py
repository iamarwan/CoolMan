"""Admin web session: the admin JWT lives in an HttpOnly, SameSite=Strict
cookie scoped to /admin. Every POST form also carries a CSRF token derived
from that session."""

import hashlib
import hmac
from urllib.parse import quote

from fastapi import Form, Request

from app.config import get_settings
from app.errors import ApiError
from app.security import decode_token

COOKIE = "sabil_admin"
_AUD_ADMIN = "sabil-admin"


class LoginRequired(Exception):
    def __init__(self, next_url: str = "/admin"):
        self.next_url = next_url


def csrf_for(token: str) -> str:
    key = get_settings().jwt_secret.encode()
    return hmac.new(key, b"csrf:" + token.encode(), hashlib.sha256).hexdigest()[:40]


def safe_next(url: str | None) -> str:
    """Only allow redirects inside the admin panel."""
    if url and url.startswith("/admin") and not url.startswith("//"):
        return url
    return "/admin/queue"


def login_url(request: Request) -> str:
    target = request.url.path + (f"?{request.url.query}" if request.url.query else "")
    return f"/admin/login?next={quote(target)}"


def _session_token(request: Request) -> str:
    token = request.cookies.get(COOKIE)
    if not token:
        raise LoginRequired(login_url(request))
    try:
        decode_token(token, _AUD_ADMIN, "admin")
    except ApiError:
        raise LoginRequired(login_url(request))
    return token


def admin_page(request: Request) -> str:
    """Dependency for GET pages. Returns the CSRF token for the page's forms."""
    return csrf_for(_session_token(request))


def admin_action(request: Request, csrf: str = Form("")) -> None:
    """Dependency for POST actions: valid session + matching CSRF token."""
    token = _session_token(request)
    if not hmac.compare_digest(csrf, csrf_for(token)):
        raise ApiError(403, "csrf_failed", "Form expired. Reload the page and try again.")
