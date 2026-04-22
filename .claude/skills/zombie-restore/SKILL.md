---
title: Skill — zombie-restore
version: 1.2
---

# Skill: zombie-restore

## Purpose

When Morty resumes after a `/clear`, crash, context window overflow, or session
handoff, validate memory integrity **before** loading or acting on any Tier-1
or Tier-2 content. No reconstruction without verification.

This is the **Zombie Protocol re-authentication gate** adapted from CyberMesh
and the MEMS Eigenmode PUF architecture: nothing is restored without first
confirming freshness, integrity, and provenance.

## When to Invoke

Invoke zombie-restore at the **start of the first task** after any of:
- Session `/clear`
- Cold start (new Claude Code session)
- Context overflow recovery
- Handoff from another session or agent

Do NOT invoke during a running session unless context overflow occurred.

## The Four-Gate Check

Answer all four gates in order. If any gate fails, follow the FAIL path.

### Gate 1 — Freshness
> Are the last 20 journal lines dated within 24 hours?

- Read: `powershell -Command "Get-Content logs/morty-journal.jsonl -Tail 20"`
- **PASS:** most recent entry timestamp < 24 hours ago → proceed to Gate 2.
- **FAIL:** stale or empty → load ONLY `MORTY.md` + `CLAUDE.md` + `03-context-hygiene.md`.
  Report to Mark: "Session state is stale — operating in minimal mode. Please confirm current task."

### Gate 2 — Checkpoint Integrity
> Does the journal contain a valid checkpoint entry within the last 24 hours?

- Search journal for entries where `kind` equals `"anchor"` OR `"checkpoint"`.
- Use: `powershell -Command "Get-Content logs/morty-journal.jsonl -Tail 50 | Select-String '\"kind\":\"checkpoint\"', '\"kind\":\"anchor\"'"`
- **PASS:** at least one matching entry exists with timestamp < 24 hours → proceed to Gate 3.
- **FAIL:** no matching entries → do NOT reconstruct from Tier-1 memories.
  Report to Mark: "No valid checkpoint found. Memory state unverified.
  Please confirm last known good state before proceeding."

### Gate 3 — Tier-1 Provenance
> Is each memories/*.md file backed by a post-write checkpoint in the journal?

- Get last checkpoint timestamp from journal (kind=anchor OR kind=checkpoint).
- Compare each `.claude/memories/*.md` LastWriteTime against that timestamp.
- Files modified **before** the latest checkpoint → **anchored**.
- Files modified **after** the latest checkpoint → **unanchored**.
- **PASS:** all files anchored → load normally.
- **PARTIAL:** some files unanchored → load all, tag unanchored files `(unverified)` in
  working context. Do not promote unverified files to higher tiers.
- **FAIL (all unanchored):** treat as Gate 2 FAIL.

### Gate 4 — LoRa-Mux Mode
> What is the current context fill level BEYOND the mandatory cold-start load?

The mandatory cold-start load (MORTY.md + CLAUDE.md + all memories/*.md) is
approximately **15–20% of the context window** and is always present. Gate 4
measures **additional** load beyond that baseline.

| Mode     | Additional load beyond boot | Behavior                          |
|----------|-----------------------------|-----------------------------------|
| WIDE     | < 20% additional            | Full reads, all on-demand files   |
| STANDARD | 20–50% additional           | Selective reads, playbooks only   |
| LORA     | > 50% additional            | Summary only, /compact before next|

**Default on a fresh cold start with no additional reads: STANDARD.**
Only escalate to LORA if the session has done significant file reads or
long reasoning chains beyond the boot sequence.

## After All Gates Pass

Proceed with the normal cold-start sequence from `00-cold-start.md`.
Log a brief zombie-restore result to SCRATCH.md:

```
## ZOMBIE-RESTORE [timestamp]
- Gate 1 Freshness: PASS / FAIL
- Gate 2 Checkpoint: PASS / FAIL
- Gate 3 Provenance: PASS / PARTIAL / FAIL
- Gate 4 LoRa-Mux mode: WIDE / STANDARD / LORA
- Result: PROCEED / MINIMAL-MODE / BLOCKED
```

## Result States (summary)

| State         | Meaning                              | Action                           |
|---------------|--------------------------------------|----------------------------------|
| PASS          | Journal clean, memories loaded       | Proceed to chain-seed            |
| PARTIAL       | Some memory files unanchored         | Load all, tag unanchored         |
| MINIMAL-MODE  | Degraded but runnable (Gate 1 FAIL)  | Warn Mark, proceed with caution  |
| FAIL          | Critical state corrupt               | Stop, report to Mark             |
| BLOCKED       | Cannot read journal or SCRATCH.md    | Stop completely                  |

After a successful run, hand off with:

```
ZOMBIE-RESTORE: [PASS|PARTIAL|MINIMAL-MODE]
Journal: [n lines], [n unclosed tasks]
Ready for chain-seed.
```

## Anti-patterns

| Anti-pattern | Why it breaks |
|---|---|
| Skip zombie-restore "to save time" | State corruption accumulates silently |
| Run zombie-restore mid-session | Overwrites a valid block with stale data |
| Report PASS without checking journal | False confidence — stale tasks persist |

## Hard Rules

- Never skip this gate sequence on cold start. Shortcuts create silent corruption.
- If blocked: always surface the block to Mark explicitly. Never silently degrade.
- This skill does not replace the Pre-Action Gate in `03-context-hygiene.md` —
  it runs BEFORE the cold-start sequence, not instead of it.
- The `echo` fallback (writing directly via Bash) is acceptable when
  `journal-anchor/scripts/append.ps1` is blocked by execution policy.
