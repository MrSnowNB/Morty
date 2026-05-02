# PreToolUse hook — enforces the denylist before any Bash tool call.
# Claude Code passes tool input on stdin as JSON.
$ErrorActionPreference = "Stop"
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $inp = $raw | ConvertFrom-Json } catch { exit 0 }
$cmd = $inp.tool_input.command
if (-not $cmd) { exit 0 }
$denyFile = $env:MORTY_DENYLIST
if (-not $denyFile) { $denyFile = "$env:USERPROFILE\.claude\skills\safe-bash\references\denylist.yaml" }
if (-not (Test-Path $denyFile)) { exit 0 }
# Bolt optimization: Use native array methods (.Where, .ForEach) instead of pipeline
# overhead for performance. Wrapped in if/else to safely handle empty collections.
$lines = Get-Content $denyFile
$patterns = if ($lines) {
  @(@($lines).Where({ $_ -match '^\s*-\s*"(.+)"\s*$' }).ForEach({ ($_ -replace '^\s*-\s*"(.+)"\s*$', '$1') }))
} else {
  @()
}
foreach ($p in $patterns) {
  if ($cmd -imatch $p) {
    Write-Output (@{ decision = "block"; reason = "Morty denylist matched pattern: $p" } | ConvertTo-Json -Compress)
    exit 0
  }
}
exit 0
