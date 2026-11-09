"""Application settings, read from environment variables (or a .env file).

Every setting uses the SABIL_ prefix, e.g. SABIL_DATABASE_URL. See .env.example
(development) and deploy/.env.production.example (production).
"""

import logging
from functools import lru_cache
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

    admin_username: str = "admin"
    admin_password: str = _DEV_ADMIN_PASSWORD

    upload_dir: str = "uploads"
    max_upload_mb: int = 8

    # Comma-separated list of allowed browser origins (the mobile app does not need CORS).
    cors_origins: str = "*"

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
            problems.append("SABIL_CORS_ORIGINS must list real origins, not '*'")
        if problems:
            if self.is_production:
                raise RuntimeError("Insecure production settings:\n- " + "\n- ".join(problems))
            for p in problems:
                log.warning("DEV MODE: %s (ok for local development only)", p)


@lru_cache
def get_settings() -> Settings:
    return Settings()
