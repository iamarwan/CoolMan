<#
  run_backend.ps1 - start the API for local development (Windows PowerShell).

    .\run_backend.ps1            # apply migrations, start server on port 8000
    .\run_backend.ps1 -Reset     # wipe the DB, re-create it and load sample data first
    .\run_backend.ps1 -Test      # run the backend test suite instead

  First time only:
    python -m venv venv
    venv\Scripts\pip install -r requirements-dev.txt
#>
param([switch]$Reset, [switch]$Test)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path "venv\Scripts\python.exe")) {
  throw "No venv found. Run: python -m venv venv; venv\Scripts\pip install -r requirements-dev.txt"
}
$py = "venv\Scripts\python.exe"

if ($Test) {
  & $py -m pytest -q
  exit $LASTEXITCODE
}

if ($Reset) {
  & $py -m scripts.reset_db
} else {
  & $py -m alembic upgrade head
}
if ($LASTEXITCODE -ne 0) { throw "Database setup failed - is PostgreSQL running?" }

Write-Host ""
Write-Host "API:   http://localhost:8000      Docs: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "Phone: http://<this-PC-IP>:8000   (see GETTING_STARTED.md, 'Test on a REAL phone')" -ForegroundColor Cyan
Write-Host ""
& $py -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --reload-dir app
