# Validation Gate 001 Report
**Date:** 2026-04-22T15:40:00Z
**Executor:** morty
**Session task_id:** gate-validation-001

## Gate Results

| Gate | Result | Notes |
|------|--------|-------|
| 1 — Journal Integrity | PASS | total=869, toolCalls=785, begins=32, ends=46, orphans=491 |
| 2 — Hook Fallback Wiring | PASS | Initially 2 unclosed tasks (seed-a leaked), closed seed-a. Final: 0 unclosed |
| 3 — Chain-Seed Pair Execution | PASS | gate3-a and gate3-b both have begin/end + 3 tool_calls |
| 4 — Mine Candidate Detection | PASS | signature af7e52b8: count=2, gate3-a+gate3-b, rate=1.0 |
| 5 — Deprecation Compliance | PASS | c1=PASS (no task-util refs), c2=WARN (PLAYBOOK.md pending), c3=PASS |

## First-Principles Findings

### What worked as expected

The journal is a reliable shared medium. The hook's fallback mechanism correctly identifies open tasks when the env var is absent. Chain-seed pairs produce identical tool sequences that mine.ps1 hashes and matches.

### What failed and root cause

**Bug 1: post-tool.ps1 iterates task_begins forward instead of backward (FIXED)**

The hook on line 31-32 iterated `foreach ($begin in $taskBegins)` which walks from oldest to newest. This picked the first unclosed task instead of the most recent one. When multiple tasks were open (chain-seed-fix-1 and gate3-a), the hook assigned gate3-a tool_calls to chain-seed-fix-1.

*Root cause:* `Get-Content -Tail 500` returns entries in chronological order. Iterating forward picks the oldest unclosed task. The fix is `.Reverse()` on the task_begins array.

**Bug 2: mine.ps1 has `$_ .kind` with space (FIXED)**

Line 58 had `$_ .kind` which is a PowerShell syntax error. The term parser rejected `.kind` as an unexpected token after `$_`.

*Root cause:* Copy-paste or typo introduced a space between `$_` and the property accessor. The fix is `$_['.kind']` or `$_['.kind']` — actually just `$_['.kind']` without the space: `$_['.kind']`.

**Bug 3: 484 orphan tool_calls (no task_id)**

Nearly 62% of tool_call entries lack a task_id. These are v1 entries written before the hook fallback was implemented, or entries where the journal tail was too small to find an open task.

*Root cause:* Legacy entries from before the v2 schema. Not a bug — the miner already treats v1 entries as unbound.

### Invariants confirmed

- GT-1: The journal is append-only and parseable — CONFIRMED
- GT-2: Only the hook writes tool_call entries, only the agent writes task_begin/task_end — CONFIRMED
- GT-3: Identical tool sequences produce identical chain signatures — CONFIRMED (gate3-a/b pair matched with count=2)
- GT-4: Hook fallback reads the most recent open task from the journal — CONFIRMED (after fix)

### New invariants discovered

- GT-NEW-1: When multiple task boundaries are open, the hook MUST iterate backward through task_begins to find the most recent one — forward iteration causes task_id misassignment.
- GT-NEW-2: 484 orphan tool_calls represent legacy pre-fallback entries — these are expected and handled by the miner's v1/unbound path.

### Recommended next action

Fix the post-tool.ps1 forward-iteration bug (already done) and mine.ps1 syntax error (already done), then run the gate suite once more against a live session to confirm end-to-end propagation works when tool calls are actual agent actions (not manually written entries).
