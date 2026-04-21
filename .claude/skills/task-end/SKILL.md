# Skill: task-end

## Purpose
Close a named task boundary. Writes a `kind:task_end` anchor with
`exit_status` to `logs/morty-journal.jsonl` so chain-miner can score
the completed chain and consider it for codification.

## Trigger
User types `/task-end exit_status=<success|partial|fail>` at the prompt.

## Preconditions
- A matching `kind:task_begin` entry exists in the journal for the
  current `MORTY_TASK_ID`
- `exit_status` is one of: `success`, `partial`, `fail`, `aborted`

## Steps

### Step 1 — Write journal anchor (MANDATORY, always first)
```powershell
pwsh -File .claude/skills/task-end/scripts/append.ps1 `
  -TaskId "<task-id>" `
  -Kind task_end `
  -Summary "<exit_status>" `
  -ExitStatus "<success|partial|fail|aborted>"
```
Do not proceed to Step 2 until this command confirms the write.

### Step 2 — Write checkpoint
Run `Skill(checkpoint-writer)` to snapshot current state.

### Step 3 — Confirm and report
Report to the user:
- Task ID closed
- exit_status recorded
- Journal anchor written (ts)
- Whether chain-miner threshold may now be met (tasks_closed count)

## exit_status values
| Value | Meaning |
|-------|---------|
| `success` | Task completed, output verified |
| `partial` | Task completed with caveats |
| `fail` | Task failed, root cause identified |
| `aborted` | Task abandoned before completion |

## Governance
- NEVER skip Step 1. An unclosed task is invisible to chain-miner.
- Chain-miner requires `kind:task_end` with summary starting with
  `success` to count a chain as successful.
- Only `success` outcome contributes to `success_rate`; partial/fail
  lower it.

## See Also
- `.claude/skills/task-begin/SKILL.md`
- `.claude/skills/chain-miner/SKILL.md`
- `cases/task-boundary-not-wired-to-journal.md`
