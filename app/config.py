"""Application settings, read from environment variables (or a .env file).

Every setting uses the SABIL_ prefix, e.g. SABIL_DATABASE_URL. See .env.example
(development) and deploy/.env.production.example (production).
"""

import logging
import secrets
from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict

log = logging.getLogger("sabil")

_DEV_JWT_SECRET = "dev-only-insecure-secret-change-me"
_DEV_ADMIN_PASSWORD = "admin123"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="SABIL_", env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    env: Literal["development", "production"] = "development"

    database_url: str = (
        "postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_db?ssl=disable"
    )
    db_pool_size: int = 10
    db_max_overflow: int = 20

    jwt_secret: str = _DEV_JWT_SECRET
    user_token_minutes: int = 60 * 24 * 30  # 30 days
    admin_token_minutes: int = 60 * 8  # 8 hours

    # PBKDF2-HMAC-SHA256 work factor (OWASP 2023 minimum: 600,000).
    password_iterations: int = 600_000

    admin_username: str = "admin"
    admin_password: str = _DEV_ADMIN_PASSWORD

    upload_dir: str = "uploads"
    max_upload_mb: int = 8

    # Comma-separated browser origins allowed to call the API from other sites.
    # The mobile app and the built-in /admin panel do not need this; leave it
    # empty in production unless you add a separate web front-end.
    cors_origins: str = "*"

    # The "be there" rule: confirm, report, add photos and add coolers only
    # within this distance of the spot. 0 switches the rule off (development).
    max_action_distance_m: int = 50
    # Refuse a position whose reported GPS error is larger than this.
    max_gps_accuracy_m: int = 40

    # Abuse limits (per 15 minutes unless stated).
    login_failures_per_user_ip: int = 10
    login_failures_per_user: int = 30
    login_failures_per_ip: int = 60
    admin_login_failures_per_ip: int = 5
    registrations_per_ip_per_hour: int = 20

    @property
    def uses_default_admin_password(self) -> bool:
        return self.admin_password == _DEV_ADMIN_PASSWORD

    @property
    def is_production(self) -> bool:
        return self.env == "production"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    def validate_for_runtime(self) -> None:
        """Refuse to run in production with development defaults."""
        problems = []
        if self.jwt_secret == _DEV_JWT_SECRET or len(self.jwt_secret) < 32:
            problems.append("SABIL_JWT_SECRET must be set to a random string of 32+ characters")
        if self.admin_password == _DEV_ADMIN_PASSWORD or len(self.admin_password) < 12:
            problems.append("SABIL_ADMIN_PASSWORD must be set (12+ characters)")
        if "*" in self.cors_origin_list:
            problems.append("SABIL_CORS_ORIGINS must not be '*' (leave it empty or list origins)")
        if problems:
            if self.is_production:
                raise RuntimeError("Insecure production settings:\n- " + "\n- ".join(problems))
            for p in problems:
                log.warning("DEV MODE: %s (ok for local development only)", p)


def _dev_secret() -> str:
    """A random signing secret kept in a local file, so development tokens
    cannot be forged with a value published in this repository."""
    path = Path(".dev-secret")
    try:
        if path.exists():
            value = path.read_text().strip()
            if len(value) >= 32:
                return value
        value = secrets.token_urlsafe(48)
        path.write_text(value)
        return value
    except OSError:
        return secrets.token_urlsafe(48)  # read-only disk: per-process secret


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    if not settings.is_production and settings.jwt_secret == _DEV_JWT_SECRET:
        settings.jwt_secret = _dev_secret()
    return settings
