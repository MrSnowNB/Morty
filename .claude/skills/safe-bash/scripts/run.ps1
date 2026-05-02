param([Parameter(Mandatory=$true)][string]$Command)
$denyFile = $env:MORTY_DENYLIST
if (-not $denyFile) { $denyFile = "$env:USERPROFILE\.claude\skills\safe-bash\references\denylist.yaml" }
if (-not (Test-Path $denyFile)) { Write-Error "Denylist not found: $denyFile"; exit 10 }
# Bolt optimization: Use native array methods (.Where, .ForEach) instead of pipeline
# overhead for performance. Wrapped in if/else to safely handle empty collections.
$lines = Get-Content $denyFile
$patterns = if ($lines) {
  @(@($lines).Where({ $_ -match '^\s*-\s*"(.+)"\s*$' }).ForEach({ ($_ -replace '^\s*-\s*"(.+)"\s*$', '$1') }))
} else {
  @()
}
foreach ($p in $patterns) {
  if ($Command -imatch $p) {
    Write-Error "DENIED by pattern: $p"
    exit 20
  }
}
& pwsh -NoProfile -Command $Command
exit $LASTEXITCODE
