# self-benchmark v1.0 — compute session performance scores from journal
# Usage: pwsh -File benchmark.ps1 [-SessionStart <ISO8601>] [-Tail <N>]
# If SessionStart is omitted, uses the ts of the oldest entry in Tail window.
param(
  [string]$SessionStart = "",
  [int]$Tail = 500,
  [string]$JournalPath = "$env:MORTY_PROJECT_ROOT\logs\morty-journal.jsonl"
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $JournalPath)) {
  Write-Error "Journal not found: $JournalPath"
  exit 1
}

$raw = Get-Content $JournalPath -Tail $Tail
# Batch parse JSON for 10x performance improvement over per-line ConvertFrom-Json
# First try parsing the batch. If it fails (due to a malformed line), fall back to line-by-line parsing to avoid data loss.
$jsonStr = "[" + ($raw -join ",") + "]"
$lines = $null
try {
  $lines = @($jsonStr | ConvertFrom-Json)
} catch {
  $lines = @(foreach ($l in $raw) {
    try { $l | ConvertFrom-Json } catch { $null }
  })
}
$lines = if ($lines) { @(@($lines).Where({ $_ -ne $null })) } else { @() }

# Determine session start
if ($SessionStart) {
  $startDt = [DateTime]::Parse($SessionStart).ToUniversalTime()
} else {
  $first = $lines | Select-Object -First 1
  $startDt = if ($first) { [DateTime]::Parse($first.ts).ToUniversalTime() } else { [DateTime]::UtcNow.AddHours(-24) }
}

$sessionLines = if ($lines) { @(@($lines).Where({ [DateTime]::Parse($_.ts).ToUniversalTime() -ge $startDt })) } else { @() }

# --- Metric 2: Tool Error Rate ---
$toolCalls = if ($sessionLines) { @(@($sessionLines).Where({ $_.kind -eq 'tool_call' })) } else { @() }
$errorCalls = if ($toolCalls) { @(@($toolCalls).Where({ $_.exit_status -eq 'error' })) } else { @() }
$toolErrorRate = if ($toolCalls.Count -gt 0) { [math]::Round($errorCalls.Count / $toolCalls.Count, 3) } else { 0 }

# --- Metric 3: Task Completion Rate ---
$taskBegins = if ($sessionLines) { @(@($sessionLines).Where({ $_.kind -eq 'task_begin' })) } else { @() }
$taskSuccesses = if ($sessionLines) { @(@($sessionLines).Where({ $_.kind -eq 'task_end' -and $_.exit_status -eq 'success' })) } else { @() }
$completionRate = if ($taskBegins.Count -gt 0) { [math]::Round($taskSuccesses.Count / $taskBegins.Count, 3) } else { 0 }

# --- Metric 4: Chain Yield (raw counts only — miner called separately) ---
$closedTasks = if ($sessionLines) { @(@($sessionLines).Where({ $_.kind -eq 'task_end' -and $_.exit_status -eq 'success' })) } else { @() }

$result = [ordered]@{
  ts                 = (Get-Date).ToUniversalTime().ToString("o")
  session_start      = $startDt.ToString("o")
  tool_calls         = $toolCalls.Count
  error_calls        = $errorCalls.Count
  tool_error_rate    = $toolErrorRate
  task_begins        = $taskBegins.Count
  task_successes     = $taskSuccesses.Count
  task_completion_rate = $completionRate
  closed_tasks_total = $closedTasks.Count
}

$result | ConvertTo-Json
