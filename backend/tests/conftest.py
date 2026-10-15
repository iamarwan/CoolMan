# tests/conftest.py
#
# Shared set-up for the tests. They talk to a REAL PostGIS database, so point
# SABIL_DATABASE_URL at a throw-away database before running, for example:
#
#   SABIL_DATABASE_URL="postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_test?ssl=disable" \
#       python -m pytest tests -q
#
# (run from the backend/ folder; create the empty database first)

import struct
import uuid
import zlib

import pytest
from fastapi.testclient import TestClient

from sabil.core import rate_limit
from sabil.main import app


def tiny_png() -> bytes:
    """A valid 1x1 PNG image, built by hand so no image library is needed."""
    def chunk(kind: bytes, data: bytes) -> bytes:
        body = struct.pack(">I", len(data)) + kind + data
        return body + struct.pack(">I", zlib.crc32(kind + data))

    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(b"\x00\xff\x00\x00"))
        + chunk(b"IEND", b"")
    )


def reset_limits() -> None:
    """Forget all rate-limit counters so one test cannot affect another."""
    for store in (
        rate_limit._requests_by_ip,
        rate_limit._photo_uploads_by_ip,
        rate_limit._auth_attempts_by_ip,
    ):
        store.clear()
    rate_limit._last_confirm.clear()


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture(autouse=True)
def _fresh_limits():
    reset_limits()
    yield
    reset_limits()


def bearer(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def make_user(client):
    def _make(prefix="user"):
        name = f"{prefix}{uuid.uuid4().hex[:8]}"
        r = client.post("/auth/register", json={"username": name, "password": "password123"})
        assert r.status_code == 201, r.text
        reset_limits()
        return bearer(r.json()["access_token"])
    return _make


@pytest.fixture()
def admin(client):
    r = client.post("/auth/admin/login", json={"username": "admin", "password": "admin123"})
    assert r.status_code == 200, r.text
    reset_limits()
    return bearer(r.json()["access_token"])
