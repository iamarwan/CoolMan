"""Test setup: a real PostGIS database (SABIL_TEST_DATABASE_URL) is required.

Default: postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_test
(the docker-compose database on port 5433; create the sabil_test DB once).
"""

import io
import os
import tempfile

TEST_DB = os.getenv(
    "SABIL_TEST_DATABASE_URL",
    "postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_test",
)
os.environ["SABIL_DATABASE_URL"] = TEST_DB
os.environ["SABIL_UPLOAD_DIR"] = tempfile.mkdtemp(prefix="sabil-test-uploads-")
os.environ["SABIL_ENV"] = "development"
os.environ["SABIL_PASSWORD_ITERATIONS"] = "1000"  # fast hashing in tests

import pytest  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from PIL import Image  # noqa: E402
from sqlalchemy import text  # noqa: E402

from app import models  # noqa: E402,F401
from app.db import Base, SessionLocal, engine  # noqa: E402
from app.main import app  # noqa: E402
from app.models import WaterCooler  # noqa: E402
from app.services.coolers import point  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
async def schema():
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


@pytest.fixture(autouse=True)
async def clean_tables():
    yield
    names = ", ".join(t.name for t in Base.metadata.sorted_tables)
    async with engine.begin() as conn:
        await conn.execute(text(f"TRUNCATE {names} RESTART IDENTITY CASCADE"))


@pytest.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


async def register(client: AsyncClient, username: str = "alice", password: str = "password123") -> dict:
    r = await client.post("/auth/register", json={"username": username, "password": password})
    assert r.status_code == 201, r.text
    return r.json()


def auth(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


async def admin_login(client: AsyncClient) -> None:
    """Logs the web admin in; the session cookie stays on `client`."""
    r = await client.post("/admin/login", data={"username": "admin", "password": "admin123"})
    assert r.status_code == 303, r.text


async def admin_post(client: AsyncClient, path: str, data: dict | None = None, **kw):
    from app.admin_web.auth import COOKIE, csrf_for

    token = client.cookies.get(COOKIE)
    assert token, "call admin_login first"
    return await client.post(path, data={"csrf": csrf_for(token), **(data or {})}, **kw)


async def set_trust(username: str, score: int) -> None:
    async with SessionLocal() as db:
        await db.execute(
            text("UPDATE users SET trust_score = :s WHERE username = :u"), {"s": score, "u": username}
        )
        await db.commit()


async def add_cooler(name="Cooler", lat=29.96, lng=31.25, approved=True, **kw) -> str:
    async with SessionLocal() as db:
        c = WaterCooler(
            name=name, latitude=lat, longitude=lng, geom=point(lat, lng), is_approved=approved, **kw
        )
        db.add(c)
        await db.commit()
        return str(c.id)


def jpeg_bytes(size=(2400, 1200)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", size, (20, 120, 110)).save(buf, "JPEG")
    return buf.getvalue()
