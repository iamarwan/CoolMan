# database.py

import os
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

# Load from environment with a sensible local default.
# In production set SABIL_DATABASE_URL in your environment or .env file.
DATABASE_URL = os.getenv(
    "SABIL_DATABASE_URL",
    "postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_db?ssl=disable",
)

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
