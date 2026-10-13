# core/config.py
#
# Every setting and tunable number lives in THIS file, so you never have to
# hunt through the code to find "where is the timeout / secret / limit set?".
#
# Values that differ between your laptop and a real server are read from
# environment variables (os.getenv). The second argument is the default that is
# used when the variable is not set.

import os

# ─────────────────────────────────────────────
# DATABASE
# ─────────────────────────────────────────────

DATABASE_URL = os.getenv(
    "SABIL_DATABASE_URL",
    "postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_db?ssl=disable",
)

# ─────────────────────────────────────────────
# LOGIN TOKENS (JWT)
# ─────────────────────────────────────────────

# WARNING: the defaults below are for local development only.
# Set SABIL_JWT_SECRET / SABIL_ADMIN_PASSWORD in any real deployment.
JWT_SECRET = os.getenv("SABIL_JWT_SECRET", "change-me-in-production")
JWT_ISSUER = "sabil-api"

JWT_AUDIENCE_ADMIN = "sabil-admin"
JWT_EXPIRES_ADMIN_MINUTES = int(os.getenv("SABIL_ADMIN_TOKEN_MIN", "480"))        # 8 hours

JWT_AUDIENCE_USER = "sabil-user"
JWT_EXPIRES_USER_MINUTES = int(os.getenv("SABIL_USER_TOKEN_MIN", "10080"))        # 7 days

ADMIN_USERNAME = os.getenv("SABIL_ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("SABIL_ADMIN_PASSWORD", "admin123")

PASSWORD_HASH_ITERATIONS = 260_000

# ─────────────────────────────────────────────
# FILE UPLOADS
# ─────────────────────────────────────────────

# Folders are relative to the directory you start the server from (backend/).
UPLOAD_ROOT = "uploads"                       # served publicly at /uploads
PHOTO_DIR = os.path.join(UPLOAD_ROOT, "photos")
PHOTO_URL_PREFIX = "/uploads/photos"          # what gets stored in the database

# Browser/phone-reported content type -> file extension we save it with.
ALLOWED_IMAGE_TYPES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
}

# ─────────────────────────────────────────────
# ABUSE PROTECTION
# ─────────────────────────────────────────────

# Submission rate limit: at most N create/upload requests per IP per window.
RATE_LIMIT_MAX_REQUESTS = 3
RATE_LIMIT_WINDOW_SECONDS = 60.0

# A user may press "Still working" on the same cooler once per this many seconds.
CONFIRM_COOLDOWN_SECONDS = 3600.0             # 1 hour
