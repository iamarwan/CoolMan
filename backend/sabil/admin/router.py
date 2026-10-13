# admin/router.py
#
# Puts the admin API together.
#
#   login_router  POST /auth/admin/login   (open to everyone; it hands out the admin token)
#   router        everything under /admin  (the dependency below makes EVERY route in it
#                                           require a valid admin token)
#
# The actual routes are in admin/coolers.py, admin/photos.py and admin/sponsors.py.

from fastapi import APIRouter, Depends, HTTPException

from sabil.admin import coolers, photos, sponsors
from sabil.admin.schemas import AdminLoginRequest
from sabil.core.dependencies import require_admin
from sabil.core.security import authenticate_admin, create_admin_token

login_router = APIRouter(tags=["admin"])


@login_router.post("/auth/admin/login")
async def admin_login(payload: AdminLoginRequest):
    if not authenticate_admin(payload.username, payload.password):
        raise HTTPException(status_code=401, detail="Invalid credentials.")
    return {"access_token": create_admin_token(payload.username)}


router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])
router.include_router(coolers.router)
router.include_router(photos.router)
router.include_router(sponsors.router)
