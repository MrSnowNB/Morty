---
title: Skill — self-benchmark
version: 1.1
author: Perplexity (PR #2 update)
---

# Skill: self-benchmark

## Purpose

Measure Morty's own performance across sessions using objective metrics derived
from the journal. Produces a scored report to SCRATCH.md so that Perplexity
(via Mark) can track improvement over time and decide what to build next.

This is the **observability primitive** for the PR-driven co-evolution game:
every session ends with a score; scores are compared across PRs.

## When to Invoke

Invoke at the END of any session, after all tasks are complete and before /clear:
- After completing a LOOP-VALIDATION run
- After any multi-task session with task_begin/task_end boundaries
- On demand: when Mark asks "how did this session go?"

Do NOT invoke during a task. Run after /task-end only.

## The Four Metrics

### Metric 1 — Gate Score (0–4)
> How many zombie-restore gates passed this session?

Read SCRATCH.md, find the most recent `## ZOMBIE-RESTORE` block.
Count gates with result PASS. Score = gates passed / 4.

- 4/4 = 1.0 (perfect)
- 3/4 = 0.75
- 2/4 = 0.5
- <2 = degraded

### Metric 2 — Tool Error Rate (0.0–1.0, lower is better)
> What fraction of tool calls returned errors this session?

Use the benchmark.ps1 script for accurate counts. The field is `exit_status`
(not `exit_status` with a hyphen). Example manual check:

```powershell
$lines = Get-Content logs/morty-journal.jsonl -Tail 500
$calls = foreach ($l in $lines) { try { $l | ConvertFrom-Json } catch { $null } } | Where-Object { $_ -and $_.kind -eq 'tool_call' }
$errors = $calls | Where-Object { $_.exit_status -eq 'error' }
"errors: $($errors.Count) / total: $($calls.Count)"
```

- 0.0 = perfect
- < 0.1 = good
- > 0.2 = degraded — investigate repeated failures

### Metric 3 — Task Completion Rate (0.0–1.0)
> What fraction of started tasks were closed with success?

```powershell
$begins = $calls | Where-Object { $_.kind -eq 'task_begin' }
$successes = $calls | Where-Object { $_.kind -eq 'task_end' -and $_.exit_status -eq 'success' }
"begins: $($begins.Count) / successes: $($successes.Count)"
```

- 1.0 = all tasks closed successfully
- < 0.5 = more than half of tasks stalled or errored

### Metric 4 — Chain Yield (candidates per 10 closed tasks)
> Is the journal accumulating enough repeatable patterns for chain-miner?

Run chain-miner with default thresholds. Divide candidate count by closed task
count * 10. Report raw candidate count and yield ratio.

- 0 candidates = no patterns yet (expected early; run chain-seed playbook)
- ≥ 1 candidate per 10 tasks = healthy

**If Chain Yield = 0: run the `chain-seed` playbook at the start of the next
session before any other task.**

## Output Format

Append to SCRATCH.md:

```
## BENCHMARK [YYYY-MM-DD HH:MM UTC] v1.1
- Session start (approx): <ts of first journal entry this session>
- Session end: <now>
- Tool calls this session: <N>

### Scores
| Metric               | Value  | Status   |
|----------------------|--------|----------|
| Gate Score           | X/4    | PASS/FAIL|
| Tool Error Rate      | X.XX   | good/degraded |
| Task Completion Rate | X.XX   | good/degraded |
| Chain Yield          | X cand / Y tasks | N/A or healthy |

### Composite Score: X.XX / 4.00

### Notes
- <one sentence on biggest weakness>
- <one sentence on biggest strength>
- <one sentence recommendation for next PR>
```

## Composite Score Formula

```
composite = gate_score                          # 0–1
          + (1 - tool_error_rate)              # 0–1 (inverted — lower error = better)
          + task_completion_rate               # 0–1
          + min(chain_yield * 10, 1.0)         # 0–1 (capped at 1)
```

Max composite = 4.0. Report to 2 decimal places.

## Session Scores History

| Session | Date | Composite | Chain Yield | Notes |
|---------|------|-----------|-------------|-------|
| 1 | 2026-04-20 | 3.00/4.00 | 0 | Baseline. task_id bug live most of session. |

## Hard Rules

- Never fabricate scores. If data is missing, report "N/A" with reason.
- Do NOT run chain-miner with MinCount 1 or MinSuccessRate 0 for this metric — use
  default thresholds only (count ≥ 2, success_rate = 1.0).
- Report the benchmark result to Mark verbally after writing to SCRATCH.md.
- The benchmark is informational only — it does not gate any action.
- If Chain Yield = 0 two sessions in a row, escalate to Mark immediately.
