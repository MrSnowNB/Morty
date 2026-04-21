# append.ps1 — alias to task-begin's append.ps1 for task-end writes.
# Kept as a separate file per skill folder convention; delegates to the
# shared implementation.

param(
  [Parameter(Mandatory)][string]$TaskId,
  [Parameter(Mandatory)][ValidateSet('task_begin','task_end')][string]$Kind,
  [string]$Summary = "",
  [string]$ExitStatus = "",
  [string]$JournalPath = "$env:MORTY_PROJECT_ROOT\logs\morty-journal.jsonl"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Split-Path $JournalPath))) {
  New-Item -ItemType Directory -Path (Split-Path $JournalPath) -Force | Out-Null
}

$entry = [ordered]@{
  ts         = (Get-Date).ToUniversalTime().ToString("o")
  agent_id   = "morty"
  task_id    = $TaskId
  kind       = $Kind
  summary    = $Summary
}

if ($ExitStatus) {
  $entry["exit_status"] = $ExitStatus
}

$json = $entry | ConvertTo-Json -Compress
Add-Content -Path $JournalPath -Value $json -Encoding utf8

Write-Output "Journal: $Kind written for task_id=$TaskId"
