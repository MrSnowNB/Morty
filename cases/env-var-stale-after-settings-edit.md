# Case: env var stale after settings.json edit

**Date:** 2026-04-20  
**Session:** introspect + model correction  
**Severity:** Low — corrected via settings.json; affects next session only

## Symptom
`MORTY_MODEL` in `settings.json` was updated from `Qwen3-Coder-Next-GGUF`
to `user.Qwen3.6-35B-A3B-GGUF`. The running session still reported
`$env:MORTY_MODEL = Qwen3-Coder-Next-GGUF` because env vars are set at
Claude Code launch and are not live-reloaded.

## Root Cause
Claude Code reads `settings.json` env block at session start. Edits to
`settings.json` during a live session do not propagate to `$env:` until
a new session is launched.

## Detection
- `$env:MORTY_MODEL` returns the old value in the current session
- `settings.json` shows the new value
- Divergence between the two is the signal

## Fix
After any `settings.json` env edit, either:
1. Set the env var manually: `$env:MORTY_MODEL = "<new-value>"`
2. Or reload the session. Option 1 is faster for single-session continuity.

## Reusable Invariant
> `settings.json` env edits are not hot-reloaded. Always manually apply
> the change to `$env:` in the running session, or note that the current
> session is operating with stale env and reload before the next task.
