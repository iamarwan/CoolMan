"""security hardening: case-insensitive usernames, rate limits, points per action

Revision ID: b2c4d6e8f0a1
Revises: 37075f6b706a
Create Date: 2026-11-11
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b2c4d6e8f0a1"
down_revision: Union[str, None] = "37075f6b706a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Usernames unique ignoring case. Fails if "Alice" and "alice" both exist;
    # rename one of them first (development databases can simply be reset).
    op.drop_index("ix_users_username", table_name="users")
    op.create_index(
        "ix_users_username_lower", "users", [sa.text("lower(username)")], unique=True
    )

    op.add_column(
        "water_coolers", sa.Column("status_changed_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column(
        "user_actions", sa.Column("points", sa.Integer(), server_default="0", nullable=False)
    )
    # Confirmations made before this change each earned 5 points.
    op.execute("UPDATE user_actions SET points = 5 WHERE action = 'confirm'")

    op.create_table(
        "rate_hits",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("bucket", sa.String(length=200), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_rate_hits_bucket_time", "rate_hits", ["bucket", "created_at"])


def downgrade() -> None:
    op.drop_index("ix_rate_hits_bucket_time", table_name="rate_hits")
    op.drop_table("rate_hits")
    op.drop_column("user_actions", "points")
    op.drop_column("water_coolers", "status_changed_at")
    op.drop_index("ix_users_username_lower", table_name="users")
    op.create_index("ix_users_username", "users", ["username"], unique=True)
