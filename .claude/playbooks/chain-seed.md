---
title: Playbook — chain-seed
version: 1.0
author: Perplexity (PR #2 of co-evolution game)
trigger: start of every session, after zombie-restore, before first real task
---

# Playbook: chain-seed

## Purpose

Run two identical journal-health tasks at the start of every session to seed
the chain-miner with at least one repeatable tool-call pattern. Without this,
chain-miner always sees 0 candidates and `/codify` can never propose a skill.

This is the minimum viable input for the self-improvement loop:
`chain-seed → chain-miner → /codify → Mark approves → new skill merged`.

## When to Run

Run chain-seed **once per session**, immediately after zombie-restore PASSES
and before the first real task begins. Skip if:
- Zombie-restore result is BLOCKED or MINIMAL-MODE (fix the block first)
- Mark has explicitly given a high-priority task to start immediately

## The Warm-Up Pair

Run Task A and Task B in sequence. They must be **identical steps** so the
chain-miner sees a repeated tool-call pattern.

### Task A — journal-health-1

```
/task-begin journal-health-1
```

Step 1: Read the last 10 journal lines.
```powershell
pwsh -NoProfile -Command "Get-Content logs/morty-journal.jsonl -Tail 10"
```

Step 2: Count total entries.
```powershell
pwsh -NoProfile -Command "(Get-Content logs/morty-journal.jsonl | Measure-Object -Line).Lines"
```

Step 3: Report — write one line to SCRATCH.md:
```
## JOURNAL-HEALTH [<ts>] task=journal-health-1 entries=<N> last_ts=<ts of last entry>
```

```
/task-end success
```

### Task B — journal-health-2

Repeat **exactly the same three steps** with `task=journal-health-2`.

```
/task-begin journal-health-2
```

(Same Step 1, Step 2, Step 3 — update the SCRATCH.md line with new counts)

```
/task-end success
```

## After the Warm-Up Pair

Run chain-miner immediately to confirm the seed worked:

```powershell
pwsh -NoProfile -File .claude/skills/chain-miner/scripts/mine.ps1 -Tail 200
```

Expected output: `tasks_seen >= 2`, `tasks_closed >= 2`, `candidates >= 1`.

If candidates = 0:
- Check that task_id is non-empty in recent tool_call entries
- Confirm `/task-begin` wrote a `kind:task_begin` entry before the tool calls
- If task_id is empty, the hook fallback is not working — stop and report to Mark

## Success Criteria

- chain-miner reports `candidates >= 1` after the warm-up pair
- Both tasks have `exit_status: success` in the journal
- SCRATCH.md has two `## JOURNAL-HEALTH` lines
- Chain Yield metric in next `self-benchmark` run is > 0

## Relation to Self-Benchmark

Chain Yield was 0.00 in Session 1 (baseline score: 3.00/4.00).
This playbook directly targets that gap. After chain-seed runs successfully
for two sessions in a row, Chain Yield should reach 0.10+ and composite
score should reach 3.50+.

If composite score does not improve after 3 sessions with chain-seed:
report to Mark — the chain-miner threshold or task_id propagation may still
have an unresolved issue.
