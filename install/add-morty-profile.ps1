# add-morty-profile.ps1
# One-time installer: appends an idempotent morty() loader to your PowerShell profile.
# Safe to re-run — checks for sentinel marker before adding.
#
# Usage: powershell -ExecutionPolicy Bypass -File install\add-morty-profile.ps1

$sentinel   = '# <morty-launcher>'
$launcherPath = Join-Path $PSScriptRoot '..\launchers\morty-launcher.ps1'
$launcherAbs  = (Resolve-Path $launcherPath -ErrorAction SilentlyContinue)?.Path

if (-not $launcherAbs) {
  Write-Error "Could not resolve morty-launcher.ps1 at: $launcherPath"
  exit 1
}

# Ensure $PROFILE exists
if (-not (Test-Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force | Out-Null
  Write-Host "[install] Created PowerShell profile at $PROFILE" -ForegroundColor Green
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -match [regex]::Escape($sentinel)) {
  Write-Host "[install] morty launcher already present in profile — nothing to do." -ForegroundColor Yellow
  exit 0
}

$block = @"

$sentinel
# Morty launcher — auto-detects Lemonade endpoint and launches Claude Code.
. '$launcherAbs'
# </morty-launcher>
"@

Add-Content -Path $PROFILE -Value $block -Encoding utf8
Write-Host "[install] Added morty() to $PROFILE" -ForegroundColor Green
Write-Host "[install] Reload with: . `$PROFILE" -ForegroundColor Cyan
