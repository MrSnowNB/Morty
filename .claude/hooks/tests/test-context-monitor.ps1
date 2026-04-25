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
Write-Host "=== 4. Fallback heuristic: large journal ===" -ForegroundColor Cyan
$json4 = '{"tool_name": "Read", "args": {}}'
$dummyLog = "logs/morty-journal.jsonl"
if (-not (Test-Path "logs")) { New-Item -ItemType Directory logs | Out-Null }
$lines = [System.Collections.Generic.List[string]]::new()
for ($i=0; $i -lt 500; $i++) { $lines.Add("{}") }
[System.IO.File]::WriteAllLines($dummyLog, $lines)

$pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File .claude/hooks/context-monitor.ps1"
$pinfo.EnvironmentVariables["MORTY_PROJECT_ROOT"] = (Get-Location).Path
$p = [System.Diagnostics.Process]::Start($pinfo)
$p.StandardInput.WriteLine($json4)
$p.StandardInput.Close()
$p.WaitForExit()
Assert-Equal 1 $p.ExitCode "returns 1 when fallback line-count triggers"
$errOut2 = $p.StandardError.ReadToEnd()
$hasMessage2 = $errOut2 -match "CONTEXT LOW \(Fallback check\)"
Assert-Equal $true $hasMessage2 "prints fallback error message"

Remove-Item $dummyLog -Force

Write-Host ""
Write-Host "=== 5. MORTY_PROJECT_ROOT = '.' resolves journal path correctly ===" -ForegroundColor Cyan
$json5 = '{"tool_name": "Read", "args": {}}'
$dummyLog2 = "logs/morty-journal.jsonl"
# Ensure the dummy journal exists with >400 lines
$lines2 = [System.Collections.Generic.List[string]]::new()
for ($i=0; $i -lt 500; $i++) { $lines2.Add("{}") }
[System.IO.File]::WriteAllLines($dummyLog2, $lines2)

$pinfo5 = New-Object System.Diagnostics.ProcessStartInfo
$pinfo5.FileName = "pwsh"
$pinfo5.Arguments = "-NoProfile -ExecutionPolicy Bypass -File .claude/hooks/context-monitor.ps1"
$pinfo5.RedirectStandardInput = $true
$pinfo5.RedirectStandardError = $true
$pinfo5.UseShellExecute = $false
$pinfo5.EnvironmentVariables["MORTY_PROJECT_ROOT"] = "."
$p5 = [System.Diagnostics.Process]::Start($pinfo5)
$p5.StandardInput.WriteLine($json5)
$p5.StandardInput.Close()
$p5.WaitForExit()
Assert-Equal 1 $p5.ExitCode "returns 1 when MORTY_PROJECT_ROOT='.' resolves journal with >400 lines"
$errOut3 = $p5.StandardError.ReadToEnd()
$hasMessage3 = $errOut3 -match "CONTEXT LOW \(Fallback check\)"
Assert-Equal $true $hasMessage3 "prints fallback error message with resolved '.' path"

Remove-Item $dummyLog2 -Force

Write-Host ""
if ($failures.Count -eq 0) {
  Write-Host "All tests passed." -ForegroundColor Green
  [Environment]::Exit(0)
} else {
  Write-Host "$($failures.Count) test(s) failed:" -ForegroundColor Red
  $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  [Environment]::Exit(1)
}
