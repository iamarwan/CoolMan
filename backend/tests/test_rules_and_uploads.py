# tests/test_rules_and_uploads.py
#
# Covers BE-05 (trust points cannot be farmed), BE-06 (sponsor contact accepts
# emails and phone numbers) and BE-08 (upload size and real file type).

import random

from tests.conftest import reset_limits, tiny_png


def _approved_cooler(client, owner, admin):
    r = client.post("/coolers", headers=owner, json={
        "name": "Rules cooler", "latitude": 27.0 + random.random() * 0.9,
        "longitude": 30.0 + random.random() * 0.9})
    assert r.status_code == 201, r.text
    cid = r.json()["id"]
    client.patch(f"/admin/coolers/{cid}/approve", headers=admin)
    reset_limits()
    return cid


def _score(client, headers):
    return client.get("/auth/me", headers=headers).json()["trust_score"]


def test_status_report_points_are_paid_only_when_approved(client, make_user, admin):
    owner, reporter = make_user("own"), make_user("rep")
    cid = _approved_cooler(client, owner, admin)
    before = _score(client, reporter)

    r = client.patch(f"/coolers/{cid}/status", headers=reporter, json={"status": "Broken"})
    assert r.status_code == 200 and r.json()["pending_status"] == "Broken"
    assert _score(client, reporter) == before                      # nothing yet

    # repeating the report is refused (cooldown), so it cannot be farmed
    assert client.patch(f"/coolers/{cid}/status", headers=reporter, json={"status": "Empty"}).status_code == 429

    client.patch(f"/admin/coolers/{cid}/approve", headers=admin)    # admin approves the change
    assert _score(client, reporter) == before + 10


def test_rejected_status_change_earns_nothing(client, make_user, admin):
    owner, reporter = make_user("own"), make_user("rep")
    cid = _approved_cooler(client, owner, admin)
    before = _score(client, reporter)
    client.patch(f"/coolers/{cid}/status", headers=reporter, json={"status": "Empty"})
    client.patch(f"/admin/coolers/{cid}/reject-status", headers=admin)
    assert _score(client, reporter) == before


def test_reporting_the_current_status_is_refused(client, make_user, admin):
    owner = make_user("own")
    cid = _approved_cooler(client, owner, admin)
    r = client.patch(f"/coolers/{cid}/status", headers=make_user("rep"), json={"status": "Working"})
    assert r.status_code == 400


def test_sponsor_contact_can_be_an_email_or_phone(client, admin):
    for contact in ("noor@example.com", "+20 100 123 4567", "https://example.com/about"):
        r = client.post("/admin/sponsors", headers=admin,
                        json={"name": "Noor Foundation", "sponsor_type": "NGO", "contact": contact})
        assert r.status_code in (200, 201), (contact, r.text)
        client.delete(f"/admin/sponsors/{r.json()['id']}", headers=admin)
    bad = client.post("/admin/sponsors", headers=admin,
                      json={"name": "X", "sponsor_type": "NGO", "contact": "<script>alert(1)</script>"})
    assert bad.status_code == 422


def _cooler_for_upload(client, owner):
    r = client.post("/coolers", headers=owner, json={
        "name": "Upload cooler", "latitude": 26.0 + random.random() * 0.9,
        "longitude": 29.0 + random.random() * 0.9})
    return r.json()["id"]


def test_upload_must_really_be_an_image(client, make_user):
    owner = make_user()
    cid = _cooler_for_upload(client, owner)
    fake = client.post(f"/coolers/{cid}/photos", headers=owner,
                       files={"file": ("a.png", b"this is not an image at all", "image/png")})
    assert fake.status_code == 400
    wrong_label = client.post(f"/coolers/{cid}/photos", headers=owner,
                              files={"file": ("a.jpg", tiny_png(), "image/jpeg")})
    assert wrong_label.status_code == 400
    ok = client.post(f"/coolers/{cid}/photos", headers=owner,
                     files={"file": ("a.png", tiny_png(), "image/png")})
    assert ok.status_code == 201


def test_upload_size_is_capped(client, make_user):
    owner = make_user()
    cid = _cooler_for_upload(client, owner)
    big = tiny_png() + b"\x00" * (9 * 1024 * 1024)
    r = client.post(f"/coolers/{cid}/photos", headers=owner,
                    files={"file": ("a.png", big, "image/png")})
    assert r.status_code == 400 and "too large" in r.json()["detail"]
