# Case: task-begin/task-end not wired to journal

**Date:** 2026-04-21  
**Session:** loop-validation-v1  
**Severity:** Critical — chain-miner sees 0 closed tasks; self-improvement loop is completely blocked

## Symptom
After running three `/task-begin` + `/task-end` bounded review sessions,
chain-miner reported:
```json
{ "tasks_seen": 1, "tasks_closed": 0, "candidates": [] }
```
No qualifying chains surfaced. `/codify` had nothing to propose.

## Root Cause
`/task-begin` and `/task-end` are Claude Code UI slash commands that
open/close the task list in the interface. They do NOT automatically
write `kind:task_begin` or `kind:task_end` entries to
`logs/morty-journal.jsonl`.

Chain-miner groups tool calls by `task_id` using `task_begin`/`task_end`
anchors in the journal. If those anchors are never written, every task
appears unclosed and is skipped entirely.

## Fix
The `task-begin` and `task-end` skills now include a mandatory Step 1
that appends the journal anchor via `append.ps1` before doing anything
else. See:
- `.claude/skills/task-begin/SKILL.md`
- `.claude/skills/task-end/SKILL.md`
- `.claude/skills/task-begin/scripts/append.ps1`

## Detection
- `chain-miner` output shows `tasks_closed: 0` despite running tasks
- Journal tail has no `kind:task_begin` or `kind:task_end` entries
- `Select-String '"kind":"task_begin"'` on journal returns no matches

## Reusable Invariant
> Claude Code slash commands control the UI task list only. Journal
> anchors must be written explicitly via `append.ps1`. Always verify
> the journal tail after the first `/task-end` of a session to confirm
> anchors are present before running chain-miner.
