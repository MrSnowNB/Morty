# PostToolUse hook — append every tool call to the project journal.
# Schema v2: adds task_id, step_idx, exit_status so chain-miner can group
# tool calls into task-bounded sequences and measure outcomes.
# v1 entries (no task_id) remain valid — miner treats them as unbound.
$ErrorActionPreference = "SilentlyContinue"
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $inp = $raw | ConvertFrom-Json } catch { exit 0 }
$projectRoot = $env:MORTY_PROJECT_ROOT
if (-not $projectRoot) { exit 0 }
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$journal = Join-Path $logDir "morty-journal.jsonl"

# --- v2 fields ---------------------------------------------------------------
# task_id: set by /task-begin into $env:MORTY_TASK_ID, cleared by /task-end.
# step_idx: per-task monotonic counter persisted in logs/.step-counter.
# exit_status: ok|error — derived from tool_response.is_error when present.
$taskId = $env:MORTY_TASK_ID

# Fallback: if env var is empty, read the most recent OPEN task_begin from the journal.
# The hook runs as a separate pwsh subprocess that doesn't inherit the agent's
# process env vars, so /task-begin's $env:MORTY_TASK_ID is invisible here.
# The journal is the shared medium — tail 500 is fast enough.
# CRITICAL: walk entries backward and pick the most recent task_begin whose
# task_id has no matching task_end in the tail. A forward walk would pick the
# OLDEST open task and misroute tool_calls when two tasks are open at once.
#
# Why not `(Where-Object {...}).Reverse()`?  PowerShell's .Reverse() is an
# in-place [Array]::Reverse mutator that returns $null, so the subsequent
# foreach would iterate over nothing and the fallback would silently no-op.
# See VALIDATION-GATE-001-REPORT.md Bug 1 — the previous "fix" did not
# actually reverse the collection.
if (-not $taskId) {
  if (Test-Path $journal) {
    $allEntries = @(Get-Content $journal -Tail 500 | ForEach-Object {
      try { $_ | ConvertFrom-Json } catch { $null }
    } | Where-Object { $_ -ne $null })

    # Pre-index closed task_ids for O(n) lookup instead of O(n*m) nested scan.
    $closedTaskIds = @{}
    foreach ($e in $allEntries) {
      if ($e.kind -eq "task_end" -and $e.task_id) {
        $closedTaskIds[$e.task_id] = $true
      }
    }

    # Walk backward — the most recent open task_begin wins.
    for ($i = $allEntries.Count - 1; $i -ge 0; $i--) {
      $e = $allEntries[$i]
      if ($e.kind -ne "task_begin") { continue }
      if (-not $e.task_id) { continue }
      if ($closedTaskIds.ContainsKey($e.task_id)) { continue }
      $taskId = $e.task_id
      break
    }
  }
}
$stepIdx = $null
if ($taskId) {
  $counterFile = Join-Path $logDir ".step-counter"
  $mutexStep = New-Object System.Threading.Mutex($false, "Global\MortyStepCounter")
  try {
    $null = $mutexStep.WaitOne()
    $current = 0
    if (Test-Path $counterFile) {
      $raw2 = Get-Content $counterFile -Raw -ErrorAction SilentlyContinue
      if ($raw2 -match '"task_id"\s*:\s*"([^"]*)"') {
        $storedTask = $matches[1]
        if ($raw2 -match '"step_idx"\s*:\s*(\d+)') { $current = [int]$matches[1] }
        if ($storedTask -ne $taskId) { $current = 0 }
      }
    }
    $stepIdx = $current + 1
    @{ task_id = $taskId; step_idx = $stepIdx } | ConvertTo-Json -Compress | Set-Content -Path $counterFile -Encoding utf8
  } finally {
    $mutexStep.ReleaseMutex()
    $mutexStep.Dispose()
  }
}

$exitStatus = "ok"
if ($inp.tool_response -and $inp.tool_response.is_error) { $exitStatus = "error" }

$summaryRaw = ($inp.tool_input | ConvertTo-Json -Compress -Depth 3)
$summary = if ($summaryRaw.Length -gt 200) { $summaryRaw.Substring(0,200) } else { $summaryRaw }

$entryObj = [ordered]@{
  ts       = (Get-Date).ToUniversalTime().ToString("o")
  agent_id = "morty"
  kind     = "tool_call"
  tool     = $inp.tool_name
  summary  = $summary
  exit_status = $exitStatus
}
if ($taskId)  { $entryObj.task_id  = $taskId }
if ($stepIdx) { $entryObj.step_idx = $stepIdx }
if ($env:MORTY_LORA_MUX) { $entryObj.lora_mux = $env:MORTY_LORA_MUX }

$entry = $entryObj | ConvertTo-Json -Compress
$mutex = New-Object System.Threading.Mutex($false, "Global\MortyJournal")
try {
  $null = $mutex.WaitOne()
  Add-Content -Path $journal -Value $entry -Encoding utf8
} finally {
  $mutex.ReleaseMutex()
  $mutex.Dispose()
}
exit 0
