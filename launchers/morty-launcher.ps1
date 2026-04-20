# morty-launcher.ps1
# Defines the morty() function for your PowerShell profile.
# Dot-source this file or let install/add-morty-profile.ps1 do it automatically.
#
# Usage (one-off):  . .\launchers\morty-launcher.ps1 ; morty
# Usage (installed): morty   (from any directory after profile install)

function morty {
  param([Parameter(ValueFromRemainingArguments)]$passThru)

  # Resolve this script's directory so the endpoint probe is always found
  $launchersDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  if (-not $launchersDir) {
    $launchersDir = "$env:USERPROFILE\.local\bin"
  }
  $probeScript = Join-Path $launchersDir "morty-endpoint.ps1"

  if (-not (Test-Path $probeScript)) {
    Write-Host "[morty] ERROR: morty-endpoint.ps1 not found at $probeScript" -ForegroundColor Red
    return
  }

  $endpoint = & $probeScript
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[morty] Lemonade not reachable. Start it and retry." -ForegroundColor Red
    return
  }

  $env:ANTHROPIC_BASE_URL  = $endpoint
  $env:ANTHROPIC_API_KEY   = "lemonade-local"
  $env:ANTHROPIC_MODEL     = "Qwen3-Coder-Next-GGUF"
  $env:MORTY_MODEL         = "Qwen3-Coder-Next-GGUF"
  $env:MORTY_PROJECT_ROOT  = (Get-Location).Path

  Write-Host "[morty] endpoint : $endpoint"                   -ForegroundColor Cyan
  Write-Host "[morty] model    : $env:MORTY_MODEL"            -ForegroundColor Cyan
  Write-Host "[morty] project  : $env:MORTY_PROJECT_ROOT"     -ForegroundColor Cyan

  claude @passThru
}
