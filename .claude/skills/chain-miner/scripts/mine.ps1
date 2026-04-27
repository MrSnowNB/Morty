# mine.ps1 — read-only chain miner for Morty's journal.
# Reads logs/morty-journal.jsonl (tail-bounded), groups tool_call entries
# by task_id using task_begin/task_end boundaries, normalizes arguments,
# hashes each chain, aggregates counts and success rates, and writes a
# JSON report to stdout.
#
# Usage:
#   pwsh -File mine.ps1 [-Tail 2000] [-MinCount 2] [-MinSuccessRate 1.0]
#
# Never writes to .claude/. Output goes to stdout; the chain-miner SKILL is
# responsible for appending the report to SCRATCH.md.

param(
  [int]$Tail = 2000,
  [int]$MinCount = 2,
  [double]$MinSuccessRate = 1.0,
  [string]$JournalPath = "$env:MORTY_PROJECT_ROOT\logs\morty-journal.jsonl"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $JournalPath)) {
  Write-Output (@{ error = "journal not found"; path = $JournalPath } | ConvertTo-Json -Compress)
  exit 1
}

# --- Read tail (bounded — never full file) -----------------------------------
$lines = Get-Content -Path $JournalPath -Tail $Tail -Encoding utf8

# --- Parse entries -----------------------------------------------------------
# Batch parse JSON for 10x performance improvement over per-line ConvertFrom-Json
# First try parsing the batch. If it fails (due to a malformed line), fall back to line-by-line parsing to avoid data loss.
$jsonStr = "[" + ($lines -join ",") + "]"
$entries = $null
try {
  $entries = @($jsonStr | ConvertFrom-Json)
} catch {
  $entries = @(foreach ($line in $lines) {
    try { $line | ConvertFrom-Json } catch { $null }
  })
}
$entries = if ($entries) { @(@($entries).Where({ $_ -ne $null })) } else { @() }

# --- Normalize an argument string into an arg_shape --------------------------
function Get-ArgShape {
  param([string]$s)
  if (-not $s) { return "" }
  $t = $s
  # Strip common project paths
  $t = $t -replace '[A-Za-z]:\\\\[^"]*', '<path>'
  $t = $t -replace '/[A-Za-z0-9_\-./]+\.[A-Za-z0-9]+', '<path>'
  # Strip SHAs and long hex
  $t = $t -replace '\b[0-9a-f]{7,40}\b', '<sha>'
  # Strip ISO timestamps
  $t = $t -replace '\d{4}-\d{2}-\d{2}T[\d:.Z+\-]+', '<ts>'
  # Keep only the first 80 chars of the normalized form
  if ($t.Length -gt 80) { $t = $t.Substring(0, 80) }
  return $t
}

# --- Build task boundaries from task_begin/task_end entries ------------------
# This handles the case where agent-injected task_id differs from journal task_id
# (e.g. when agent runs inside a different task boundary).

# Collect all boundary entries
$boundaries = if ($entries) { @(@($entries).Where({
  $_ -and ($_.kind -eq "task_begin" -or $_.kind -eq "task_end")
})) } else { @() }

# Build a map: task_id → { begin_ts, end_ts, outcome }
$boundaryMap = @{}
foreach ($b in $boundaries) {
  if ($b.kind -eq "task_begin") {
    $boundaryMap[$b.task_id] = @{ begin_ts = [datetime]$b.ts; end_ts = $null; outcome = $null }
  }
  elseif ($b.kind -eq "task_end") {
    if ($boundaryMap.ContainsKey($b.task_id)) {
      $boundaryMap[$b.task_id].end_ts = [datetime]$b.ts
      $s = [string]$b.summary
      if     ($s -match '^success') { $boundaryMap[$b.task_id].outcome = "success" }
      elseif ($s -match '^partial') { $boundaryMap[$b.task_id].outcome = "partial" }
      elseif ($s -match '^fail')    { $boundaryMap[$b.task_id].outcome = "fail" }
    }
  }
}

# --- Group by task_id --------------------------------------------------------
$tasks = @{}

foreach ($e in $entries) {
  if ($e.kind -ne "tool_call") { continue }
  if (-not $e.task_id) { continue }                 # skip v1 entries
  if ($e.task_id -like "skill:chain-miner*") { continue }  # anti-recursion

  # Skip boundary-management tools — they pollute chain signatures
  $toolName = [string]$e.tool
  if ($toolName -in @('task-util', 'Skill', 'TaskCreate', 'TaskUpdate')) { continue }

  # Primary path: trust the tool_call's task_id. Post-B1 the hook fallback
  # sets task_id correctly, so the boundary map lookup is O(1) and exact.
  $tid = $null
  if ($boundaryMap.ContainsKey($e.task_id)) {
    $tid = $e.task_id
  } else {
    # Legacy fallback: tool_call has a task_id but no matching boundary
    # (e.g. boundaries aged out of the -Tail window, or pre-B1 entries where
    # the hook wrote the wrong task_id). Fall back to timestamp containment
    # over closed boundaries only.
    $toolTs = [datetime]$e.ts
    foreach ($bid in $boundaryMap.Keys) {
      $bd = $boundaryMap[$bid]
      if ($bd.begin_ts -and $bd.end_ts -and
          $toolTs -ge $bd.begin_ts -and $toolTs -le $bd.end_ts) {
        $tid = $bid
        break
      }
    }
  }

  if (-not $tid) { continue }  # no matching boundary, skip this tool_call

  if (-not $tasks.ContainsKey($tid)) {
    $tasks[$tid] = [ordered]@{
      steps   = [System.Collections.Generic.List[object]]::new()
      outcome = $null
    }
  }

  $shape = Get-ArgShape ([string]$e.summary)
  $tasks[$tid].steps.Add([ordered]@{
    tool      = [string]$e.tool
    arg_shape = $shape
    exit_status = if ($e.exit_status) { [string]$e.exit_status } else { "ok" }
  })

  # Also inherit outcome from the boundary
  if ($boundaryMap.ContainsKey($tid) -and $boundaryMap[$tid].outcome) {
    $tasks[$tid].outcome = $boundaryMap[$tid].outcome
  }
}

# --- Hash each task's tool sequence and aggregate ----------------------------
function Get-Sha8 {
  param([string]$s)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  $hash  = $sha.ComputeHash($bytes)
  return [BitConverter]::ToString($hash).Replace("-", "").ToLowerInvariant().Substring(0, 8)
}

$agg = @{}
foreach ($tid in $tasks.Keys) {
  $t = $tasks[$tid]
  if ($t.steps.Count -eq 0) { continue }
  if (-not $t.outcome)       { continue }  # unclosed task, skip

  $seqString = ($t.steps.ForEach({ "$($_.tool):$($_.arg_shape)" })) -join " | "
  $sig = Get-Sha8 $seqString

  if (-not $agg.ContainsKey($sig)) {
    $agg[$sig] = [ordered]@{
      signature              = $sig
      steps                  = $t.steps
      count                  = 0
      success_count          = 0
      fail_count             = 0
      partial_count          = 0
      total_step_count       = 0
      sample_task_ids        = [System.Collections.Generic.List[string]]::new()
      representative_summary = ($t.steps.ForEach({ $_.tool })) -join " → "
    }
  }

  $agg[$sig].count++
  $agg[$sig].total_step_count += $t.steps.Count
  if ($t.outcome -eq "success") { $agg[$sig].success_count++ }
  elseif ($t.outcome -eq "fail") { $agg[$sig].fail_count++ }
  elseif ($t.outcome -eq "partial") { $agg[$sig].partial_count++ }

  if ($agg[$sig].sample_task_ids.Count -lt 5) {
    $agg[$sig].sample_task_ids.Add($tid)
  }
}

# --- Filter by threshold and emit --------------------------------------------
$candidates = foreach ($sig in $agg.Keys) {
  $c = $agg[$sig]
  $rate = if ($c.count -gt 0) { [math]::Round($c.success_count / $c.count, 3) } else { 0 }
  $avg  = if ($c.count -gt 0) { [math]::Round($c.total_step_count / $c.count, 2) } else { 0 }

  if ($c.count -ge $MinCount -and $rate -ge $MinSuccessRate) {
    [ordered]@{
      signature              = $c.signature
      steps                  = $c.steps
      count                  = $c.count
      success_count          = $c.success_count
      fail_count             = $c.fail_count
      success_rate           = $rate
      avg_steps              = $avg
      sample_task_ids        = $c.sample_task_ids
      representative_summary = $c.representative_summary
    }
  }
}

$candidatesSorted = $candidates | Sort-Object -Property @{Expression={$_.count * $_.success_rate}; Descending=$true}

$report = [ordered]@{
  ts              = (Get-Date).ToUniversalTime().ToString("o")
  journal_path    = $JournalPath
  tail_lines      = $Tail
  tasks_seen      = $tasks.Count
  tasks_closed    = ($tasks.Values.Where({ $_.outcome })).Count
  min_count       = $MinCount
  min_success_rate = $MinSuccessRate
  candidates      = @($candidatesSorted)
}

$report | ConvertTo-Json -Depth 6
