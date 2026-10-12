# 🚀 SABIL (CoolMan) Project Runbook & Getting Started

Welcome to the Sabil Project! This guide provides a detailed operational map separating what has **already been set up once** from what you need to run **every single time** you start a development session.

---

## ✅ Part 1: Tasks Done ONCE (Completed Setup)

> [!NOTE]
> **These steps have already been successfully completed on your machine.** You do **NOT** need to run these commands again unless you reinstall your environment or clone to a clean machine.

### 1. Database & Spatial Extensions Setup
- PostgreSQL is installed locally.
- The `sabil_db` database is created with owner `sabil` (password: `sabil_pass`).
- PostGIS spatial extensions are enabled.

### 2. Backend Environment Configuration
- A Python virtual environment has been created inside the project root:
  ```bash
  python -m venv venv
  ```
- All required dependencies (`fastapi`, `uvicorn`, `sqlalchemy`, `asyncpg`, `geoalchemy2`, `pydantic`, `pydantic-settings`, `python-multipart`) have been installed in this environment.
- Core table structures and initial Egyptian seed data (in Maadi, Cairo) have been successfully migration-mapped (`db_fix.py` and `seed.py` have been executed).

### 3. Flutter Client SDK & Package Setup
- The Flutter SDK has been added to your system path.
- Android Studio is configured along with the Android SDK licenses.
- Project packages have been successfully pulled:
  ```bash
  cd mobile
  flutter pub get
  ```

---

## 💻 Part 2: Tasks to Do EVERY TIME (Session Runbook)

Follow this precise order of actions every time you start a development session to test the app locally.

### 🗄️ Step 1: Start the PostgreSQL Database Service
Ensure the PostgreSQL server is running:
- **Windows (Native)**: Open `services.msc`, locate **PostgreSQL**, and ensure the status is set to **Running** (or start it via the services window).
- **If using Docker (Alternative)**:
  ```powershell
  docker start sabil-postgis
  ```

---

### 🐍 Step 2: Spin up the FastAPI Backend Server
Open a terminal in the project root directory and execute:

```powershell
# 1. Activate the Python Virtual Environment
venv\Scripts\activate

# 2. Set the local database connection URL
$env:SABIL_DATABASE_URL="postgresql+asyncpg://sabil:sabil_pass@localhost:5433/sabil_db?ssl=disable"

# 3. Start the FastAPI development server with hot-reload enabled (excluding build and library folders to prevent lag)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload --reload-exclude "venv" --reload-exclude "mobile" --reload-exclude "uploads"
```

> [!TIP]
> - Once the server is running, you can access the interactive Swagger API documentation at: **`http://localhost:8000/docs`**
> - If you ever need to reset or re-seed sample Egyptian coordinates (e.g. for testing Maadi Metro Station / Road 9 coolers), run `python seed.py` while the database is running.

---

### 📱 Step 3: Launch Android Emulator & Connect the Client App
1. Open your Android Emulator (via Android Studio, VS Code device selector, or CLI).
2. Set the emulator's mock GPS location to Cairo, Egypt (e.g. `29.9596, 31.2575` in Maadi) to see the seeded coolers on the map.
3. Open a second terminal window, navigate to the `mobile` directory, and run the client:

```powershell
cd mobile
flutter run
```

> [!IMPORTANT]
> The Flutter application connects to the local computer server using the dedicated loopback bridge IP **`10.0.2.2:8000`** (defined in `api_service.dart`). Do not change this unless you are deploying to a physical device on the same local Wi-Fi.

---

## 🛠️ Troubleshooting Cheat Sheet

| Symptom | Root Cause | Immediate Action |
| :--- | :--- | :--- |
| **ST_DWithin function not found** | PostGIS extension is missing | Run database console and execute: <br> `CREATE EXTENSION IF NOT EXISTS postgis;` |
| **Flutter app cannot fetch results** | Server not running / IP config error | Ensure the FastAPI server is running on port 8000. Verify the emulator uses `10.0.2.2` in `api_service.dart`. |
| **JWT credentials rejected** | Out-of-sync session token | Tap **Logout** in the profile screen to clear tokens, or run `flutter clean` to wipe build caches. |
| **Cannot fetch current location** | Emulator location services disabled | Toggle location settings inside the emulator's extended settings (`...` menu). |
