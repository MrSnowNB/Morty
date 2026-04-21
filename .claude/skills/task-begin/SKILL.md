# Skill: task-begin

## Purpose
Open a named task boundary. Writes a `kind:task_begin` anchor to
`logs/morty-journal.jsonl` so chain-miner can group subsequent
tool_call entries into a scored, bounded chain.

## Trigger
User types `/task-begin <task-id>` at the prompt.

## Preconditions
- `$env:MORTY_PROJECT_ROOT` is set
- `logs/morty-journal.jsonl` is accessible (created if missing)
- No existing open task with the same `task_id` (warn if duplicate)

## Steps

### Step 1 — Write journal anchor (MANDATORY, always first)
```powershell
pwsh -File .claude/skills/task-begin/scripts/append.ps1 `
  -TaskId "<task-id>" `
  -Kind task_begin `
  -Summary "<brief description of what this task will do>"
```
Do not proceed to Step 2 until this command confirms the write.

### Step 2 — Confirm and report
Report to the user:
- Task ID opened
- Journal entry written (ts + task_id)
- LoRa-Mux mode (STANDARD/LORA)

## Governance
- NEVER skip Step 1. A task without a journal anchor is invisible to
  chain-miner and wastes the execution record.
- NEVER use Bash(`/task-begin`) — this command must be typed as a
  slash command or invoked via `Skill(task-begin)` with the task ID
  passed as context.
- `/task-begin` does NOT auto-run zombie-restore. That is a separate
  pre-task gate and must be run explicitly if required.

## Anti-patterns
- Logging task boundaries only to SCRATCH.md (chain-miner reads the
  journal, not SCRATCH.md)
- Using `Write-Output` to the journal instead of `Add-Content`
  (overwrites instead of appending)

## See Also
- `.claude/skills/task-end/SKILL.md`
- `.claude/skills/chain-miner/SKILL.md`
- `cases/task-boundary-not-wired-to-journal.md`
- `cases/task-begin-misrouted-as-bash.md`
