# main.py
#
# The entry point. It builds the FastAPI app and plugs in the feature routers.
# All real logic lives in the feature folders:
#
#   users/     register, login, leaderboard, trust rules
#   coolers/   find coolers, add one, report status, photos
#   sponsors/  public sponsor pages
#   admin/     admin login, review queue, moderation, sponsor management
#   core/      settings, database, security, rate limiting (shared by all)
#   media/     saving/deleting uploaded image files
#
# Run it from the backend/ folder:   uvicorn sabil.main:app --reload

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from sabil.admin.router import login_router as admin_login_router
from sabil.admin.router import router as admin_router
from sabil.coolers.router import router as coolers_router
from sabil.core.config import check_settings
from sabil.core.database import init_db
from sabil.media.router import router as media_router
from sabil.media.storage import ensure_upload_dirs
from sabil.sponsors.router import router as sponsors_router
from sabil.users.router import router as users_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    check_settings()  # production: refuse to start with default secrets
    await init_db()  # runs once at startup: PostGIS extension + create missing tables
    yield


app = FastAPI(title="Sabil / CoolMan", version="2.0.0", lifespan=lifespan)

# CORS: allow Flutter web + Android emulator + local dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Uploaded photos are served by media_router at /uploads/photos/<file>, with an
# approval check (not as open static files).
ensure_upload_dirs()

app.include_router(users_router)
app.include_router(coolers_router)
app.include_router(sponsors_router)
app.include_router(admin_login_router)
app.include_router(admin_router)
app.include_router(media_router)
