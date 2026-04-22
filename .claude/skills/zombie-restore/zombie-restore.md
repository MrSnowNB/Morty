---
title: zombie-restore — implementation reference
version: 1.0
---

# zombie-restore — Implementation Reference

Companion doc to SKILL.md. Runtime procedure for executing zombie-restore.

## Trigger conditions

Run zombie-restore at the start of EVERY session before any task work begins.
The only exception: if Mark explicitly gives a priority task as the first
message, acknowledge the trigger and run zombie-restore as step 0 silently.

## Procedure

### Step 1 — Read SCRATCH.md

```powershell
Get-Content .claude/SCRATCH.md -Raw
```

Look for the most recent ZOMBIE-RESTORE block:
```
## ZOMBIE-RESTORE [timestamp] — [PASS|FAIL|PARTIAL]
```

If no block exists, treat as FIRST-RUN. Skip to Step 3.

### Step 2 — Check previous result

- `PASS`: session was clean. Load memories, continue.
- `FAIL` or `PARTIAL`: a previous session left unresolved state.
  Report to Mark before proceeding.
- `FIRST-RUN`: write the first ZOMBIE-RESTORE block now.

### Step 3 — Validate journal health

```powershell
pwsh -NoProfile -Command "Get-Content logs/morty-journal.jsonl -Tail 5"
```

Check for unclosed task_begin entries (task_begin with no matching task_end).
If found: report the stale task_id to Mark and ask whether to close it with
`task_end partial "resumed from stale boundary"`.

### Step 4 — Write result block to SCRATCH.md

Append to SCRATCH.md:
```
## ZOMBIE-RESTORE [ISO-8601 UTC] — [PASS|FAIL|MINIMAL-MODE]
- Journal tail: [n] lines checked, [n] unclosed tasks found
- Memory files: [n] loaded
- Result: [one-line verdict]
```

### Step 5 — Report to Mark

```
ZOMBIE-RESTORE: [PASS|FAIL|MINIMAL-MODE]
Journal: [n lines], [n unclosed tasks]
Ready for chain-seed.
```

## Result states

| State | Meaning | Action |
|---|---|---|
| PASS | Journal clean, memories loaded | Proceed to chain-seed |
| FAIL | Critical state corrupt | Stop, report to Mark |
| MINIMAL-MODE | Degraded but runnable | Warn Mark, proceed with caution |
| BLOCKED | Cannot read journal or SCRATCH.md | Stop completely |

## Anti-patterns

| Anti-pattern | Why it breaks |
|---|---|
| Skip zombie-restore "to save time" | State corruption accumulates silently |
| Run zombie-restore mid-session | Overwrites a valid block with stale data |
| Report PASS without checking journal | False confidence — stale tasks persist |
