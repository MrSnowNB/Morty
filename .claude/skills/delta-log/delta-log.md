---
title: Skill — delta-log
version: 1.0
---

# Skill: delta-log

## Purpose

Before any file write, memory promotion, or destructive action, emit a
structured delta entry to `SCRATCH.md`. This creates a reversible, append-only
audit trail at Tier-0 that persists for the duration of the session.

This is the **progressive atomic tooling** primitive: every non-trivial action
is decomposed into a delta artifact before it is committed.

## When to Invoke

Invoke delta-log **before** any of the following:
- Writing or updating any `.claude/memories/*.md` file
- Writing or updating any `.claude/playbooks/*.md` file
- Writing or updating any `.claude/skills/*.md` file
- Any journal anchor entry (`/checkpoint`)
- Any `git commit` that touches `.claude/`
- Any destructive or irreversible file operation

Do NOT invoke for: read-only operations, Bash commands that only print output,
or purely exploratory tool calls with no side effects.

## Delta Entry Format

Append to `SCRATCH.md`:

```
## DELTA [YYYY-MM-DD HH:MM] [action-type]
- **What changed:** <one sentence — what file or state>
- **Why:** <one sentence — what task or decision drove this>
- **Invariant preserved:** <which Pre-Action Gate invariant applies>
- **Rollback:** <exact step to undo — delete file / revert content / etc.>
- **Integrity tag:** <SHA or CRC of key content, or "n/a">
```

## Example

```
## DELTA 2026-04-20 19:00 memory-promotion
- **What changed:** Created .claude/memories/07-first-principles.md
- **Why:** Recursive first-principles loop pattern survived 2 successful tasks
- **Invariant preserved:** Memory injection budget stays under 8,000 tokens
- **Rollback:** Delete .claude/memories/07-first-principles.md
- **Integrity tag:** n/a
```

## Rules

- Delta entries are **append-only**. Never edit or delete a delta entry within a session.
- If an action fails after the delta is written, the delta entry IS the recovery artifact.
- After session end, SCRATCH.md may be cleared — but only after `/checkpoint` is invoked.
- Do NOT invoke delta-log recursively (i.e., do not log the act of logging).
