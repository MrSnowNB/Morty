---
title: Tiered Memory — Three-Tier Model
version: 1.0
scope: session-global
---

# Tiered Memory — Three-Tier Model

Morty's memory is organized into three tiers inspired by CyberMesh distributed
memory architecture. Nothing leaves a tier without passing a gate. Nothing is
reconstructed without verifying integrity first.

## Tier-0: SCRATCH.md (Local / Hot)
- Write here for any in-progress reasoning, intermediate state, and
  first-principles scratchpads.
- Never read SCRATCH.md into context speculatively — only when the current
  step explicitly requires it.
- SCRATCH.md is volatile. It does NOT survive a `/clear`.
- Delta entries are append-only within a session. Do not delete them.
- Promote to Tier-1 only after completing a task AND passing the Pre-Action Gate.

## Tier-1: .claude/memories/*.md (Neighborhood / Warm)
- These files are injected at cold start within the 8,000-token hard cap.
- Write a new numbered memory file (e.g. `07-*.md`) only when a finding:
  (a) survives task completion,
  (b) is NOT already covered by an existing memory,
  (c) passes the Pre-Action Gate (see `03-context-hygiene.md`).
- Promotion action: write the file, then immediately invoke `/checkpoint`.
- Maximum combined size: stay within cold-start token budget (see `03-context-hygiene.md`).
- Each memory file: soft cap 500 tokens.

## Tier-2: .claude/playbooks/ + logs/ (Archive / Cold)
- Playbooks are validated operational procedures. Promote from Tier-1 only when
  a procedure has been executed successfully **at least twice** (verify in journal).
- Journal (`logs/morty-journal.jsonl`) is append-only ground truth.
  Never rewrite. Never read in full during an active session.
- Use playbook: `.claude/playbooks/tiered-memory-promote.md` for all promotions.

---

## LoRa-Mux Policy (context bandwidth mode)

Set mode based on current context fill level. Check fill before loading any
additional files beyond the cold-start minimum.

| Mode     | Trigger         | Tier-0       | Tier-1 reads        | Tier-2 reads      | Rank  |
|----------|----------------|--------------|---------------------|-------------------|-------|
| WIDE     | fill < 40%     | full read    | all memories files  | on demand         | r=32  |
| STANDARD | fill 40–70%    | full read    | last-3 modified     | playbooks only    | r=16  |
| LORA     | fill > 70%     | summary only | `03` + `04` only   | none              | r=8   |

### LoRa Mode Rules
- In LORA mode: write SCRATCH.md aggressively, do NOT read it back.
- Run `/compact` before the next task in LORA mode.
- Do NOT promote to Tier-1 or Tier-2 while in LORA mode — defer to next session.
- Advertise current mode in any journal anchor entry: `"lora_mux": "LORA"`.

### Rank Meaning
- **r=32 (WIDE):** full detail, deep context, complex reasoning chains allowed.
- **r=16 (STANDARD):** default operating mode, normal task execution.
- **r=8 (LORA):** compressed summaries only, no new memory reads, immediate compact.
