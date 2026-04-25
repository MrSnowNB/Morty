# Test: PreToolUse hook for context window limits

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

Write-Host "=== 1. Low context (<=20% remaining), non-whitelisted tool ===" -ForegroundColor Cyan
$json1 = '{"tool_name": "Read", "args": {}, "context_window": {"total": 200000, "used": 180000, "remaining": 20000, "remaining_pct": 10.0}}'
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "pwsh"
$pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File .claude/hooks/context-monitor.ps1"
$pinfo.RedirectStandardInput = $true
$pinfo.RedirectStandardError = $true
$pinfo.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($pinfo)
$p.StandardInput.WriteLine($json1)
$p.StandardInput.Close()
$p.WaitForExit()
Assert-Equal 1 $p.ExitCode "returns 1 when context is low and tool is not whitelisted"

$errOut = $p.StandardError.ReadToEnd()
$hasMessage = $errOut -match "CONTEXT LOW: Context window usage is at/above 80%"
Assert-Equal $true $hasMessage "prints error message"

Write-Host ""
Write-Host "=== 2. Low context (<=20% remaining), whitelisted tool (Bash) ===" -ForegroundColor Cyan
$json2 = '{"tool_name": "Bash", "args": {}, "context_window": {"total": 200000, "used": 180000, "remaining": 20000, "remaining_pct": 10.0}}'
$pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File .claude/hooks/context-monitor.ps1"
$p = [System.Diagnostics.Process]::Start($pinfo)
$p.StandardInput.WriteLine($json2)
$p.StandardInput.Close()
$p.WaitForExit()
Assert-Equal 0 $p.ExitCode "returns 0 when context is low but tool is whitelisted"

Write-Host ""
Write-Host "=== 3. High context (>20% remaining), non-whitelisted tool ===" -ForegroundColor Cyan
$json3 = '{"tool_name": "Read", "args": {}, "context_window": {"total": 200000, "used": 100000, "remaining": 100000, "remaining_pct": 50.0}}'
$pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File .claude/hooks/context-monitor.ps1"
$p = [System.Diagnostics.Process]::Start($pinfo)
$p.StandardInput.WriteLine($json3)
$p.StandardInput.Close()
$p.WaitForExit()
Assert-Equal 0 $p.ExitCode "returns 0 when context is high"

Write-Host ""
if ($failures.Count -eq 0) {
  Write-Host "All tests passed." -ForegroundColor Green
  [Environment]::Exit(0)
} else {
  Write-Host "$($failures.Count) test(s) failed:" -ForegroundColor Red
  $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  [Environment]::Exit(1)
}
