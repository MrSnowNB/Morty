# Case: Journal written to literal `${CLAUDE_PROJECT_DIR}/logs/` directory

**Date:** 2026-04-22
**Severity:** data-integrity (silent)
**Surface:** `.claude/hooks/post-tool.ps1` → journal write

## Symptom

After a session, `git status` shows a new tracked file at:

```
${CLAUDE_PROJECT_DIR}/logs/morty-journal.jsonl
```

— a real file inside a real directory whose name is the literal string `${CLAUDE_PROJECT_DIR}`. The canonical `logs/morty-journal.jsonl` remains empty (or absent).

## Root cause

`post-tool.ps1` uses `$env:MORTY_PROJECT_ROOT` to locate the journal directory. `settings.json` sets that env var to `${CLAUDE_PROJECT_DIR}` so each clone resolves to its own checkout. This relies on Claude Code performing `${CLAUDE_PROJECT_DIR}` substitution when it materializes env vars for the hook subprocess.

If that substitution does not happen — for example, when the hook is invoked in a context that doesn't pre-expand env values — `$env:MORTY_PROJECT_ROOT` arrives in the script as the literal 26-character string `${CLAUDE_PROJECT_DIR}`. `Join-Path $projectRoot 'logs'` then yields `${CLAUDE_PROJECT_DIR}/logs`, which `New-Item -ItemType Directory -Force` happily creates because the `$`, `{`, `}` characters are valid in filenames on both NTFS and POSIX filesystems. The journal is then written there. No error surfaces.

Meanwhile, the `.gitignore` rule `logs/*.jsonl` does not match `${CLAUDE_PROJECT_DIR}/logs/morty-journal.jsonl` (different path), so the journal gets tracked and committed.

## Fix

Two layers:

1. **Defensive expansion in `post-tool.ps1`.** If `$env:MORTY_PROJECT_ROOT` still contains a `${...}` placeholder, fall back to `$env:CLAUDE_PROJECT_DIR` or `(Get-Location).Path`. This prevents the bug from re-occurring even if settings.json loading changes in the future.
2. **Boot-loop validation.** `boot-validation.ps1` has two checks covering this failure mode:
   - **Check 1** fails if `CLAUDE_PROJECT_DIR` itself is unset or still contains the placeholder.
   - **Check 4** fails if a literal `${CLAUDE_PROJECT_DIR}` directory already exists under the project root — the smoking gun that a past session wrote there.
3. **CI guard.** Hygiene job refuses to merge any PR that tracks files containing a literal `${CLAUDE_PROJECT_DIR}` path component.

## What would have caught this earlier

- Boot-loop validation on SessionStart (added in this PR).
- A hygiene rule scanning `git ls-files` for placeholder path components (added in this PR).
- A post-session `logs/` integrity check that confirms new journal lines appeared in the canonical location — not yet implemented; candidate for follow-up.
