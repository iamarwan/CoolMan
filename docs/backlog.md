# Backlog

Updated 2026-11-11 after the Nwasy redesign.

## Done in the redesign (2026-11-11)

| Item | Result |
|---|---|
| 1. Sponsors out of the profile | Done. No sponsors list; a cooler's patron is reachable only from that cooler. |
| 2. Confirm only when near | Done. 50 m rule enforced by the server on confirming, reporting, photos and new coolers; the app shows near / too far / waiting for GPS. GPS less accurate than 40 m is refused. |
| 3. Per-photo review of new submissions | Dropped by the owner. |
| 6. Show a user their own cooler while it waits | Done. Blue "waiting" pin and an "Under review" entry, visible to the author only. |

## From the Stitch designs, not built yet (each needs data the app does not have)

| Design element | What it needs first |
|---|---|
| Saved coolers (bookmark buttons, "Saved" tab) | A saved-places list per user on the server |
| Live community activity feed on a cooler | Showing other users' names and actions: a privacy decision, then an activity endpoint |
| Key specifications (filter stages, temperature, number of taps) | New fields on a cooler and a way to collect them |
| Tap cleanliness rating, "water tasting" notes | A rating feature and its abuse rules |
| Patron dedication story, patron photos, "about 450 people a day" | Patron profile fields in the admin panel; a real way to count people served |
| Offline map download, community alerts switch | Offline tile packs; push notifications |
| Voice search, weather chip, share buttons | Low priority; share needs links that open the app |
| Profile photo, location and "member since" | Photo upload for users; currently accounts are a username only |
| Bottom navigation has 3 tabs instead of 4 | The 4th ("Saved") arrives with saved coolers |

## Still open

## 4. Admin: more context for photos added to an existing cooler

**Current:** the Photos section shows only `Cooler · <name>`, the uploader and
Approve/Delete.

**Agreed behaviour:** make it clear this is an **extra photo for an existing,
live cooler**, with enough context to decide without clicking around, while
keeping the link to the cooler page.

**Planned change** (`app/admin_web/routes.py:queue` + `queue.html`)
- Label: **"New photo for a live cooler"**, with the photo category
  ("shows the cooler" / "shows the cups").
- Show alongside the new photo:
  - Cooler name (link to the cooler page), current status, last confirmed,
    map link.
  - The cooler's **existing approved photos** (small thumbnails) to compare.
  - Uploader: username, trust points, how many of their photos were
    approved/deleted before (needs a count query).
  - Upload time.
- Larger preview: click opens the full-size photo.
- Group several pending photos for the same cooler into one card.
- Optional: "Approve all from this user" for trusted uploaders.

---

## 5. Patrons: needs more work

**Status:** owner wants to improve sponsors; details to be agreed.

**Already known**
- Sponsors show only on their coolers (item 1).
- Admin can add / verify / delete sponsors and assign one per cooler.

**To discuss (Phase 6 + business plan in BUSINESS_STRATEGY.md)**
- What a sponsor card shows on a cooler (logo, short message, offer, contact,
  opening hours, "10 m away" store location).
- Sponsor logos/photos (upload in admin, shown in the app).
- One sponsor for many coolers (bulk assign in admin).
- Sponsor stats for the sponsor (views/taps) — the earlier code had unused
  `views_count`/`clicks_count` columns that were removed; can be re-added.
- Sponsor types and Arabic names (bilingual sponsor name/description).
- Whether sponsors pay (SaaS) and an expiry date for sponsorships.

**Next step:** owner describes what sponsors should look like/do (ideally in
the Stitch designs), then this item gets a concrete plan.

---

## 7. Security items that need the redesign or owner decisions

See `docs/master-plan/06-security-audit.md` (open risks R1 to R5):
limits and undo for trusted accounts,
phone-number login, server-side logout, per-admin accounts.

---

## 8. Code tidy-up after the redesign

- `mobile/lib/features/map/map_screen.dart` (542 lines) and
  `features/cooler/cooler_sheet.dart` (586 lines) are above the 400-line
  target; move their private widgets into their own files.
- The server settings still use the `SABIL_` prefix and the Dart package is
  still named `sabil`. Renaming them is safe but touches every setup step, so
  it is left for a quiet moment.
- Android application id is still `com.example.sabil` (see the quality audit, B1).
