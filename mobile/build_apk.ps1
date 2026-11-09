<#
  build_apk.ps1 - build small release APKs for Android.

  USAGE (PowerShell, from the mobile folder):
    .\build_apk.ps1                         # phone on your Wi-Fi -> auto-detects this PC's IP
    .\build_apk.ps1 -ApiUrl http://192.168.1.20:8000
    .\build_apk.ps1 -ApiUrl https://api.your-domain.com   # production (HTTPS only)
    .\build_apk.ps1 -Emulator               # Android emulator (http://10.0.2.2:8000)

  OUTPUT:
    build\app\outputs\flutter-apk\app-arm64-v8a-release.apk   <- install THIS on almost any phone
    build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk <- very old 32-bit phones only
    build\app\outputs\flutter-apk\app-x86_64-release.apk      <- emulators only

  Why three files? One "fat" APK contains native code for all three CPU types and is
  ~3x bigger. Each phone only needs one of them.
#>
param(
  [string]$ApiUrl = "",
  [switch]$Emulator,
  [string]$TileUrl = ""
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if ($Emulator) {
  $ApiUrl = "http://10.0.2.2:8000"
}

if (-not $ApiUrl) {
  # Pick this PC's Wi-Fi/Ethernet IPv4 address (skip virtual adapters).
  $ip = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
      $_.IPAddress -notmatch '^(127\.|169\.254\.)' -and
      $_.InterfaceAlias -notmatch 'vEthernet|VirtualBox|VMware|Loopback|WSL|Docker'
    } |
    Sort-Object -Property InterfaceMetric |
    Select-Object -First 1 -ExpandProperty IPAddress
  if (-not $ip) { throw "Could not detect this PC's IP. Pass -ApiUrl http://<your-pc-ip>:8000" }
  $ApiUrl = "http://${ip}:8000"
}

Write-Host ""
Write-Host "Building release APKs" -ForegroundColor Cyan
Write-Host "  API_BASE_URL = $ApiUrl"
if ($ApiUrl.StartsWith("http://")) {
  Write-Host "  (plain HTTP allowed - fine for testing on your Wi-Fi, NOT for production)" -ForegroundColor Yellow
}
Write-Host ""

$defines = @("--dart-define=API_BASE_URL=$ApiUrl")
if ($TileUrl) { $defines += "--dart-define=TILE_URL=$TileUrl" }

flutter build apk --release `
  --split-per-abi `
  --obfuscate `
  --split-debug-info=build/debug-symbols `
  @defines

if ($LASTEXITCODE -ne 0) { throw "flutter build failed" }

Write-Host ""
Write-Host "APK sizes:" -ForegroundColor Cyan
Get-ChildItem "build\app\outputs\flutter-apk\*-release.apk" | ForEach-Object {
  "{0,-40} {1,6:N1} MB" -f $_.Name, ($_.Length / 1MB)
}
Write-Host ""
Write-Host "Install on a USB-connected phone:" -ForegroundColor Cyan
Write-Host "  adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
Write-Host ""
Write-Host "Keep build\debug-symbols - it is needed to read crash stack traces." -ForegroundColor DarkGray
