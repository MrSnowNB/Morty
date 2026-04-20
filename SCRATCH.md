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

## ZOMBIE-RESTORE [2026-04-20T23:25 UTC] — CURRENT RUN

### Gate 1 — Freshness: PASS
- Last journal entry: 2026-04-20T23:25:18Z (within 24 hours)

### Gate 2 — Checkpoint Integrity: PASS
- Found `kind:checkpoint` entry at 2026-04-20T23:20:00Z
- Summary: "Zombie-restore gate check: G1 PASS, G2 PASS, G3 PARTIAL, G4 LORA"

### Gate 3 — Tier-1 Provenance: PASS
- Latest checkpoint: 2026-04-20T23:20:00Z
- All 7 memory files modified before checkpoint (earliest: 09:48, latest: 19:05)
- All files anchored

### Gate 4 — LoRa-Mux Mode: STANDARD
- Fresh cold start, only mandatory boot sequence loaded
- No additional context beyond baseline
- Default mode per policy: STANDARD

### Result: PROCEED

## ZOMBIE-RESTORE [2026-04-20T23:07 UTC] — PREVIOUS RUN

- Gate 1 Freshness: PASS — last journal entry 2026-04-20T23:07Z (within 24h)
- Gate 2 Checkpoint: FAIL — CHECKPOINT.md exists but no `kind: anchor` field; journal contains zero `kind: anchor` entries
- Gate 3 Provenance: FAIL — all 7 memory files unanchored (zero anchors in journal)
- Gate 4 LoRa-Mux mode: WIDE — fresh session, minimal accumulated context (~30% fill)
- Result: BLOCKED — Gates 2 and 3 failed; no valid checkpoint anchor, no tier provenance
