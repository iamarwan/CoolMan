# Nwasy Software Documentation (repository: CoolMan)

This document describes the software architecture, data schemas, verification mechanisms, and API topologies for the Sabil public water locator application.

---

## 🏗️ 1. Architecture Overview

```
 ┌───────────────────────┐
 │   Flutter Client App  │ <── (Mobile, Dart / OSM Map Canvas)
 └───────────┬───────────┘
             │ HTTP (JSON / Parts) over Port 8000
             ▼
 ┌───────────────────────┐
 │   FastAPI Backend API │ <── (Python / Uvicorn Server Engine)
 └───────────┬───────────┘
             │ asyncpg (Async Database Adapter)
             ▼
 ┌───────────────────────┐
 │ PostgreSQL + PostGIS  │ <── (Relational DB Spatial Spatial Query Engine)
 └───────────────────────┘
```

The system relies on a two-tier full-stack architecture:
1.  **Mobile Client (Flutter/Dart)**: Map-first app. Loads only the coolers inside the visible map area (`GET /coolers/map`), clusters them, and fetches full details when a pin is tapped.
2.  **Server Engine (FastAPI/SQLAlchemy)**: Async API in the `app/` package (routers per area, services for trust rules and image processing). Schema managed with Alembic migrations (`migrations/`).

### Admin panel (`app/admin_web/`)

Server-rendered pages at `/admin`: review queue (new coolers, status changes,
photos), cooler list and detail (status, sponsor, photos, hide/restore/delete),
sponsors. Login is the `SABIL_ADMIN_USERNAME` / `SABIL_ADMIN_PASSWORD` account;
the session is an HttpOnly, SameSite=Strict cookie scoped to `/admin`, every
form carries a CSRF token, and pages send strict security headers. Moderation
logic lives in `app/services/moderation.py`.

### Mobile app structure (`mobile/lib/`)

```
main.dart            start-up (never waits on the network), error boundary
app/app.dart         MaterialApp, theme, first screen (onboarding or map)
core/                config (--dart-define), ApiClient, session (login), cache, location, formatting
models/              Cooler, CoolerPin, Sponsor, UserProfile ...
features/map/        map screen, viewport pin loading (MapPinsController), clustering, search
features/cooler/     detail sheet, add-cooler form, photo picking, repository
features/auth/       login/register sheet (shown only when contributing)
features/profile/    profile, stats, leaderboard, my submissions
features/home/       bottom navigation (map, my reports, account)
features/patron/     a cooler's patron page (opened from the cooler only)
features/onboarding/ first-run pages (with a language button)
l10n/                English + Arabic translations (app_en.arb, app_ar.arb) and generated code
app/theme.dart       the Nwasy theme (from the Stitch design system)
shared/ui.dart       design tokens (AppColors), pills, cards, buttons
```

State is managed with Riverpod. How the map stays fast:
1. On launch it shows the pins and camera position saved from the last session.
2. When the map stops moving (350 ms), it requests only the visible area plus a margin from `GET /coolers/map`, skipping the request if that area was loaded in the last 2 minutes.
3. Late responses from older requests are ignored; pins are clustered at low zoom.
4. Actions (confirm, report) update the screen first and roll back if the server refuses.
5. Map tiles are cached on the device by flutter_map.

### Languages (English / Arabic)

- All app text lives in `mobile/lib/l10n/app_en.arb` (English, the template) and
  `app_ar.arb` (Arabic). Use them in code with `context.l10n.someKey`.
- To add or change text: edit both `.arb` files, then run `flutter gen-l10n`
  (also runs automatically on `flutter run` / `flutter build`). A test fails if a
  key exists in only one language.
- Choosing Arabic switches the whole app to right-to-left. Layouts use
  direction-aware padding/alignment (`EdgeInsetsDirectional`, `AlignmentDirectional`).
- The app follows the phone's language by default; users can change it from
  the onboarding screen, the guest menu (account icon) or Profile → Language.
- Server errors carry a `code` that the app translates; cooler and sponsor
  names are shown exactly as entered.
- Arabic is drawn with the phone's built-in Arabic font for now; the brand font
  (covering Arabic and Latin) is chosen and bundled in Phase 6.

### Key endpoints

| Endpoint | Purpose |
|---|---|
| `GET /coolers/map?min_lat&min_lng&max_lat&max_lng&limit` | Minimal pins inside the visible map area |
| `GET /coolers/{id}` | Full cooler detail (approved photos only) |
| `GET /coolers/search?q&lat&lng` | Name search, nearest first when lat/lng given |
| `POST /coolers` · `PATCH /coolers/{id}/status` · `POST /coolers/{id}/confirm` · `POST /coolers/{id}/photos` | Contributions (login required) |
| `GET /users/me/stats` · `GET /users/leaderboard` | Profile numbers, top 10 |
| `/admin` | Web admin panel (HTML, cookie login, CSRF-protected forms) |
| `GET /health` | Liveness + database check |
| `DELETE /auth/me`, `/account/delete`, `/privacy` | Account deletion (app and web) and the privacy page |

**The "be there" rule.** Confirming, reporting, photo uploads and new coolers
must carry the phone's position (`lat`, `lng`, `accuracy`) and are refused
beyond `SABIL_MAX_ACTION_DISTANCE_M` (default 50) or when GPS accuracy is worse
than `SABIL_MAX_GPS_ACCURACY_M` (default 40). The position is checked and
discarded. Error codes: `too_far`, `location_required`, `location_inaccurate`.

Errors look like `{"detail": "...", "code": "cooler_duplicate"}`; the app translates `code`.

---

## 🗄️ 2. Database Schema & Relations

The PostgreSQL schema is structured around 4 interactive entities:

```
                  ┌──────────────┐
                  │    users     │
                  └──────┬───────┘
                         │ 1
                         │
                         │ 1..* (Submissions, Approvals, Votes)
                         ▼
  ┌──────────┐ 1      ┌─────────────────┐ 1      ┌────────────────┐
  │ sponsors ├───────>│  water_coolers  ├────────>│ cooler_photos  │
  └──────────┘  0..*  └─────────────────┘   0..*  └────────────────┘
```

### Table Definitions

#### `users`
Tracks registered community contributors and administrators.
*   `id` (UUID): Primary Key.
*   `username` (String(64)): Unique index.
*   `hashed_password` (String(256)): Structured password hash.
*   `trust_score` (Integer): Dynamic score mapping permissions. Default: 0.
*   `created_at` (DateTime): Registration date.

#### `sponsors`
Tracks commercial or religious organizations sponsoring charity coolers.
*   `id` (UUID): Primary Key.
*   `name` (String(255)): Entity name.
*   `sponsor_type` (Enum): Business, Mosque, Individual, NGO.
*   `contact` (String(255), optional): Launch links or telephone numbers.
*   `verified` (Boolean): Administrative endorsement state. Default: False.

#### `water_coolers`
The main spatial entity representing physical drinking water stations.
*   `id` (UUID): Primary Key.
*   `name` (String(255)): Human-readable label or landmark description.
*   `latitude`, `longitude` (Numeric(10, 7)): Decimal map coordinates.
*   `geom` (Geometry(POINT, 4326)): Spatial coordinate mapped to PostGIS indexes.
*   `status` (Enum): Working, Empty, Broken.
*   `last_verified_at` (DateTime): Last confirmation date.
*   `is_approved` (Boolean): Live visibility state.
*   `is_rejected` (Boolean): Deemed spam or non-existent.
*   `pending_status` (String, optional): Staged update proposed by non-trusted reporter.
*   `has_cups` (Boolean, optional): High-level cup count stock.
*   `cups_type` (Enum, optional): Communal, Disposable.
*   `user_id` (UUID, Foreign Key): Identifier of the original reporter.
*   `pending_status_user_id` (UUID, Foreign Key): Submitter of review updates.
*   `sponsor_id` (UUID, Foreign Key): Linked charity sponsor.

#### `cooler_photos`
Tracks verification photos uploaded for security review.
*   `id` (UUID): Primary Key.
*   `cooler_id` (UUID, Foreign Key): Owning cooler.
*   `file_path` (String(512)): Full image URL path (max 1600 px JPEG, EXIF/GPS stripped).
*   `thumb_path` (String(512)): Thumbnail URL path (max 400 px).
*   `uploaded_at` (DateTime): Time of upload.
*   `is_approved` (Boolean): Admin approved for public view.
*   `photo_category` (Enum): Cooler, Cups.

---

## 🔒 3. Integrity, Authentication & Security Guidelines

### Password Encryption
All client credentials utilize cryptographic standards:
*   Passes are salted and scrambled via **PBKDF2-HMAC-SHA256**.
*   Work factor iterations are set to **260,000 iterations**, avoiding brute-force vectors.

### JWT Structure
Tokens are signed server-side using **HMAC-SHA256**:
*   *Audience parameters*: `sabil-user` or `sabil-admin`.
*   *Expirations*: User tokens last **30 days**; admin tokens **8 hours**.
*   In production (`SABIL_ENV=production`) the server refuses to start with default/weak secrets.

---

## 🎮 4. Verification Mechanics & Trust Logic

A central gamified trust loop handles review queues and defends the database against spam:

1.  **Submission Verification**:
    *   Proposed coolers get queued as `is_approved = False`.
    *   If the submitter is a **Verified Reporter (Trust Score ≥ 500)**, the cooler is auto-approved and goes live instantly.
2.  **Trust Flow Calculations**:
    *   *Add New Cooler*: Approved: **+50 Trust** to the reporter. Rejected: **-100 Trust**.
    *   *Verify / Confirm*: Tap "Still Working" (1-hour cooldown per cooler per user): **+5 Trust**.
    *   *Propose Status Update*: **+10 Trust** (1-hour cooldown per cooler per user). If trust ≥ 500, the status updates instantly; otherwise it is staged as `pending_status` for admin approval.
    *   Cooldowns are stored in the `user_actions` table, so they survive restarts. When a cooler's status changes, everyone may confirm it again.
    *   Submission limits: 10 new coolers and 30 photos per user per hour.
3.  **GPS Duplication Guard**:
    *   The API rejects adding a cooler if a non-rejected cooler exists within **15 meters** (bounding-box index pre-filter + geodesic `ST_DWithin`).
