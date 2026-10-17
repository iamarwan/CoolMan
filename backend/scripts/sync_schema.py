# scripts/sync_schema.py
#
# Brings an EXISTING database up to date with the models (BE-14).
# `create_all` (run at server start) creates missing tables but never changes
# existing ones, so a database made by an older version can lack new columns
# or still hold removed ones. This script compares the two and fixes it.
#
# Run from the backend/ folder while the database is running:
#
#     python -m scripts.sync_schema                 # only REPORT what differs
#     python -m scripts.sync_schema --apply         # add the missing columns
#     python -m scripts.sync_schema --apply --drop-extra
#                                                   # ALSO drop columns the code no longer uses
#
# Nothing is changed without --apply, and nothing is ever dropped without
# --drop-extra (dropped data cannot be recovered: take a backup first).

import asyncio
import sys

from sqlalchemy import inspect, text

from sabil.core.database import Base, engine, init_db


def _column_ddl(table: str, column, dialect) -> str:
    sql_type = column.type.compile(dialect=dialect)
    default = ""
    if column.server_default is not None:
        default = f" DEFAULT {column.server_default.arg.text}" if hasattr(column.server_default.arg, "text") else f" DEFAULT {column.server_default.arg}"
    # A NOT NULL column can only be added to a table that already has rows
    # when it has a default, so otherwise it is added as nullable.
    not_null = " NOT NULL" if (not column.nullable and default) else ""
    return f'ALTER TABLE "{table}" ADD COLUMN IF NOT EXISTS "{column.name}" {sql_type}{default}{not_null}'


def _diff(sync_conn):
    insp = inspect(sync_conn)
    missing, extra = [], []
    for table in Base.metadata.sorted_tables:
        if not insp.has_table(table.name):
            continue  # create_all makes whole missing tables
        db_cols = {c["name"] for c in insp.get_columns(table.name)}
        model_cols = {c.name for c in table.columns}
        for name in sorted(model_cols - db_cols):
            missing.append((table, table.columns[name]))
        for name in sorted(db_cols - model_cols):
            extra.append((table.name, name))
    return missing, extra


async def main(apply: bool, drop_extra: bool) -> None:
    await init_db()  # makes missing tables so only column differences remain
    async with engine.begin() as conn:
        missing, extra = await conn.run_sync(_diff)
        dialect = conn.dialect

        print("Columns the code expects but the database lacks:")
        for table, col in missing or []:
            print(f"  + {table.name}.{col.name}")
        if not missing:
            print("  (none)")
        print("Columns in the database that the code no longer uses:")
        for t, c in extra:
            print(f"  - {t}.{c}")
        if not extra:
            print("  (none)")

        if not apply:
            print("\nDry run: nothing changed. Add --apply to fix the missing columns.")
            return

        for table, col in missing:
            ddl = _column_ddl(table.name, col, dialect)
            print("run:", ddl)
            await conn.execute(text(ddl))
            if col.unique or col.index:  # keep uniqueness / speed of the new column
                kind = "UNIQUE INDEX" if col.unique else "INDEX"
                idx = f'CREATE {kind} IF NOT EXISTS "ix_{table.name}_{col.name}" ON "{table.name}" ("{col.name}")'
                print("run:", idx)
                await conn.execute(text(idx))
        if drop_extra:
            for t, c in extra:
                ddl = f'ALTER TABLE "{t}" DROP COLUMN IF EXISTS "{c}"'
                print("run:", ddl)
                await conn.execute(text(ddl))
        elif extra:
            print("\nUnused columns were left in place (harmless). Add --drop-extra to remove them.")
    print("Done.")


if __name__ == "__main__":
    asyncio.run(main("--apply" in sys.argv, "--drop-extra" in sys.argv))
