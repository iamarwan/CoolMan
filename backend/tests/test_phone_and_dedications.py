# tests/test_phone_and_dedications.py
#
# Phone sign-in (SMS code) and the admin "in memory of" dedication.

import random
import uuid

import pytest

from sabil.core import sms
from sabil.core.phone import normalize_egyptian_mobile
from tests.conftest import bearer, reset_limits


# ─────────────── helpers ───────────────

class FakeSms:
    """Collects the texts instead of sending them."""

    def __init__(self):
        self.sent = []

    async def send(self, phone, text):
        self.sent.append((phone, text))

    def last_code(self):
        return self.sent[-1][1].split("Sabil code: ")[1].split(".")[0]


@pytest.fixture()
def fake_sms(monkeypatch):
    fake = FakeSms()
    sms.set_sms_sender(fake)
    # no waiting between two codes for the same number in most tests
    monkeypatch.setattr("sabil.users.phone.PHONE_CODE_RESEND_SECONDS", 0)
    yield fake
    sms.set_sms_sender(None)


def new_phone():
    return "010" + "".join(random.choice("0123456789") for _ in range(8))


def new_name():
    return "ph" + uuid.uuid4().hex[:8]


def request_code(client, phone):
    r = client.post("/auth/phone/request", json={"phone": phone})
    reset_limits()
    return r


def verify(client, phone, code, username=None):
    body = {"phone": phone, "code": code}
    if username:
        body["username"] = username
    r = client.post("/auth/phone/verify", json=body)
    reset_limits()
    return r


# ─────────────── number cleaning ───────────────

@pytest.mark.parametrize("raw", [
    "01012345678", "1012345678", "+201012345678", "201012345678",
    "00201012345678", "010 1234 5678", "010-1234-5678", "٠١٠١٢٣٤٥٦٧٨",
])
def test_number_forms_all_become_one(raw):
    assert normalize_egyptian_mobile(raw) == "+201012345678"


@pytest.mark.parametrize("raw", ["", "abc", "0101234567", "01312345678", "+14155550123", "0221234567"])
def test_bad_numbers_are_refused(raw):
    assert normalize_egyptian_mobile(raw) is None


# ─────────────── phone sign-in ───────────────

def test_new_number_needs_a_username_then_signs_in_again(client, fake_sms):
    phone = new_phone()
    assert request_code(client, phone).status_code == 202
    code = fake_sms.last_code()
    assert fake_sms.sent[-1][0] == normalize_egyptian_mobile(phone)

    r = verify(client, phone, code)                       # no username yet
    assert r.status_code == 400 and "username" in r.json()["detail"].lower()

    name = new_name()
    r = verify(client, phone, code, username=name)        # same code still valid
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["is_new"] is True and body["username"] == name and body["access_token"]
    me = client.get("/auth/me", headers=bearer(body["access_token"])).json()
    assert me["phone"] == normalize_egyptian_mobile(phone)

    assert verify(client, phone, code).status_code == 400  # a code works once

    request_code(client, phone)                           # sign in again later
    r = verify(client, phone, fake_sms.last_code())
    assert r.status_code == 200 and r.json()["is_new"] is False
    assert r.json()["id"] == body["id"]


def test_wrong_codes_burn_the_code(client, fake_sms):
    phone = new_phone()
    request_code(client, phone)
    good = fake_sms.last_code()
    bad = "000000" if good != "000000" else "111111"
    answers = [verify(client, phone, bad, username=new_name()) for _ in range(5)]
    assert all(a.status_code == 400 for a in answers)
    assert "too many" in answers[-1].json()["detail"].lower()
    assert verify(client, phone, good, username=new_name()).status_code == 400   # burned


def test_username_taken_keeps_the_code_valid(client, fake_sms):
    phone = new_phone()
    taken = new_name()
    client.post("/auth/register", json={"username": taken, "password": "password123"})
    reset_limits()
    request_code(client, phone)
    code = fake_sms.last_code()
    assert verify(client, phone, code, username=taken).status_code == 409
    assert verify(client, phone, code, username=new_name()).status_code == 200


def test_new_code_replaces_the_old_one(client, fake_sms):
    phone = new_phone()
    request_code(client, phone)
    first = fake_sms.last_code()
    request_code(client, phone)
    second = fake_sms.last_code()
    if first != second:
        assert verify(client, phone, first, username=new_name()).status_code == 400
    assert verify(client, phone, second, username=new_name()).status_code == 200


def test_resend_cooldown_and_hourly_limit(client, fake_sms, monkeypatch):
    monkeypatch.setattr("sabil.users.phone.PHONE_CODE_RESEND_SECONDS", 60)
    phone = new_phone()
    assert request_code(client, phone).status_code == 202
    assert request_code(client, phone).status_code == 429       # too soon

    monkeypatch.setattr("sabil.users.phone.PHONE_CODE_RESEND_SECONDS", 0)
    other = new_phone()
    codes = [request_code(client, other).status_code for _ in range(6)]
    assert codes[:5] == [202] * 5 and codes[5] == 429           # 5 per hour


def test_not_an_egyptian_mobile(client, fake_sms):
    assert request_code(client, "+14155550123").status_code == 422
    assert fake_sms.sent == []


def test_sms_failure_is_reported_and_code_unusable(client, monkeypatch):
    class Broken:
        async def send(self, phone, text):
            raise RuntimeError("provider down")

    sms.set_sms_sender(Broken())
    try:
        assert request_code(client, new_phone()).status_code == 502
    finally:
        sms.set_sms_sender(None)


def test_phone_sign_in_can_be_switched_off(client, monkeypatch):
    sms.set_sms_sender(None)
    monkeypatch.setattr("sabil.core.sms.SMS_PROVIDER", "none")
    assert request_code(client, new_phone()).status_code == 503


def test_logged_in_user_can_attach_a_number(client, fake_sms, make_user):
    me = make_user("att")
    phone = new_phone()
    request_code(client, phone)
    code = fake_sms.last_code()
    r = client.post("/auth/phone/attach", headers=me, json={"phone": phone, "code": code})
    assert r.status_code == 200 and r.json()["phone"] == normalize_egyptian_mobile(phone)
    assert client.get("/auth/me", headers=me).json()["phone"] == normalize_egyptian_mobile(phone)

    # signing in with that number now gives the same account, not a new one
    request_code(client, phone)
    r = verify(client, phone, fake_sms.last_code())
    assert r.status_code == 200 and r.json()["is_new"] is False

    # another account cannot take the same number
    other = make_user("att")
    request_code(client, phone)
    r = client.post("/auth/phone/attach", headers=other, json={"phone": phone, "code": fake_sms.last_code()})
    assert r.status_code == 409


def test_attach_needs_login(client, fake_sms):
    phone = new_phone()
    request_code(client, phone)
    r = client.post("/auth/phone/attach", json={"phone": phone, "code": fake_sms.last_code()})
    assert r.status_code == 401


def test_stored_code_is_not_readable(client, fake_sms):
    """The code itself must not be in the database, only a hash."""
    import asyncio
    from sqlalchemy import select
    from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
    from sqlalchemy.pool import NullPool
    from sabil.core.config import DATABASE_URL
    from sabil.users.models import PhoneCode

    phone = new_phone()
    request_code(client, phone)
    code = fake_sms.last_code()

    async def read():
        # own engine: the app's pooled connections belong to the test client's event loop
        engine = create_async_engine(DATABASE_URL, poolclass=NullPool)
        try:
            async with AsyncSession(engine) as s:
                rows = (await s.execute(
                    select(PhoneCode).where(PhoneCode.phone == normalize_egyptian_mobile(phone))
                )).scalars().all()
                return [r.code_hash for r in rows]
        finally:
            await engine.dispose()

    hashes = asyncio.run(read())
    assert hashes and all(code not in h and len(h) == 64 for h in hashes)


# ─────────────── dedications ───────────────

def _approved_cooler(client, admin, name="Dedicated cooler"):
    lat = 27.0 + random.random() * 0.8
    user = client.post("/auth/register", json={"username": new_name(), "password": "password123"}).json()
    reset_limits()
    h = bearer(user["access_token"])
    r = client.post("/coolers", headers=h, json={"name": name, "latitude": lat, "longitude": 30.0 + random.random() * 0.8})
    reset_limits()
    cid = r.json()["id"]
    assert client.patch(f"/admin/coolers/{cid}/approve", headers=admin).status_code == 200
    return cid


def test_admin_sets_shows_and_clears_a_dedication(client, admin, make_user):
    cid = _approved_cooler(client, admin)
    assert client.get(f"/coolers/{cid}").json()["dedicated_to"] is None

    body = {"dedicated_to": "الحاج أحمد محمد", "message": "رحمه الله، صدقة جارية"}
    r = client.put(f"/admin/coolers/{cid}/dedication", headers=admin, json=body)
    assert r.status_code == 200, r.text
    public = client.get(f"/coolers/{cid}").json()                  # no login at all
    assert public["dedicated_to"] == "الحاج أحمد محمد"
    assert public["dedication_message"] == "رحمه الله، صدقة جارية"

    listing = client.get("/admin/dedications", headers=admin).json()
    assert cid in [c["id"] for c in listing]

    r = client.delete(f"/admin/coolers/{cid}/dedication", headers=admin)
    assert r.status_code == 200 and r.json()["dedicated_to"] is None
    assert client.get(f"/coolers/{cid}").json()["dedication_message"] is None


def test_only_admin_can_dedicate(client, admin, make_user):
    cid = _approved_cooler(client, admin)
    body = {"dedicated_to": "Someone"}
    assert client.put(f"/admin/coolers/{cid}/dedication", json=body).status_code == 401
    assert client.put(f"/admin/coolers/{cid}/dedication", headers=make_user(), json=body).status_code in (401, 403)
    assert client.delete(f"/admin/coolers/{cid}/dedication", headers=make_user()).status_code in (401, 403)


def test_dedication_text_is_checked(client, admin):
    cid = _approved_cooler(client, admin)
    url = f"/admin/coolers/{cid}/dedication"
    assert client.put(url, headers=admin, json={"dedicated_to": "<script>"}).status_code == 422
    assert client.put(url, headers=admin, json={"dedicated_to": ""}).status_code == 422
    assert client.put(url, headers=admin, json={"dedicated_to": "x" * 121}).status_code == 422
    assert client.put(url, headers=admin, json={"dedicated_to": "Ok", "message": "y" * 281}).status_code == 422
    assert client.put(f"/admin/coolers/{uuid.uuid4()}/dedication", headers=admin,
                      json={"dedicated_to": "Ok"}).status_code == 404
