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

## ZOMBIE-RESTORE [2026-04-20T23:15 UTC] — REFRESHED

### Gate 1 — Freshness: PASS
- Last journal entry: 2026-04-20T23:12:20Z (within 24 hours)

### Gate 2 — Checkpoint Integrity: FAIL
- CHECKPOINT.md exists but contains NO `kind: "anchor"` field
- Journal has `kind: "checkpoint"` entries (lines 94, 118, 156) but zero `kind: "anchor"` entries
- The journal-anchor skill was invoked (line 155) but did not produce valid anchor entries

### Gate 3 — Tier-1 Provenance: FAIL
- All 7 memory files (00-06) are unanchored
- Zero `kind: "anchor"` entries exist in the journal
- Total provenance failure — no memory file has a post-write checkpoint anchor

### Gate 4 — LoRa-Mux Mode: LORA
- All 6 memory files + CLAUDE.md + MORTY.md already loaded at cold start
- Context fill estimated > 70%
- Per LoRa-Mux table: > 70% → LORA mode

### Result: MINIMAL-MODE

## ZOMBIE-RESTORE [2026-04-20T23:07 UTC] — PREVIOUS RUN

- Gate 1 Freshness: PASS — last journal entry 2026-04-20T23:07Z (within 24h)
- Gate 2 Checkpoint: FAIL — CHECKPOINT.md exists but no `kind: anchor` field; journal contains zero `kind: anchor` entries
- Gate 3 Provenance: FAIL — all 7 memory files unanchored (zero anchors in journal)
- Gate 4 LoRa-Mux mode: WIDE — fresh session, minimal accumulated context (~30% fill)
- Result: BLOCKED — Gates 2 and 3 failed; no valid checkpoint anchor, no tier provenance
