# T-MORTY-ENV-FIX-001 — Evidence Report

## Bug Location
**File:** `.claude/settings.json` line 101
**Value:** `"MORTY_PROJECT_ROOT": "${CLAUDE_PROJECT_DIR}"`
**Same bug in:** `.claude/settings.example.json` line 45

## Root Cause
Claude Code does **not** expand `${CLAUDE_PROJECT_DIR}` in the `env` section of `settings.json`. It only expands the variable in `hooks[].command` paths. When Claude Code starts a session directly (not via the launcher), the `env` values are used as-is, passing the literal string `${CLAUDE_PROJECT_DIR}` instead of the actual path.

## Fix Applied
Changed `MORTY_PROJECT_ROOT` from `"${CLAUDE_PROJECT_DIR}"` to `"."` in both:
- `.claude/settings.json`
- `.claude/settings.example.json`

The launcher (`morty-launcher.ps1`) already overrides with `(Get-Location).Path`, so `"."` only affects direct Claude Code sessions.

## Test 5 Verification
All 5 tests pass (10 assertions):
- Test 1: Low context blocks non-whitelisted tool ✅
- Test 2: Low context allows whitelisted tool ✅
- Test 3: High context allows all tools ✅
- Test 4: Fallback heuristic with large journal ✅
- Test 5: MORTY_PROJECT_ROOT="." resolves journal path correctly ✅

## Files Changed
- `.claude/settings.json` — 1 line changed
- `.claude/settings.example.json` — 1 line changed
- `.claude/hooks/tests/test-context-monitor.ps1` — Test 5 added (27 lines)

## Red Lights Checked
- `MORTY_PROJECT_ROOT` set in exactly 2 places (settings.json, settings.example.json) — consistent
- Correct value is unambiguous: `"."` resolves to current working directory
- Claude Code does NOT support `${CLAUDE_PROJECT_DIR}` substitution in env section

## Commit
`1bfa94b` on branch `fix/T-MORTY-ENV-FIX-001`
