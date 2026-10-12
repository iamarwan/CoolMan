# SABIL (CoolMan) Software Documentation

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
1.  **Mobile Client (Flutter/Dart)**: An immersive single-page map controller with visual overlays, legend overlays, bottom detail drawers, and onboarding pages. Recharts OSM map tiles with high-performance marker clustering (`flutter_map_marker_cluster`) to avoid slow layouts.
2.  **Server Engine (FastAPI/SQLAlchemy)**: A fully asynchronous backend processing REST queries, rate limiter, and authentication. Coordinates GIS spatial filters via PostGIS native SQL directives.

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
*   `file_path` (String(512)): File address on the disk or S3 bucket.
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
*   *Expirations*: Standard user token is set to **7 days** (10,080 minutes), while admin tokens auto-invalidate after **8 hours** to limit hijacking windows.

---

## 🎮 4. Verification Mechanics & Trust Logic

A central gamified trust loop handles review queues and defends the database against spam:

1.  **Submission Verification**:
    *   Proposed coolers get queued as `is_approved = False`.
    *   If the submitter is a **Verified Reporter (Trust Score ≥ 500)**, the cooler is auto-approved and goes live instantly.
2.  **Trust Flow Calculations**:
    *   *Add New Cooler*: Approved: **+50 Trust** to the reporter. Rejected: **-100 Trust**.
    *   *Verify / Confirm*: Tap "Still Working" (restricted by 1-hour cooldown per cooler): **+5 Trust**.
    *   *Propose Status Update*: Suggested status change: **+10 Trust** upon submission. If trust ≥ 500, the status updates instantly. Otherwise, it is staged as `pending_status` for admin approval.
3.  **GPS Duplication Guard**:
    *   The database rejects adding a cooler if another cooler exists within a **15-meter radius** (determined via PostGIS `ST_DWithin` on the coordinates index). This blocks multiple reports for the same cooler.
