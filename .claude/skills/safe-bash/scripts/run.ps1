param([Parameter(Mandatory=$true)][string]$Command)
$denyFile = $env:MORTY_DENYLIST
if (-not $denyFile) { $denyFile = "$env:USERPROFILE\.claude\skills\safe-bash\references\denylist.yaml" }
if (-not (Test-Path $denyFile)) { Write-Error "Denylist not found: $denyFile"; exit 10 }
$patterns = Get-Content $denyFile |
  Where-Object { $_ -match '^\s*-\s*"(.+)"\s*$' } |
  ForEach-Object { ($_ -replace '^\s*-\s*"(.+)"\s*$', '$1') }
foreach ($p in $patterns) {
  if ($Command -imatch $p) {
    Write-Error "DENIED by pattern: $p"
    exit 20
  }
}
& pwsh -NoProfile -Command $Command
exit $LASTEXITCODE
