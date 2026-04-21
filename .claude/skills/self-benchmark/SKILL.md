---
title: Skill — self-benchmark
version: 1.0
author: Perplexity (via PR game)
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

```powershell
$lines = Get-Content logs/morty-journal.jsonl -Tail 500 | ConvertFrom-Json
$sessionCalls = $lines | Where-Object { $_.kind -eq 'tool_call' -and $_.ts -gt $sessionStart }
$errors = $sessionCalls | Where-Object { $_.exit_status -eq 'error' }
$errorRate = if ($sessionCalls.Count -gt 0) { $errors.Count / $sessionCalls.Count } else { 0 }
```

- 0.0 = perfect
- < 0.1 = good
- > 0.2 = degraded — investigate repeated failures

### Metric 3 — Task Completion Rate (0.0–1.0)
> What fraction of started tasks were closed with success?

```powershell
$begins = $lines | Where-Object { $_.kind -eq 'task_begin' -and $_.ts -gt $sessionStart }
$successes = $lines | Where-Object { $_.kind -eq 'task_end' -and $_.exit_status -eq 'success' -and $_.ts -gt $sessionStart }
$completionRate = if ($begins.Count -gt 0) { $successes.Count / $begins.Count } else { 0 }
```

- 1.0 = all tasks closed successfully
- < 0.5 = more than half of tasks stalled or errored

### Metric 4 — Chain Yield (candidates per 10 closed tasks)
> Is the journal accumulating enough repeatable patterns for chain-miner?

Run chain-miner with default thresholds. Divide candidate count by closed task
count * 10. Report raw candidate count and yield ratio.

- 0 candidates = no patterns yet (expected early in a project)
- ≥ 1 candidate per 10 tasks = healthy

## Output Format

Append to SCRATCH.md:

```
## BENCHMARK [YYYY-MM-DD HH:MM UTC] v1.0
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

## Hard Rules

- Never fabricate scores. If data is missing, report "N/A" with reason.
- Do NOT run chain-miner with MinCount 1 or MinSuccessRate 0 for this metric — use
  default thresholds only (count ≥ 2, success_rate = 1.0).
- Report the benchmark result to Mark verbally after writing to SCRATCH.md.
- The benchmark is informational only — it does not gate any action.
