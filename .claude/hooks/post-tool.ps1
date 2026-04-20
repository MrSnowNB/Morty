# PostToolUse hook — append every tool call to the project journal.
$ErrorActionPreference = "SilentlyContinue"
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $inp = $raw | ConvertFrom-Json } catch { exit 0 }
$projectRoot = $env:MORTY_PROJECT_ROOT
if (-not $projectRoot) { exit 0 }
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$journal = Join-Path $logDir "morty-journal.jsonl"
$summaryRaw = ($inp.tool_input | ConvertTo-Json -Compress -Depth 3)
$summary = if ($summaryRaw.Length -gt 200) { $summaryRaw.Substring(0,200) } else { $summaryRaw }
$entry = @{
  ts       = (Get-Date).ToUniversalTime().ToString("o")
  agent_id = "morty"
  kind     = "tool_call"
  tool     = $inp.tool_name
  summary  = $summary
} | ConvertTo-Json -Compress
$mutex = New-Object System.Threading.Mutex($false, "Global\MortyJournal")
try {
  $null = $mutex.WaitOne()
  Add-Content -Path $journal -Value $entry -Encoding utf8
} finally {
  $mutex.ReleaseMutex()
  $mutex.Dispose()
}
exit 0
