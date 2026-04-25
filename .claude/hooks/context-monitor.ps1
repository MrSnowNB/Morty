# .claude/hooks/context-monitor.ps1
# A PreToolUse hook that checks context size and acts as a human-in-the-loop warning
# to prevent context overflow against Lemonade (llama.cpp) which ignores compaction.

$ErrorActionPreference = "Continue"

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { [Environment]::Exit(0) }
try { $inp = $raw | ConvertFrom-Json } catch { [Environment]::Exit(0) }

# Allow certain harmless tools to proceed unconditionally, preventing deadlocks when agent tries to checkpoint.
# We whitelist tools necessary for creating a checkpoint and viewing files.
$whitelist = @("Bash", "Write", "Edit", "Read", "Replace")
if ($whitelist -contains $inp.tool_name) {
    [Environment]::Exit(0)
}

# The payload contains "context_window": {"total": ..., "used": ..., "remaining": ..., "remaining_pct": ...}
if ($inp.context_window -and $inp.context_window.remaining_pct -ne $null) {
    $remaining_pct = [double]$inp.context_window.remaining_pct

    # Check for the 80% usage threshold. If remaining_pct <= 20.0, we block.
    if ($remaining_pct -le 20.0) {
        # Return a non-zero exit code and error message to block the tool call
        [Console]::Error.WriteLine("CONTEXT LOW: Context window usage is at/above 80%.")
        [Console]::Error.WriteLine("ACTION REQUIRED: Run /checkpoint now, then /clear before the next tool call to rotate context.")
        [Environment]::Exit(1)
    }
} else {
    # Fallback heuristic: check line count of the morty journal as a proxy for context
    # If the journal exceeds 400 lines in a session, we warn the user.
    $projectRoot = if ($env:MORTY_PROJECT_ROOT) { $env:MORTY_PROJECT_ROOT } else { $env:CLAUDE_PROJECT_DIR }
    if (-not $projectRoot) { $projectRoot = (Get-Location).Path }
    $journal = Join-Path $projectRoot "logs/morty-journal.jsonl"

    if (Test-Path $journal) {
        # Fast line count reading
        $lineCount = 0
        $reader = [System.IO.File]::OpenText($journal)
        while ($reader.ReadLine() -ne $null) { $lineCount++ }
        $reader.Close()

        if ($lineCount -ge 400) {
            [Console]::Error.WriteLine("CONTEXT LOW (Fallback check): Journal exceeds 400 lines.")
            [Console]::Error.WriteLine("ACTION REQUIRED: Run /checkpoint now, then /clear before the next tool call to rotate context.")
            [Environment]::Exit(1)
        }
    }
}
[Environment]::Exit(0)
