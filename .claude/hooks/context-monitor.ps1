# .claude/hooks/context-monitor.ps1
# A PreToolUse hook that checks context size and acts as a human-in-the-loop warning
# to prevent context overflow against Lemonade (llama.cpp) which ignores compaction.

$ErrorActionPreference = "Continue"

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { [Environment]::Exit(0) }
try { $inp = $raw | ConvertFrom-Json } catch { [Environment]::Exit(0) }

# Allow certain harmless tools to proceed unconditionally, preventing deadlocks when agent tries to checkpoint.
# We whitelist tools necessary for creating a checkpoint and viewing files.
$whitelist = @("Bash", "Write", "Edit")
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
}
[Environment]::Exit(0)
