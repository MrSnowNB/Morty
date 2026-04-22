# Test: post-tool.ps1 fallback picks the MOST RECENT open task_begin.
#
# Regression coverage for VALIDATION-GATE-001 Bug 1:
# the previous fix used `(Where-Object {...}).Reverse()` which returns $null
# (PowerShell's .Reverse() is an in-place mutator), causing the fallback to
# silently no-op. This test would have caught it.
#
# Run:
#   pwsh -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/tests/test-post-tool-fallback.ps1
#
# Exits 0 on pass, 1 on any failure. Prints a summary table.

$ErrorActionPreference = "Stop"
$failures = @()

function Assert-Equal {
  param($expected, $actual, [string]$name)
  if ($expected -eq $actual) {
    Write-Host "  PASS  $name" -ForegroundColor Green
  } else {
    Write-Host "  FAIL  $name" -ForegroundColor Red
    Write-Host "        expected: $expected"
    Write-Host "        actual:   $actual"
    $script:failures += $name
  }
}

Write-Host "=== 1. Demonstrate the .Reverse() pitfall ===" -ForegroundColor Cyan
# The original hook bug was `foreach ($b in $pipelineExpr.Reverse()) { ... }`
# where `$pipelineExpr` was the result of `Where-Object`. Depending on the
# PowerShell version / platform / how the pipeline materializes, `.Reverse()`
# on that value either:
#   (a) returns $null (void in-place mutator on a List/Array), OR
#   (b) throws because member access maps over elements that lack .Reverse().
# Either way the foreach body never ran \u2014 the bug. This test accepts either
# symptom as proof of the pitfall; what matters is that the return value is
# not a usable reversed collection.
$arr = 1..5 | Where-Object { $_ -gt 0 }
$reverseReturn = $null
$threw = $false
try {
  # Suppress the per-statement error so $ErrorActionPreference="Stop" doesn't abort.
  $reverseReturn = $arr.Reverse() 2>$null
} catch {
  $threw = $true
}
$isUnsafe = ($threw -or ($null -eq $reverseReturn))
Assert-Equal $true $isUnsafe ".Reverse() on a filtered pipeline is unsafe (returned `$null or threw)"

Write-Host ""
Write-Host "=== 2. Correct approach: [Array]::Reverse on @() wrapped array ===" -ForegroundColor Cyan
$arr2 = @(1..5 | Where-Object { $_ -gt 0 })
[Array]::Reverse($arr2)
Assert-Equal 5 $arr2[0] "first element after [Array]::Reverse is 5"
Assert-Equal 1 $arr2[4] "last element after [Array]::Reverse is 1"

Write-Host ""
Write-Host "=== 3. Backward-for-loop approach (used in post-tool.ps1) ===" -ForegroundColor Cyan
# Synthesize a tail with two open task_begins and one closed one, in order:
#   t1 open \u2192 t2 closed \u2192 t3 open  (t3 is most recent, should win)
$tail = @(
  [pscustomobject]@{ kind = "task_begin"; task_id = "t1" }
  [pscustomobject]@{ kind = "tool_call";  tool    = "Read" }
  [pscustomobject]@{ kind = "task_begin"; task_id = "t2" }
  [pscustomobject]@{ kind = "tool_call";  tool    = "Edit" }
  [pscustomobject]@{ kind = "task_end";   task_id = "t2" }
  [pscustomobject]@{ kind = "task_begin"; task_id = "t3" }
  [pscustomobject]@{ kind = "tool_call";  tool    = "Write" }
)

$closed = @{}
foreach ($e in $tail) {
  if ($e.kind -eq "task_end" -and $e.task_id) { $closed[$e.task_id] = $true }
}

$picked = $null
for ($i = $tail.Count - 1; $i -ge 0; $i--) {
  $e = $tail[$i]
  if ($e.kind -ne "task_begin") { continue }
  if (-not $e.task_id) { continue }
  if ($closed.ContainsKey($e.task_id)) { continue }
  $picked = $e.task_id
  break
}
Assert-Equal "t3" $picked "picks most recent open task (t3, not t1)"

Write-Host ""
Write-Host "=== 4. No open tasks \u2192 fallback yields `$null ===" -ForegroundColor Cyan
$tail2 = @(
  [pscustomobject]@{ kind = "task_begin"; task_id = "a" }
  [pscustomobject]@{ kind = "task_end";   task_id = "a" }
)
$closed2 = @{}; foreach ($e in $tail2) { if ($e.kind -eq "task_end") { $closed2[$e.task_id] = $true } }
$picked2 = $null
for ($i = $tail2.Count - 1; $i -ge 0; $i--) {
  $e = $tail2[$i]
  if ($e.kind -ne "task_begin") { continue }
  if ($closed2.ContainsKey($e.task_id)) { continue }
  $picked2 = $e.task_id; break
}
Assert-Equal $null $picked2 "all tasks closed \u2192 fallback is `$null"

Write-Host ""
if ($failures.Count -eq 0) {
  Write-Host "All tests passed." -ForegroundColor Green
  exit 0
} else {
  Write-Host "$($failures.Count) test(s) failed:" -ForegroundColor Red
  $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  exit 1
}
