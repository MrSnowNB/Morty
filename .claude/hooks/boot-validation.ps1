# .claude/hooks/boot-validation.ps1
# Morty boot-loop self-check. Runs on SessionStart.
#
# Purpose: fail loud when the harness is misconfigured, with a remediation
# checklist, rather than silently degrading (hooks that don't fire, journals
# that get written to `${CLAUDE_PROJECT_DIR}/logs/...` instead of `logs/...`,
# env vars that drift from settings.json, etc.).
#
# Exit codes:
#   0 = all green (or warnings only)
#   1 = one or more fatal checks failed; session should abort and show remediation
#
# Usage (wired as a SessionStart hook in settings.json):
#   pwsh -NoProfile -ExecutionPolicy Bypass -File ${CLAUDE_PROJECT_DIR}/.claude/hooks/boot-validation.ps1
#
# Standalone / CI smoke test:
#   pwsh -NoProfile -File .claude/hooks/boot-validation.ps1 -ProjectRoot . -Strict

[CmdletBinding()]
param(
    # Override CLAUDE_PROJECT_DIR for testing. Default: env var, falling back to $PWD.
    [string]$ProjectRoot = $(if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }),

    # Path to the user-scope settings.json. Default: $HOME/.claude/settings.json (cross-platform).
    [string]$SettingsPath = $(Join-Path $HOME '.claude/settings.json'),

    # If set, warnings also fail (for CI).
    [switch]$Strict,

    # If set, emit a structured JSON summary to stdout in addition to text.
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

# Bolt optimization: Using [System.Collections.Generic.List[object]] and .Add()
# instead of standard arrays (@()) and += to avoid O(n^2) performance bottleneck
# from repeated array reallocations when aggregating results.
$fails = [System.Collections.Generic.List[object]]::new()
$warns = [System.Collections.Generic.List[object]]::new()
$oks   = [System.Collections.Generic.List[object]]::new()

function Add-Ok   { param([string]$name, [string]$detail) $script:oks.Add([pscustomobject]@{ name=$name; detail=$detail }) }
function Add-Warn { param([string]$name, [string]$detail, [string]$fix) $script:warns.Add([pscustomobject]@{ name=$name; detail=$detail; fix=$fix }) }
function Add-Fail { param([string]$name, [string]$detail, [string]$fix) $script:fails.Add([pscustomobject]@{ name=$name; detail=$detail; fix=$fix }) }

# ---------------------------------------------------------------------------
# Check 1: CLAUDE_PROJECT_DIR is set AND expands to a real directory
# ---------------------------------------------------------------------------
$cpd = $env:CLAUDE_PROJECT_DIR
if (-not $cpd) {
    Add-Fail 'CLAUDE_PROJECT_DIR exported' `
        'Env var is unset. Hooks/skills that reference ${CLAUDE_PROJECT_DIR} will write to literal "${CLAUDE_PROJECT_DIR}" paths.' `
        'Export CLAUDE_PROJECT_DIR in your launcher (morty.ps1) to $PWD before starting the agent.'
} elseif ($cpd -match '\$\{CLAUDE_PROJECT_DIR\}' -or $cpd -match '^\$\{') {
    Add-Fail 'CLAUDE_PROJECT_DIR expanded' `
        "Env var contains an unexpanded placeholder: '$cpd'." `
        'Ensure the launcher expands the value before export (e.g. PowerShell: $env:CLAUDE_PROJECT_DIR = $PWD.Path).'
} elseif (-not (Test-Path $cpd)) {
    Add-Fail 'CLAUDE_PROJECT_DIR resolves' `
        "Env var points to a non-existent path: '$cpd'." `
        'Fix the path or unset the variable so it falls back to $PWD.'
} else {
    Add-Ok 'CLAUDE_PROJECT_DIR' $cpd
}

# ---------------------------------------------------------------------------
# Check 2: MORTY_MODEL env vs settings.json agreement
# ---------------------------------------------------------------------------
if (Test-Path $SettingsPath) {
    try {
        $settings = Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json
        $settingsModel = $settings.env.MORTY_MODEL
        $envModel = $env:MORTY_MODEL
        if ($settingsModel -and $envModel -and ($settingsModel -ne $envModel)) {
            Add-Warn 'MORTY_MODEL agreement' `
                "settings.json says '$settingsModel' but env var says '$envModel'. Env wins at runtime; settings.json may be misleading." `
                'Reconcile the two: either unset the shell export, or update settings.json to match.'
        } elseif (-not $envModel -and -not $settingsModel) {
            Add-Warn 'MORTY_MODEL agreement' `
                'MORTY_MODEL is unset in both env and settings.json.' `
                'Set MORTY_MODEL in settings.json or export it in the launcher.'
        } else {
            $effective = if ($envModel) { $envModel } else { $settingsModel }
            Add-Ok 'MORTY_MODEL' $effective
        }
    } catch {
        Add-Warn 'settings.json parseable' `
            "Could not parse $SettingsPath as JSON: $($_.Exception.Message)" `
            'Fix JSON syntax errors in settings.json.'
    }
} else {
    Add-Warn 'settings.json exists' `
        "$SettingsPath not found." `
        'Create a user-scope settings.json, or override -SettingsPath on the boot-validation call.'
}

# ---------------------------------------------------------------------------
# Check 3: logs/ directory exists and is writable (in the PROJECT root, not literal)
# ---------------------------------------------------------------------------
$logsDir = Join-Path $ProjectRoot 'logs'
if (-not (Test-Path $logsDir)) {
    Add-Warn 'logs/ directory' `
        "logs/ does not exist under '$ProjectRoot'." `
        'mkdir logs; touch logs/.gitkeep'
} else {
    # Probe writability via the BCL (straight POSIX syscalls) rather than
    # Set-Content/Remove-Item, whose providers can report spurious
    # "insufficient access" errors on PS7/Linux under $ErrorActionPreference='Stop'
    # even for directories the process clearly owns (seen on /tmp fixtures in CI).
    $probe = Join-Path $logsDir ".boot-validation-probe-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    $probeOk = $false
    $probeErr = $null
    try {
        [System.IO.File]::WriteAllText($probe, 'probe')
        if (Test-Path -LiteralPath $probe) {
            [System.IO.File]::Delete($probe)
            $probeOk = $true
        } else {
            $probeErr = 'probe file did not materialize'
        }
    } catch {
        $probeErr = $_.Exception.Message
    }
    if ($probeOk) {
        Add-Ok 'logs/ writable' $logsDir
    } else {
        Add-Fail 'logs/ writable' `
            "logs/ exists but cannot be written: $probeErr" `
            'Fix filesystem permissions on the logs/ directory.'
    }
}

# ---------------------------------------------------------------------------
# Check 4: no literal ${CLAUDE_PROJECT_DIR} directory exists in the workspace
#           (this happens when a hook writes to the unexpanded placeholder)
# ---------------------------------------------------------------------------
$brokenDir = Join-Path $ProjectRoot '${CLAUDE_PROJECT_DIR}'
if (Test-Path $brokenDir) {
    Add-Fail 'no literal placeholder dir' `
        "A directory literally named '`${CLAUDE_PROJECT_DIR}' exists under the project root. Some hook/skill wrote to the unexpanded placeholder." `
        "Inspect '$brokenDir', move its contents into the real 'logs/' tree, delete the broken dir, and fix whichever script wrote there (check post-tool.ps1 and journal-anchor)."
} else {
    Add-Ok 'no literal placeholder dir' 'clean'
}

# ---------------------------------------------------------------------------
# Check 5: PreToolUse + PostToolUse hooks wired in settings.json
# ---------------------------------------------------------------------------
if (Test-Path $SettingsPath) {
    try {
        if (-not $settings) { $settings = Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json }
        $pre  = $settings.hooks.PreToolUse
        $post = $settings.hooks.PostToolUse
        if (-not $pre -or $pre.Count -eq 0) {
            Add-Warn 'PreToolUse hook wired' `
                'No PreToolUse entries in settings.json.' `
                'Add a PreToolUse hook (e.g. pre-bash.ps1) matching "Bash" to enforce the denylist.'
        } else {
            Add-Ok 'PreToolUse hook wired' "$($pre.Count) entr(y/ies)"
        }
        if (-not $post -or $post.Count -eq 0) {
            Add-Fail 'PostToolUse hook wired' `
                'No PostToolUse entries in settings.json. Journal will not be written.' `
                'Add a PostToolUse hook pointing at post-tool.ps1 so every tool call anchors to the journal.'
        } else {
            Add-Ok 'PostToolUse hook wired' "$($post.Count) entr(y/ies)"
        }
    } catch {
        # already reported above
    }
}

# ---------------------------------------------------------------------------
# Check 6: denylist exists at the path settings.json points to (if set)
# ---------------------------------------------------------------------------
if ($settings -and $settings.env.MORTY_DENYLIST) {
    $denylist = $settings.env.MORTY_DENYLIST
    if (Test-Path $denylist) {
        Add-Ok 'denylist exists' $denylist
    } else {
        Add-Fail 'denylist exists' `
            "MORTY_DENYLIST in settings.json points to '$denylist' which does not exist." `
            'Fix the path or create the denylist YAML at that location.'
    }
}

# ---------------------------------------------------------------------------
# Check 7: key skill dirs present (non-fatal; warn if stuff is missing)
# ---------------------------------------------------------------------------
$expectedSkills = @('first-principles', 'journal-anchor', 'safe-bash', 'checkpoint-writer')
foreach ($s in $expectedSkills) {
    $skillPath = Join-Path $ProjectRoot ".claude/skills/$s/SKILL.md"
    if (-not (Test-Path $skillPath)) {
        Add-Warn 'expected skill present' `
            "$s SKILL.md not found at $skillPath" `
            "Restore the $s skill or remove the dependency."
    }
}
if ($warns.Count -eq 0 -or -not ($warns | Where-Object { $_.name -eq 'expected skill present' })) {
    Add-Ok 'expected skills present' ($expectedSkills -join ', ')
}

# ---------------------------------------------------------------------------
# Report
#
# Use [Console]::WriteLine directly so output is captured when stdout is
# piped (child-process invocation, CI). Write-Host goes to the Information
# stream, which PowerShell on Linux does not route to pipe-stdout in all
# hosts. ANSI colors are kept via raw escape codes for interactive use.
# ---------------------------------------------------------------------------
$esc = [char]27
$C_RESET = "$esc[0m"
$C_CYAN  = "$esc[36m"
$C_GREEN = "$esc[32m"
$C_YELL  = "$esc[33m"
$C_RED   = "$esc[31m"
$C_DIM   = "$esc[2m"

$sep = '-' * 60
[Console]::WriteLine('')
[Console]::WriteLine("${C_CYAN}Morty boot validation${C_RESET}")
[Console]::WriteLine($sep)

foreach ($o in $oks) {
    $line = "  ${C_GREEN}[ OK ]${C_RESET} $($o.name)"
    if ($o.detail) { $line += " ${C_DIM}— $($o.detail)${C_RESET}" }
    [Console]::WriteLine($line)
}
foreach ($w in $warns) {
    [Console]::WriteLine("  ${C_YELL}[WARN]${C_RESET} $($w.name)")
    [Console]::WriteLine("         $($w.detail)")
    if ($w.fix) { [Console]::WriteLine("         ${C_DIM}fix: $($w.fix)${C_RESET}") }
}
foreach ($f in $fails) {
    [Console]::WriteLine("  ${C_RED}[FAIL]${C_RESET} $($f.name)")
    [Console]::WriteLine("         $($f.detail)")
    if ($f.fix) { [Console]::WriteLine("         ${C_DIM}fix: $($f.fix)${C_RESET}") }
}
[Console]::WriteLine($sep)
[Console]::WriteLine("  summary: $($oks.Count) OK, $($warns.Count) WARN, $($fails.Count) FAIL")
[Console]::WriteLine('')

if ($Json) {
    $summary = [pscustomobject]@{
        ok       = $oks
        warnings = $warns
        failures = $fails
    }
    $summary | ConvertTo-Json -Depth 5
}

if ($fails.Count -gt 0) { exit 1 }
if ($Strict -and $warns.Count -gt 0) { exit 1 }
exit 0
