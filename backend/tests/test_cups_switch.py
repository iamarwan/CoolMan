# Cups are hidden by default and only an admin can switch them on, per cooler.
# Sponsoring a cooler must NOT switch them on by itself.

import uuid

from tests.conftest import reset_limits
from tests.test_phone_and_dedications import _approved_cooler


def test_cups_are_off_by_default(client, admin):
    cid = _approved_cooler(client, admin)
    assert client.get(f"/coolers/{cid}").json()["cups_enabled"] is False


def test_admin_switches_cups_on_and_off(client, admin):
    cid = _approved_cooler(client, admin)
    url = f"/admin/coolers/{cid}/cups"

    r = client.put(url, headers=admin, json={"enabled": True})
    assert r.status_code == 200, r.text
    on = client.get(f"/coolers/{cid}").json()           # public, no login
    assert on["cups_enabled"] is True and on["has_cups"] is True

    r = client.put(url, headers=admin, json={"enabled": False})
    assert r.status_code == 200
    assert client.get(f"/coolers/{cid}").json()["cups_enabled"] is False


def test_only_admin_can_switch_cups(client, admin, make_user):
    cid = _approved_cooler(client, admin)
    url = f"/admin/coolers/{cid}/cups"
    assert client.put(url, json={"enabled": True}).status_code == 401
    assert client.put(url, headers=make_user(), json={"enabled": True}).status_code in (401, 403)
    assert client.get(f"/coolers/{cid}").json()["cups_enabled"] is False


def test_cups_switch_checks_input(client, admin):
    cid = _approved_cooler(client, admin)
    assert client.put(f"/admin/coolers/{cid}/cups", headers=admin, json={}).status_code == 422
    assert client.put(f"/admin/coolers/{uuid.uuid4()}/cups", headers=admin,
                      json={"enabled": True}).status_code == 404


def test_sponsoring_does_not_switch_cups_on(client, admin):
    cid = _approved_cooler(client, admin)
    sponsor = client.post("/admin/sponsors", headers=admin,
                          json={"name": "Banner Co", "sponsor_type": "Business"}).json()
    r = client.patch(f"/admin/coolers/{cid}/assign-sponsor", headers=admin,
                     json={"sponsor_id": sponsor["id"]})
    assert r.status_code == 200, r.text
    got = client.get(f"/coolers/{cid}").json()
    assert got["sponsor"]["name"] == "Banner Co"
    assert got["cups_enabled"] is False
    reset_limits()
