# core/database.py
#
# Connects to PostgreSQL and hands out database sessions.
#
#   engine         the connection pool to the database
#   Base           the parent class of every model (every table class inherits it)
#   get_db()       a FastAPI dependency: gives each request its own session
#   init_db()      creates the PostGIS extension and any missing tables

from typing import AsyncGenerator

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

from sabil.core.config import DATABASE_URL

engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,          # detect stale connections
    pool_size=10,
    max_overflow=20,
)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session


async def init_db() -> None:
    """Create the PostGIS extension and any tables that do not exist yet.

    Used by the server on startup and by scripts/seed.py.
    """
    # Imported here (not at the top) because the model files import `Base`
    # from THIS file; importing them at the top would be circular.
    import sabil.core.all_models  # noqa: F401  (registers every table with Base)

    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.create_all)
