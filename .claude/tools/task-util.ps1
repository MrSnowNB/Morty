# task-util.ps1 — Unified task lifecycle management tool.
# Replaces separate task-begin and task-end skill invocations.
#
# Usage:
#   pwsh -NoProfile -Command "& '.claude/tools/task-util.ps1' open <task-id> --summary '<desc>'"
#   pwsh -NoProfile -Command "& '.claude/tools/task-util.ps1' close --status success --summary '<desc>'"
#   pwsh -NoProfile -Command "& '.claude/tools/task-util.ps1' list"
#   pwsh -NoProfile -Command "& '.claude/tools/task-util.ps1' status <task-id>"
#
# Output: JSON to stdout
# Journal: logs/morty-journal.jsonl (appends task_begin/task_end anchors)

param(
  [Parameter(Position=0)]
  [ValidateSet("open", "close", "list", "status")]
  [string]$Action,

  [string]$TaskId,

  [string]$Summary,

  [ValidateSet("success", "partial", "fail", "skip")]
  [string]$Status = "success"
)

$ErrorActionPreference = "Stop"

$projectRoot = $env:MORTY_PROJECT_ROOT
if (-not $projectRoot) {
    Write-Output (@{ error = "MORTY_PROJECT_ROOT not set" } | ConvertTo-Json)
    exit 1
}

$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$journal = Join-Path $logDir "morty-journal.jsonl"
$counterFile = Join-Path $logDir ".step-counter"

function Get-StepIdx {
    param([string]$CurrentTaskId)
    $mutexStep = New-Object System.Threading.Mutex($false, "Global\MortyStepCounter")
    try {
        $null = $mutexStep.WaitOne()
        $current = 0
        if (Test-Path $counterFile) {
            $raw = Get-Content $counterFile -Raw -ErrorAction SilentlyContinue
            if ($raw -match '"task_id"\s*:\s*"([^"]*)"') {
                $storedTask = $matches[1]
                if ($raw -match '"step_idx"\s*:\s*(\d+)') { $current = [int]$matches[1] }
                if ($storedTask -ne $CurrentTaskId) { $current = 0 }
            }
        }
        $stepIdx = $current + 1
        @{ task_id = $CurrentTaskId; step_idx = $stepIdx } | ConvertTo-Json -Compress | Set-Content -Path $counterFile -Encoding utf8
        return $stepIdx
    } finally {
        $mutexStep.ReleaseMutex()
        $mutexStep.Dispose()
    }
}

function Write-JournalEntry {
    param([hashtable]$Entry)
    $mutex = New-Object System.Threading.Mutex($false, "Global\MortyJournal")
    try {
        $null = $mutex.WaitOne()
        $entry | ConvertTo-Json -Compress | Add-Content -Path $journal -Encoding utf8
    } finally {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}

function Get-LastTaskBegin {
    if (-not (Test-Path $journal)) { return $null }
    $entries = Get-Content $journal -Tail 500 | ConvertFrom-Json
    $taskBegins = $entries | Where-Object { $_ -and $_.kind -eq "task_begin" }
    # Return the most recent task_begin that doesn't have a matching task_end after it
    foreach ($begin in $taskBegins) {
        $hasEnd = $false
        foreach ($e in $entries) {
            if ($e.kind -eq "task_end" -and $e.task_id -eq $begin.task_id) {
                $hasEnd = $true
                break
            }
        }
        if (-not $hasEnd) { return $begin }
    }
    return $null
}

# --- Main ---
switch ($Action) {
    "open" {
        if (-not $TaskId) {
            Write-Output (@{ error = "open requires --task-id" } | ConvertTo-Json)
            exit 1
        }
        if (-not $Summary) { $Summary = "Task: $TaskId" }

        # Check if task is already open
        $lastBegin = Get-LastTaskBegin
        if ($lastBegin -and $lastBegin.task_id -eq $TaskId) {
            Write-Output (@{ status = "already_open"; task_id = $TaskId } | ConvertTo-Json)
            exit 0
        }

        $stepIdx = Get-StepIdx $TaskId
        $ts = (Get-Date).ToUniversalTime().ToString("o")

        $entryObj = [ordered]@{
            ts = $ts
            agent_id = "morty"
            task_id = $TaskId
            kind = "task_begin"
            summary = $Summary
            step_idx = $stepIdx
        }
        Write-JournalEntry $entryObj

        # Set env var for subsequent tool calls
        $env:MORTY_TASK_ID = $TaskId

        Write-Output (@{
            status = "opened"
            task_id = $TaskId
            summary = $Summary
            ts = $ts
            step_idx = $stepIdx
        } | ConvertTo-Json)
    }

    "close" {
        if (-not $TaskId) {
            # Try to get current task from env or journal
            $TaskId = $env:MORTY_TASK_ID
            if (-not $TaskId) {
                $lastBegin = Get-LastTaskBegin
                if ($lastBegin) { $TaskId = $lastBegin.task_id }
            }
        }

        if (-not $TaskId) {
            Write-Output (@{ error = "No open task to close" } | ConvertTo-Json)
            exit 1
        }

        if (-not $Summary) { $Summary = "Closed: $TaskId" }

        $stepIdx = Get-StepIdx $TaskId
        $ts = (Get-Date).ToUniversalTime().ToString("o")

        $entryObj = [ordered]@{
            ts = $ts
            agent_id = "morty"
            task_id = $TaskId
            kind = "task_end"
            summary = $Summary
            exit_status = $Status
            step_idx = $stepIdx
        }
        Write-JournalEntry $entryObj

        # Clear env var
        $env:MORTY_TASK_ID = $null

        Write-Output (@{
            status = "closed"
            task_id = $TaskId
            exit_status = $Status
            ts = $ts
        } | ConvertTo-Json)
    }

    "list" {
        $entries = @()
        if (Test-Path $journal) {
            $allEntries = Get-Content $journal -Tail 500 | ConvertFrom-Json
            $taskBegins = $allEntries | Where-Object { $_ -and $_.kind -eq "task_begin" }
            $taskEnds = $allEntries | Where-Object { $_ -and $_.kind -eq "task_end" }

            foreach ($begin in $taskBegins) {
                $hasEnd = $false
                foreach ($e in $taskEnds) {
                    if ($e.task_id -eq $begin.task_id) {
                        $hasEnd = $true
                        break
                    }
                }
                if (-not $hasEnd) {
                    $entries += @{
                        task_id = $begin.task_id
                        summary = $begin.summary
                        ts = $begin.ts
                    }
                }
            }
        }

        Write-Output (@{ open_tasks = $entries; count = $entries.Count } | ConvertTo-Json)
    }

    "status" {
        if (-not $TaskId) {
            Write-Output (@{ error = "status requires --task-id" } | ConvertTo-Json)
            exit 1
        }

        if (-not (Test-Path $journal)) {
            Write-Output (@{ task_id = $TaskId; status = "not_found" } | ConvertTo-Json)
            exit 0
        }

        $allEntries = Get-Content $journal -Tail 1000 | ConvertFrom-Json
        $begin = $allEntries | Where-Object { $_ -and $_.kind -eq "task_begin" -and $_.task_id -eq $TaskId } | Select-Object -Last 1
        $end = $allEntries | Where-Object { $_ -and $_.kind -eq "task_end" -and $_.task_id -eq $TaskId } | Select-Object -Last 1

        if (-not $begin) {
            Write-Output (@{ task_id = $TaskId; status = "not_found" } | ConvertTo-Json)
        } elseif ($end) {
            Write-Output (@{
                task_id = $TaskId
                status = "closed"
                begin_ts = $begin.ts
                end_ts = $end.ts
                exit_status = $end.exit_status
            } | ConvertTo-Json)
        } else {
            Write-Output (@{
                task_id = $TaskId
                status = "open"
                begin_ts = $begin.ts
            } | ConvertTo-Json)
        }
    }

    default {
        Write-Output (@{ error = "Unknown action: $Action" } | ConvertTo-Json)
        exit 1
    }
}

exit 0
