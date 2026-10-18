# SABIL (CoolMan) Software Documentation

This document describes the software architecture, data schemas, verification mechanisms, and API topologies for the Sabil public water locator application.

---

## 🏗️ 1. Architecture Overview

```
 ┌───────────────────────┐
 │   Flutter Client App  │ <── (Mobile, Dart / OpenStreetMap map)
 └───────────┬───────────┘
             │ HTTP (JSON and photo uploads) over port 8000
             ▼
 ┌───────────────────────┐
 │   FastAPI Backend API │ <── (Python / Uvicorn)
 └───────────┬───────────┘
             │ asyncpg
             ▼
 ┌───────────────────────┐
 │ PostgreSQL + PostGIS  │ <── (stores coolers; answers "what is within 5 km?")
 └───────────────────────┘
```

1.  **Mobile client (Flutter/Dart)**: a single map screen with pop-up sheets, plus profile, submissions, sponsor, onboarding and (hidden) admin screens. Map markers are grouped with `flutter_map_marker_cluster`.
2.  **Server (FastAPI/SQLAlchemy)**: asynchronous REST API with rate limits and sign-in. Distance searches use PostGIS.

The code is organised by **feature**: each feature folder holds its own `models.py` (database tables), `schemas.py` (what the API accepts and returns) and `router.py` (the routes). See the folder map and the list of reusable pieces in sections 6 and 7 below.

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
*   `phone` (String(16), optional, unique): Egyptian mobile in the form `+201012345678`, used for phone sign-in.
*   `badges`: Kept on purpose for trust-level badges (nothing writes it yet; see `docs/LAUNCH_PLAN.md` section 8a).
*   `created_at` (DateTime): Registration date.

#### `phone_codes`
One-time SMS codes waiting to be entered (`phone`, keyed hash of the code, `expires_at`, `wrong_tries`, `used`). The code itself is never stored.

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
*   `dedicated_to` (String(120), optional), `dedication_message` (String(280), optional): "Sadaka Jariya in memory of ...", set by an admin only and shown to everyone on the cooler's card.

#### `cooler_photos`
Tracks verification photos uploaded for security review.
*   `id` (UUID): Primary Key.
*   `cooler_id` (UUID, Foreign Key): Owning cooler.
*   `file_path` (String(512)): File address on the disk or S3 bucket.
*   `uploaded_at` (DateTime): Time of upload.
*   `is_approved` (Boolean): Admin approved for public view.
*   `photo_category` (Enum): Cooler, Cups.
*   `user_id` (UUID, Foreign Key): Who uploaded it.

---

## 🔒 3. Integrity, Authentication & Security Guidelines

### Password Encryption
All client credentials utilize cryptographic standards:
*   Passes are salted and scrambled via **PBKDF2-HMAC-SHA256**.
*   Work factor iterations are set to **260,000 iterations**, avoiding brute-force vectors.

### JWT Structure
Tokens are signed server-side using **HMAC-SHA256**:
*   *Audience parameters*: `sabil-user` or `sabil-admin`.
*   *Expirations*: Standard user token is set to **7 days** (10,080 minutes), while admin tokens auto-invalidate after **8 hours** to limit hijacking windows.

---

## 🎮 4. Verification Mechanics & Trust Logic

A central gamified trust loop handles review queues and defends the database against spam:

1.  **Submission Verification**:
    *   Proposed coolers get queued as `is_approved = False`.
    *   If the submitter is a **Verified Reporter (Trust Score ≥ 500)**, the cooler is auto-approved and goes live instantly.
2.  **Trust Flow Calculations** (all numbers live in `backend/sabil/users/trust.py`):
    *   *Add New Cooler*: Approved: **+50 Trust** to the reporter. Rejected: **-100 Trust**.
    *   *Verify / Confirm*: Tap "Still Working" (restricted by a 1-hour cooldown per user and cooler): **+5 Trust**.
    *   *Propose Status Update*: **+10 Trust**, paid only when the change takes effect: at once for trusted users (score >= 500), otherwise when an admin approves it. One report per cooler every 10 minutes, and reporting the status a cooler already has is refused.
3.  **GPS Duplication Guard**:
    *   The database rejects adding a cooler if another cooler exists within a **15-meter radius** (determined via PostGIS `ST_DWithin` on the coordinates index). This blocks multiple reports for the same cooler.
4.  **Privacy of unapproved items**:
    *   An unapproved cooler (`GET /coolers/{id}`) and an unapproved photo (`/uploads/photos/<file>`) are visible only to admins and to the person who submitted them. Everyone else gets 404.
5.  **Abuse limits** (all in `backend/sabil/core/config.py`):
    *   3 new coolers per minute per IP; 20 photo uploads per minute per IP; 10 login/register attempts per minute per IP.
    *   Uploads: JPEG, PNG or WebP only (checked by the file's real contents), at most 8 MB.
    *   `SABIL_ENV=production` makes the server refuse to start with the default admin password or token secret.

---

## 🌐 5. API Overview

Interactive docs are served at `/docs` when the server runs. Routes by feature:

| Feature | Routes |
|---|---|
| Accounts | `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `GET /users/leaderboard` |
| Phone sign-in | `POST /auth/phone/request` (text a code), `POST /auth/phone/verify` (log in, or create the account with a username), `POST /auth/phone/attach` (logged-in user links a number) |
| Finding coolers | `GET /coolers/nearby`, `GET /coolers/search`, `GET /coolers/my`, `GET /coolers/{id}`, `GET /coolers/{id}/photos` |
| Reporting | `POST /coolers`, `PATCH /coolers/{id}/status`, `POST /coolers/{id}/confirm`, `POST /coolers/{id}/photos` |
| Sponsors (public) | `GET /sponsors`, `GET /sponsors/{id}` |
| Photos | `GET /uploads/photos/{file}` (approval-checked) |
| Admin (needs admin token) | `POST /auth/admin/login`, then everything under `/admin/...`: review queue, approve / reject, force status, delete, photo moderation, sponsor management, "in memory of" dedications (`PUT/DELETE /admin/coolers/{id}/dedication`, `GET /admin/dedications`) |

---

## 6. Reusable pieces

Each of these has no knowledge of coolers, so you can copy it into another project.

**Backend (`backend/sabil/`)**

| File | What it gives you | Copy it with |
|---|---|---|
| `core/security.py` | Password hashing and signed login tokens (JWT) with no extra libraries | `core/config.py` (the settings it reads) |
| `core/rate_limit.py` | Per-IP request limits and per-user cooldowns | `core/config.py` |
| `core/validation.py` | Text sanitising for user input (Arabic letters and punctuation allowed) | nothing |
| `core/phone.py` | Cleans Egyptian mobile numbers into `+20...` (accepts 010..., +20..., Arabic digits) | nothing |
| `core/sms.py` | "Send a text" with swappable providers (console for development) | `core/config.py` |
| `core/lookup.py` | `get_or_404` helper | nothing |
| `core/dependencies.py` | "Who is asking?" (user / admin / anonymous) for FastAPI routes | `core/security.py` |
| `media/storage.py` | Safe image saving: type check by content, size cap, random file names | `core/config.py` |

**Mobile (`mobile/lib/`)**

| File | What it gives you |
|---|---|
| `core/theme.dart` | All colours (`AppColors`) and the app theme in one place |
| `core/config.dart` | The one server address |
| `services/session_store.dart` | Saved login (token kept in secure storage) |
| `services/api_client.dart` | Building URLs and reading error messages |
| `widgets/app_snackbar.dart`, `photo_pickers.dart`, `auth_dialog.dart` | Message bar, camera/gallery pop-ups, login pop-up |
| `screens/admin/...`, `screens/map/...`, `screens/profile/...` | One folder per screen: the screen file holds the state, the folder holds its pieces |

---

## 7. Folder map

```
backend/
  sabil/
    main.py            starts the app and plugs in the feature folders
    core/              settings, database, security, limits, shared helpers
    users/             accounts, phone sign-in, leaderboard, trust rules
    coolers/           the main feature: find, add, report, photos, who-can-see-what
    sponsors/          public sponsor pages
    admin/             admin login, review queue, moderation, sponsor management, dedications
    media/             saving image files and serving them safely
  scripts/seed.py      puts sample coolers in an empty database
  scripts/sync_schema.py  compares an existing database with the models and fixes the columns
  tests/               automated tests (need a PostGIS database)
mobile/lib/
  main.dart            app start
  core/                colours and server address
  models/              plain data classes (one per file)
  services/            talking to the server (one file per area) + saved login
  widgets/             small pieces used on several screens
  screens/             the screens, with a sub-folder of pieces for the big ones
docs/FINDINGS_LOG.md   problems found, what was fixed, what is left
docs/LAUNCH_PLAN.md    what the app still needs before launch in Egypt
docs/translations/     Arabic translation spreadsheet (every text in the app)
tools/pack_code.py     writes the whole code into one dated text file
```
