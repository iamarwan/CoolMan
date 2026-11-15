"""Alembic environment (async, PostGIS-aware)."""

import asyncio

from alembic import context
from geoalchemy2 import alembic_helpers
from sqlalchemy import pool, text
from sqlalchemy.ext.asyncio import create_async_engine

from app import models  # noqa: F401  (registers tables)
from app.config import get_settings
from app.db import Base

config = context.config
target_metadata = Base.metadata


def _include_object(obj, name, type_, reflected, compare_to):
    # Ignore PostGIS/tiger internal tables.
    if type_ == "table" and reflected and compare_to is None:
        return False
    return alembic_helpers.include_object(obj, name, type_, reflected, compare_to)


def _configure(connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        include_object=_include_object,
        process_revision_directives=alembic_helpers.writer,
        render_item=alembic_helpers.render_item,
        compare_type=True,
    )


def _run_sync(connection) -> None:
    _configure(connection)
    with context.begin_transaction():
        context.run_migrations()


async def run_online() -> None:
    engine = create_async_engine(get_settings().database_url, poolclass=pool.NullPool)
    async with engine.connect() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.commit()
        await conn.run_sync(_run_sync)
    await engine.dispose()


if context.is_offline_mode():
    context.configure(url=get_settings().database_url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()
else:
    asyncio.run(run_online())
