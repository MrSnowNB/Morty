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
$json1 = '{"tool_name": "Glob", "args": {}, "context_window": {"total": 200000, "used": 180000, "remaining": 20000, "remaining_pct": 10.0}}'
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
$json3 = '{"tool_name": "Glob", "args": {}, "context_window": {"total": 200000, "used": 100000, "remaining": 100000, "remaining_pct": 50.0}}'
$pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File .claude/hooks/context-monitor.ps1"
$p = [System.Diagnostics.Process]::Start($pinfo)
$p.StandardInput.WriteLine($json3)
$p.StandardInput.Close()
$p.WaitForExit()
Assert-Equal 0 $p.ExitCode "returns 0 when context is high"

$tempPath = [System.IO.Path]::GetTempPath()
$testRoot = Join-Path $tempPath "morty-test-$([guid]::NewGuid().ToString().Substring(0,8))"
$testLogDir = Join-Path $testRoot "logs"
$dummyLog = Join-Path $testLogDir "morty-journal.jsonl"
New-Item -ItemType Directory $testLogDir -Force | Out-Null
$lines = [System.Collections.Generic.List[string]]::new()
for ($i=0; $i -lt 500; $i++) { $lines.Add("{}") }
[System.IO.File]::WriteAllLines($dummyLog, $lines)

Write-Host ""
Write-Host "=== 4. Fallback heuristic: large journal ===" -ForegroundColor Cyan
$json4 = '{"tool_name": "Glob", "args": {}}'

$pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File .claude/hooks/context-monitor.ps1"
$pinfo.EnvironmentVariables["MORTY_PROJECT_ROOT"] = $testRoot
$p = [System.Diagnostics.Process]::Start($pinfo)
$p.StandardInput.WriteLine($json4)
$p.StandardInput.Close()
$p.WaitForExit()
Assert-Equal 1 $p.ExitCode "returns 1 when fallback line-count triggers"
$errOut2 = $p.StandardError.ReadToEnd()
$hasMessage2 = $errOut2 -match "CONTEXT LOW \(Fallback check\)"
Assert-Equal $true $hasMessage2 "prints fallback error message"

Write-Host ""
Write-Host "=== 5. Fallback heuristic with MORTY_PROJECT_ROOT='.' ===" -ForegroundColor Cyan
$json5 = '{"tool_name": "Glob", "args": {}}'

# We must CD to the temp dir to test the relative path '.' correctly
$originalPath = (Get-Location).Path
Set-Location $testRoot
$pinfo2 = New-Object System.Diagnostics.ProcessStartInfo
# Need absolute path to hook script since we moved directories
$hookPath = Join-Path $originalPath ".claude/hooks/context-monitor.ps1"
$pinfo2.FileName = "pwsh"
$pinfo2.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$hookPath`""
$pinfo2.RedirectStandardInput = $true
$pinfo2.RedirectStandardError = $true
$pinfo2.UseShellExecute = $false
$pinfo2.EnvironmentVariables["MORTY_PROJECT_ROOT"] = "."

$p2 = [System.Diagnostics.Process]::Start($pinfo2)
$p2.StandardInput.WriteLine($json5)
$p2.StandardInput.Close()
$p2.WaitForExit()
Assert-Equal 1 $p2.ExitCode "returns 1 when fallback line-count triggers with relative path"
$errOut3 = $p2.StandardError.ReadToEnd()
$hasMessage3 = $errOut3 -match "CONTEXT LOW \(Fallback check\)"
Assert-Equal $true $hasMessage3 "prints fallback error message with relative path"

Set-Location $originalPath
Remove-Item $testRoot -Recurse -Force

Write-Host ""
if ($failures.Count -eq 0) {
  Write-Host "All tests passed." -ForegroundColor Green
  [Environment]::Exit(0)
} else {
  Write-Host "$($failures.Count) test(s) failed:" -ForegroundColor Red
  $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  [Environment]::Exit(1)
}
