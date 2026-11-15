"""build-a-sabil requests sent from the app

Revision ID: c3d5e7f9a1b2
Revises: b2c4d6e8f0a1
Create Date: 2026-11-15
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "c3d5e7f9a1b2"
down_revision: Union[str, None] = "b2c4d6e8f0a1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

STATUS = sa.Enum("new", "contacted", "site_visit", "quoted", "won", "lost", name="requeststatus")


def upgrade() -> None:
    op.create_table(
        "sabil_requests",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=True),
        sa.Column("status", STATUS, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("package", sa.String(length=32), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("taps", sa.Integer(), nullable=False),
        sa.Column("extras", sa.String(length=200), server_default="", nullable=False),
        sa.Column("timing", sa.String(length=32), nullable=False),
        sa.Column("purpose", sa.String(length=32), nullable=False),
        sa.Column("dedication_name", sa.String(length=120), nullable=True),
        sa.Column("plaque_text", sa.String(length=200), nullable=True),
        sa.Column("show_publicly", sa.Boolean(), nullable=False),
        sa.Column("governorate", sa.String(length=32), nullable=False),
        sa.Column("area", sa.String(length=120), nullable=False),
        sa.Column("address_notes", sa.String(length=300), nullable=True),
        sa.Column("latitude", sa.Numeric(precision=10, scale=7), nullable=True),
        sa.Column("longitude", sa.Numeric(precision=10, scale=7), nullable=True),
        sa.Column("place_type", sa.String(length=32), nullable=False),
        sa.Column("permission", sa.String(length=32), nullable=False),
        sa.Column("electricity", sa.String(length=16), nullable=False),
        sa.Column("water_line", sa.String(length=16), nullable=False),
        sa.Column("contact_name", sa.String(length=120), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column("contact_method", sa.String(length=16), nullable=False),
        sa.Column("best_time", sa.String(length=16), nullable=False),
        sa.Column("notes", sa.String(length=1000), nullable=True),
        sa.Column("quote_egp", sa.Integer(), nullable=True),
        sa.Column("admin_notes", sa.String(length=2000), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_sabil_requests_user_id", "sabil_requests", ["user_id"])
    op.create_index("ix_sabil_requests_status_created", "sabil_requests", ["status", "created_at"])


def downgrade() -> None:
    op.drop_index("ix_sabil_requests_status_created", table_name="sabil_requests")
    op.drop_index("ix_sabil_requests_user_id", table_name="sabil_requests")
    op.drop_table("sabil_requests")
    STATUS.drop(op.get_bind(), checkfirst=True)
