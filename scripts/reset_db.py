"""DANGER: wipes all app tables, re-creates the schema with migrations and
loads sample data. Development only.

    python -m scripts.reset_db
"""

import asyncio
import subprocess
import sys

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from app.config import get_settings

from app import models  # noqa: E402,F401  (registers every table)
from app.db import Base  # noqa: E402

# Every table the app defines, plus Alembic's bookkeeping table.
TABLES = [t.name for t in Base.metadata.sorted_tables] + ["alembic_version"]
TYPES = ["actiontype", "photocategory", "cupstype", "coolerstatus", "sponsortype"]


async def drop_everything() -> None:
    engine = create_async_engine(get_settings().database_url)
    async with engine.begin() as conn:
        for t in TABLES:
            await conn.execute(text(f'DROP TABLE IF EXISTS "{t}" CASCADE'))
        for t in TYPES:
            await conn.execute(text(f'DROP TYPE IF EXISTS "{t}" CASCADE'))
    await engine.dispose()


def main() -> None:
    settings = get_settings()
    if settings.is_production:
        sys.exit("Refusing to reset a production database.")
    if "--yes" not in sys.argv:
        answer = input(f"This deletes ALL data in {settings.database_url.split('@')[-1]}. Type 'yes': ")
        if answer.strip().lower() != "yes":
            sys.exit("Cancelled.")
    asyncio.run(drop_everything())
    subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"], check=True)
    subprocess.run([sys.executable, "-m", "scripts.seed"], check=True)
    print("Database reset and seeded.")


if __name__ == "__main__":
    main()
