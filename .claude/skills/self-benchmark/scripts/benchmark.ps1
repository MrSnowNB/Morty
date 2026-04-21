# self-benchmark v1.0 — compute session performance scores from journal
# Usage: pwsh -File benchmark.ps1 [-SessionStart <ISO8601>] [-Tail <N>]
# If SessionStart is omitted, uses the ts of the oldest entry in Tail window.
param(
  [string]$SessionStart = "",
  [int]$Tail = 500,
  [string]$JournalPath = "$env:MORTY_PROJECT_ROOT\logs\morty-journal.jsonl"
)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

if (-not (Test-Path $JournalPath)) {
  Write-Error "Journal not found: $JournalPath"
  exit 1
}

$raw = Get-Content $JournalPath -Tail $Tail
$lines = foreach ($l in $raw) {
  try { $l | ConvertFrom-Json } catch { $null }
} | Where-Object { $_ }

# Determine session start
if ($SessionStart) {
  $startDt = [DateTime]::Parse($SessionStart).ToUniversalTime()
} else {
  $first = $lines | Select-Object -First 1
  $startDt = if ($first) { [DateTime]::Parse($first.ts).ToUniversalTime() } else { [DateTime]::UtcNow.AddHours(-24) }
}

$sessionLines = $lines | Where-Object { [DateTime]::Parse($_.ts).ToUniversalTime() -ge $startDt }

# --- Metric 2: Tool Error Rate ---
$toolCalls = $sessionLines | Where-Object { $_.kind -eq 'tool_call' }
$errorCalls = $toolCalls | Where-Object { $_.exit_status -eq 'error' }
$toolErrorRate = if ($toolCalls.Count -gt 0) { [math]::Round($errorCalls.Count / $toolCalls.Count, 3) } else { 0 }

# --- Metric 3: Task Completion Rate ---
$taskBegins = $sessionLines | Where-Object { $_.kind -eq 'task_begin' }
$taskSuccesses = $sessionLines | Where-Object { $_.kind -eq 'task_end' -and $_.exit_status -eq 'success' }
$completionRate = if ($taskBegins.Count -gt 0) { [math]::Round($taskSuccesses.Count / $taskBegins.Count, 3) } else { 0 }

# --- Metric 4: Chain Yield (raw counts only — miner called separately) ---
$closedTasks = $sessionLines | Where-Object { $_.kind -eq 'task_end' -and $_.exit_status -eq 'success' }

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
