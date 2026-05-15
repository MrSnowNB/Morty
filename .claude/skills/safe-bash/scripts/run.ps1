param([Parameter(Mandatory=$true)][string]$Command)
$denyFile = $env:MORTY_DENYLIST
if (-not $denyFile) { $denyFile = "$env:USERPROFILE\.claude\skills\safe-bash\references\denylist.yaml" }
if (-not (Test-Path $denyFile)) { Write-Error "Denylist not found: $denyFile"; exit 10 }
# Bolt optimization: Replaced pipeline operators (| Where-Object, | ForEach-Object)
# with intrinsic array methods (.Where(), .ForEach()).
# Expected performance impact: This eliminates PowerShell's pipeline element-binding
# overhead. It significantly improves execution time when reading larger YAML files,
# ensuring minimal latency in this critical pre-bash hook path.
$fileContent = Get-Content $denyFile
$patterns = if ($fileContent) {
  @(@($fileContent).Where({ $_ -match '^\s*-\s*"(.+)"\s*$' }).ForEach({ ($_ -replace '^\s*-\s*"(.+)"\s*$', '$1') }))
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
