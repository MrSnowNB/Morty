---
title: Skill — zombie-restore
version: 1.0
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
  Do not load any other memories. Report to Mark: "Session state is stale — operating
  in minimal mode. Please confirm current task."

### Gate 2 — Checkpoint Integrity
> Does CHECKPOINT.md contain a valid anchor?

- Read `CHECKPOINT.md`. A valid anchor has a `kind: anchor` field or an
  explicit checkpoint timestamp.
- **PASS:** valid anchor found → proceed to Gate 3.
- **FAIL:** no anchor or corrupted → do NOT reconstruct from Tier-1 memories.
  Report to Mark: "No valid checkpoint anchor found. Memory state unverified.
  Please confirm last known good state before proceeding."

### Gate 3 — Tier-1 Provenance
> Is each memories/*.md file backed by a post-write checkpoint anchor in the journal?

- For each file in `.claude/memories/`, check whether a journal anchor entry
  exists with a timestamp AFTER the file's last-modified date.
- **PASS:** all files are anchored → load normally.
- **PARTIAL:** some files unanchored → load those files but tag them
  `(unverified)` in your working context. Do not promote unverified files further.
- **FAIL (all unanchored):** treat as Gate 2 FAIL.

### Gate 4 — LoRa-Mux Mode
> What is the current context fill level?

- Estimate fill based on what has been loaded so far in this session.
- Set mode per `.claude/memories/06-tiered-memory.md` LoRa-Mux table.
- **Do not load additional files beyond what the selected mode permits.**

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

## Hard Rules

- Never skip this gate sequence on cold start. Shortcuts create silent corruption.
- If blocked: always surface the block to Mark explicitly. Never silently degrade.
- This skill does not replace the Pre-Action Gate in `03-context-hygiene.md` —
  it runs BEFORE the cold-start sequence, not instead of it.
