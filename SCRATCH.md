# FP Solve: [problem-slug] — [timestamp]

## Problem Statement

Write a single paragraph that defines the problem in stable terms. Once written, do not silently redefine it.

## Known Context

- Relevant user constraints:
- Relevant project facts:
- Prior attempts or logs:

## Assumption Table

| ID | Assumption | Type | Challenge | Five Whys root | Verdict | Notes |
|---|---|---|---|---|---|---|

## Ground Truths

- GT-1:
- GT-2:
- GT-3:

## Active Sub-Problems

- [ ] SP-1:
- [ ] SP-2:

## Breadth-First Challenge Results

Summarize which top-level assumptions survived, changed, or were discarded.

## Recursion Trace

- Depth 0:

## Error Log / Dead Ends

- None yet.

## Bottom-Up Reconstruction

Map conclusions back to ground truths and solved sub-problems.

## Open Questions

- OQ-1:

## Skill Synthesis Candidates

- Pattern:
- Reusable invariant:
- Candidate skill edit:

## ZOMBIE-RESTORE [2026-04-21T01:24Z] — CURRENT RUN

### Gate 1 — Freshness: PASS
- Last journal entry: 2026-04-21T01:23:56Z (within 24 hours)

### Gate 2 — Checkpoint Integrity: PASS
- Found `kind:checkpoint` entry at 2026-04-20T23:20:00Z
- Summary: "Zombie-restore gate check: G1 PASS, G2 PASS, G3 PASS, G4 LORA"

### Gate 3 — Tier-1 Provenance: PASS
- Latest checkpoint: 2026-04-20T23:20:00Z
- All 7 memory files modified before checkpoint (earliest: 04/16, latest: 04/20 19:05)
- All files anchored

### Gate 4 — LoRa-Mux Mode: STANDARD
- Fresh cold start, only mandatory boot sequence loaded
- No additional context beyond baseline
- Default mode per policy: STANDARD

### Result: PROCEED

### Model Confirmation
- $env:MORTY_MODEL: user.Qwen3.6-35B-A3B-GGUF
- /api/v1/health model_loaded: user.Qwen3.6-35B-A3B-GGUF
- Match: YES

## ZOMBIE-RESTORE [2026-04-20T23:07 UTC] — PREVIOUS RUN

- Gate 1 Freshness: PASS — last journal entry 2026-04-20T23:07Z (within 24h)
- Gate 2 Checkpoint: FAIL — CHECKPOINT.md exists but no `kind: anchor` field; journal contains zero `kind: anchor` entries
- Gate 3 Provenance: FAIL — all 7 memory files unanchored (zero anchors in journal)
- Gate 4 LoRa-Mux mode: WIDE — fresh session, minimal accumulated context (~30% fill)
- Result: BLOCKED — Gates 2 and 3 failed; no valid checkpoint anchor, no tier provenance

## Phase 1 — OBSERVE: Review 1 (morty-endpoint-review-1)
**Task boundary:** [2026-04-21T00:28Z]
**File:** launchers/morty-endpoint.ps1

### Top 2 Improvements

1. **Hardcoded model pattern is stale.** The script searches for `Qwen3-Coder-Next` but the bound model is now `user.Qwen3.6-35B-A3B-GGUF` (loaded via `/api/v1/health`). The script would fail silently on port 8000 because the health endpoint uses a different model name. Should accept the model name as a parameter or use a broader pattern.

2. **No caching / re-probing on stale results.** Once the script succeeds and returns an endpoint, callers have no way to refresh if the model unloads and reloads on a different port. Adding a TTL or a `--refresh` flag would help.

### Summary

The script is a simple port-scanner for a hardcoded model name. It works for its original intent but is brittle: it assumes a specific model name is present in the `/api/v1/models` response, doesn't handle the health endpoint path, and has no refresh mechanism.

## Phase 1 — OBSERVE: Review 2 (morty-endpoint-review-2)
**Task boundary:** [2026-04-21T00:28Z]
**File:** launchers/morty-endpoint.ps1

### Top 2 Improvements

1. **No error detail on failure.** The `catch {}` block does `continue` silently, so the user sees zero output until the final error line. Adding per-port failure logging (e.g., `Write-Verbose`) would let users diagnose which port failed and why (connection refused vs HTTP error vs model mismatch).

2. **Uses deprecated `-UseBasicParsing`.** On modern Windows (Win 11), `Invoke-WebRequest` works fine without `-UseBasicParsing`. This flag was needed for Windows PowerShell 5.1 on older systems. Removing it cleans up the call and avoids potential compatibility issues with future .NET changes.

### Summary

Review 2 focuses on error handling and modernization. The script swallows diagnostic info and uses a legacy flag. Both are low-risk fixes but would improve debuggability.

## Phase 1 — OBSERVE: Review 3 (morty-endpoint-review-3)
**Task boundary:** [2026-04-21T00:28Z]
**File:** launchers/morty-endpoint.ps1

### Top 2 Improvements

1. **Port list should be configurable.** The hardcoded `@(8000, 8001, 8004, 8080)` works for the current setup but breaks if Lemonade runs on a non-standard port. Accepting an environment variable or `$args` override would make it portable across environments.

2. **No verification that the loaded model is the *right* model.** The script checks that the model name matches a pattern in `/api/v1/models`, but that endpoint lists *all* models on the backend — not necessarily the one serving inference. A better approach would be to hit `/api/v1/health` and verify `model_loaded` matches the expected model.

### Summary

Review 3 focuses on portability and correctness. The script scans ports blindly and checks a potentially misleading endpoint. Adding env-var port configuration and health-endpoint verification would make it robust for production use.

## MINE [2026-04-21 01:46]

```json
{
  "ts": "2026-04-21T01:46:30.8952367Z",
  "journal_path": "C:/work/harness-sandbox\\logs\\morty-journal.jsonl",
  "tail_lines": 2000,
  "tasks_seen": 6,
  "tasks_closed": 3,
  "min_count": 2,
  "min_success_rate": 1.0,
  "candidates": []
}
```

**Note:** 3 tasks closed (3 endpoint reviews), but zero qualifying chains. Each review has a unique tool sequence — no pattern repeats >= 2 times. Additionally, tool_call entries in the journal have `task_id=""` despite task boundaries being set, so the miner sees 0 tool_call steps per task.

## ROOT CAUSE: task_id not propagated to tool_call entries

The `/task-begin` command in `.claude/commands/task-begin.md` only appends a journal anchor line. It does not propagate the task_id to Claude Code's native tool_call logging framework. All tool calls in the journal have `task_id=""`, so the chain-miner can never associate tool calls with tasks.

**Fix required:** The task-begin command must integrate with Claude Code's native task/task_id mechanism so that subsequent tool_call entries carry the task_id. This is likely a hook or settings.json configuration issue, not a script fix.

## Phase 3 — PROPOSE: /codify [2026-04-21T01:48Z]

**Result:** No proposal generated.

The MINE block contains zero qualifying chains. `/codify` requires at least one candidate chain meeting the threshold (count >= 2, success_rate == 1.0).

### DELTA entry

- **Candidate:** (none)
- **Reason:** No chains meet codification threshold
- **Root cause:** task_id not propagated to tool_call entries — chain-miner sees 0 tool_call steps per task, so no chains can form

### Two blockers preventing codification:

1. **task_id propagation gap:** `/task-begin` only appends a journal anchor; it doesn't affect Claude Code's native tool_call logging. All tool_calls have `task_id=""`.
2. **No repeated patterns:** Even with fixed task_id propagation, the 3 endpoint reviews have unique tool sequences (each reads a different file or does different edits). Need ≥2 tasks with the same tool sequence.

### What's needed:

- Fix the task_begin command to wire into Claude Code's native task/task_id context (likely a settings.json hook or Claude Code feature)
- Run ≥2 identical or similar tasks to produce a repeatable chain
- Then re-run chain-miner → /codify
