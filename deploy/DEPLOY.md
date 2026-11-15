# Deploying Sabil (when you are ready)

Everything in this `deploy/` folder is **inactive** until you follow these
steps. Local development does not use any of it.

## What you need

1. **A server** — any small Linux VPS (1 vCPU, 1–2 GB RAM is enough to start),
   e.g. Hetzner, DigitalOcean, Contabo, AWS Lightsail. Ubuntu 24.04 recommended.
2. **A domain** — e.g. `yourapp.com`. Create a DNS **A record** for
   `api.yourapp.com` pointing at the server's IP address.
3. **Docker** on the server: `curl -fsSL https://get.docker.com | sh`

## Steps

```bash
# 1. On the server: get the code
git clone https://github.com/<you>/CoolMan.git && cd CoolMan

# 2. Fill in the production settings
cp deploy/.env.production.example deploy/.env.production
nano deploy/.env.production          # set API_DOMAIN, passwords, JWT secret

# 3. Start everything (database + API + HTTPS)
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env.production up -d --build

# 4. Check it
curl https://api.yourapp.com/health   # -> {"status":"ok"}
```

The admin panel is then at `https://api.yourapp.com/admin`, logging in with
`SABIL_ADMIN_USERNAME` / `SABIL_ADMIN_PASSWORD` from your `.env.production`.

Caddy obtains the HTTPS certificate automatically on first start (this needs
ports 80 and 443 open and the DNS record already pointing at the server).

## Point the app at the server

On your PC:

```powershell
cd mobile
.\build_apk.ps1 -ApiUrl https://api.yourapp.com
```

Because the URL is `https://`, the build automatically **blocks plain HTTP**
(see `mobile/android/app/build.gradle.kts`).

## Map tiles

OpenStreetMap's public tile servers are not meant for production apps. Create a
free/low-cost account with a tile provider (MapTiler, Stadia Maps, Carto, ...)
and build with its URL:

```powershell
.\build_apk.ps1 -ApiUrl https://api.yourapp.com -TileUrl "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=YOUR_KEY"
```

## Updating

```bash
git pull
docker compose -f deploy/docker-compose.prod.yml --env-file deploy/.env.production up -d --build
```

Migrations run automatically when the API container starts.

## Backups

```bash
# Database dump
docker compose -f deploy/docker-compose.prod.yml exec db pg_dump -U sabil sabil > backup.sql
# Photos live in the "uploads" Docker volume
docker run --rm -v sabil_uploads:/data -v "$PWD":/backup alpine tar czf /backup/uploads.tgz -C /data .
```

## Before publishing on Google Play

- Create an upload signing key and configure it in
  `mobile/android/app/build.gradle.kts` (currently signs with the debug key).
- Change the application id `com.example.sabil` (done in the rebrand phase).
- Build an App Bundle: `flutter build appbundle --obfuscate --split-debug-info=build/debug-symbols --dart-define=API_BASE_URL=https://api.yourapp.com`
