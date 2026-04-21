# append.ps1 — writes a single journal entry to morty-journal.jsonl
# Used by task-begin and task-end to emit kind:task_begin / kind:task_end
# anchors that chain-miner requires.
#
# Usage:
#   pwsh -File append.ps1 -TaskId <id> -Kind task_begin -Summary "..."
#   pwsh -File append.ps1 -TaskId <id> -Kind task_end   -Summary "success" [-ExitStatus success]

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
