# Test: .claude/hooks/boot-validation.ps1
#
# Cross-platform regression coverage for the boot-loop self-check.
# Each subtest materializes a synthetic project root + settings.json,
# runs boot-validation.ps1 against it, and asserts the expected
# failure/warning set appears.
#
# Run:
#   pwsh -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/tests/test-boot-validation.ps1

$ErrorActionPreference = 'Stop'

# Locate the script under test. Supports running from repo root or from tests dir.
$repoRoot = $PSScriptRoot
while ($repoRoot -and -not (Test-Path (Join-Path $repoRoot '.claude/hooks/boot-validation.ps1'))) {
    $parent = Split-Path -Parent $repoRoot
    if (-not $parent -or $parent -eq $repoRoot) { break }
    $repoRoot = $parent
}
$validator = Join-Path $repoRoot '.claude/hooks/boot-validation.ps1'
if (-not (Test-Path $validator)) {
    Write-Host "FAIL: cannot locate boot-validation.ps1 from $PSScriptRoot" -ForegroundColor Red
    exit 1
}

$failures = @()

function New-Fixture {
    param([hashtable]$Settings, [switch]$CreateLogs, [switch]$CreateBrokenPlaceholder, [switch]$CreateSkills)
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("morty-bv-" + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    if ($CreateLogs) { New-Item -ItemType Directory -Path (Join-Path $root 'logs') -Force | Out-Null }
    if ($CreateBrokenPlaceholder) {
        $bad = Join-Path $root '${CLAUDE_PROJECT_DIR}/logs'
        New-Item -ItemType Directory -Path $bad -Force | Out-Null
    }
    if ($CreateSkills) {
        foreach ($s in 'first-principles','journal-anchor','safe-bash','checkpoint-writer') {
            $sd = Join-Path $root ".claude/skills/$s"
            New-Item -ItemType Directory -Path $sd -Force | Out-Null
            Set-Content -Path (Join-Path $sd 'SKILL.md') -Value "---`nname: $s`n---`n"
        }
    }
    $settingsPath = Join-Path $root 'settings.json'
    if ($Settings) {
        ($Settings | ConvertTo-Json -Depth 10) | Set-Content -Path $settingsPath
    }
    return @{ Root = $root; Settings = $settingsPath }
}

function Invoke-Validator {
    param([string]$Root, [string]$SettingsPath, [hashtable]$EnvOverrides = @{})
    # Save current env and override
    $saved = @{}
    foreach ($k in @('CLAUDE_PROJECT_DIR','MORTY_MODEL')) { $saved[$k] = [Environment]::GetEnvironmentVariable($k) }
    foreach ($k in $EnvOverrides.Keys) { [Environment]::SetEnvironmentVariable($k, $EnvOverrides[$k]) }
    try {
        $out = & pwsh -NoProfile -File $validator -ProjectRoot $Root -SettingsPath $SettingsPath -Json 2>&1 | Out-String
        $exit = $LASTEXITCODE
        return @{ Output = $out; ExitCode = $exit }
    }
    finally {
        foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
    }
}

function Assert-Contains {
    param([string]$Haystack, [string]$Needle, [string]$TestName)
    if ($Haystack -like "*$Needle*") {
        Write-Host "  PASS  $TestName" -ForegroundColor Green
    } else {
        Write-Host "  FAIL  $TestName" -ForegroundColor Red
        Write-Host "        expected substring: $Needle"
        $script:failures += $TestName
    }
}

function Assert-ExitCode {
    param([int]$Expected, [int]$Actual, [string]$TestName)
    if ($Expected -eq $Actual) {
        Write-Host "  PASS  $TestName" -ForegroundColor Green
    } else {
        Write-Host "  FAIL  $TestName (expected exit $Expected, got $Actual)" -ForegroundColor Red
        $script:failures += $TestName
    }
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== 1. All-green fixture ===" -ForegroundColor Cyan
$f = New-Fixture -CreateLogs -CreateSkills -Settings @{
    env = @{ MORTY_MODEL = 'test-model'; MORTY_DENYLIST = (Join-Path $PSScriptRoot 'test-boot-validation.ps1') }
    hooks = @{
        PreToolUse  = @(@{ matcher = 'Bash'; hooks = @(@{ type = 'command'; command = 'echo pre' }) })
        PostToolUse = @(@{ matcher = '.*';  hooks = @(@{ type = 'command'; command = 'echo post' }) })
    }
}
$r = Invoke-Validator -Root $f.Root -SettingsPath $f.Settings -EnvOverrides @{ CLAUDE_PROJECT_DIR = $f.Root; MORTY_MODEL = 'test-model' }
Assert-ExitCode 0 $r.ExitCode 'all-green exits 0'
Assert-Contains $r.Output '[ OK ] CLAUDE_PROJECT_DIR' 'all-green reports OK for CLAUDE_PROJECT_DIR'
Assert-Contains $r.Output '[ OK ] PostToolUse hook wired' 'all-green reports OK for PostToolUse'
Remove-Item -Path $f.Root -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== 2. Unexpanded placeholder in CLAUDE_PROJECT_DIR ===" -ForegroundColor Cyan
$f = New-Fixture -CreateLogs -Settings @{ hooks = @{ PostToolUse = @(@{ matcher='.*'; hooks=@(@{type='command';command='x'}) }) } }
$r = Invoke-Validator -Root $f.Root -SettingsPath $f.Settings -EnvOverrides @{ CLAUDE_PROJECT_DIR = '${CLAUDE_PROJECT_DIR}'; MORTY_MODEL = $null }
Assert-ExitCode 1 $r.ExitCode 'unexpanded placeholder exits 1'
Assert-Contains $r.Output '[FAIL] CLAUDE_PROJECT_DIR expanded' 'unexpanded placeholder is flagged'
Remove-Item -Path $f.Root -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== 3. Literal `${CLAUDE_PROJECT_DIR} directory exists ===" -ForegroundColor Cyan
$f = New-Fixture -CreateLogs -CreateBrokenPlaceholder -Settings @{ hooks = @{ PostToolUse = @(@{ matcher='.*'; hooks=@(@{type='command';command='x'}) }) } }
$r = Invoke-Validator -Root $f.Root -SettingsPath $f.Settings -EnvOverrides @{ CLAUDE_PROJECT_DIR = $f.Root; MORTY_MODEL = $null }
Assert-ExitCode 1 $r.ExitCode 'broken placeholder dir exits 1'
Assert-Contains $r.Output '[FAIL] no literal placeholder dir' 'broken placeholder dir is flagged'
Remove-Item -Path $f.Root -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== 4. Missing PostToolUse hook ===" -ForegroundColor Cyan
$f = New-Fixture -CreateLogs -Settings @{ hooks = @{} }
$r = Invoke-Validator -Root $f.Root -SettingsPath $f.Settings -EnvOverrides @{ CLAUDE_PROJECT_DIR = $f.Root; MORTY_MODEL = $null }
Assert-ExitCode 1 $r.ExitCode 'missing PostToolUse exits 1'
Assert-Contains $r.Output '[FAIL] PostToolUse hook wired' 'missing PostToolUse is flagged'
Remove-Item -Path $f.Root -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== 5. MORTY_MODEL drift between env and settings.json ===" -ForegroundColor Cyan
$f = New-Fixture -CreateLogs -Settings @{
    env = @{ MORTY_MODEL = 'settings-says-A' }
    hooks = @{ PostToolUse = @(@{ matcher='.*'; hooks=@(@{type='command';command='x'}) }) }
}
$r = Invoke-Validator -Root $f.Root -SettingsPath $f.Settings -EnvOverrides @{ CLAUDE_PROJECT_DIR = $f.Root; MORTY_MODEL = 'env-says-B' }
Assert-ExitCode 0 $r.ExitCode 'model drift is a warning (exit 0)'
Assert-Contains $r.Output '[WARN] MORTY_MODEL agreement' 'model drift is flagged as WARN'
Remove-Item -Path $f.Root -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== 6. Denylist path points to a missing file ===" -ForegroundColor Cyan
$f = New-Fixture -CreateLogs -Settings @{
    env = @{ MORTY_DENYLIST = '/nonexistent/denylist.yaml' }
    hooks = @{ PostToolUse = @(@{ matcher='.*'; hooks=@(@{type='command';command='x'}) }) }
}
$r = Invoke-Validator -Root $f.Root -SettingsPath $f.Settings -EnvOverrides @{ CLAUDE_PROJECT_DIR = $f.Root; MORTY_MODEL = $null }
Assert-ExitCode 1 $r.ExitCode 'missing denylist exits 1'
Assert-Contains $r.Output '[FAIL] denylist exists' 'missing denylist is flagged'
Remove-Item -Path $f.Root -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
Write-Host ""
if ($failures.Count -eq 0) {
    Write-Host "All boot-validation tests passed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "$($failures.Count) test(s) failed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
