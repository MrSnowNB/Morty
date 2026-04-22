---
title: Skill — delta-log
version: 1.2
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
- Writing or updating any `.claude/skills/` file
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

## Step-by-step Procedure

1. Before any destructive write, open `SCRATCH.md` with a Read call.
2. Append the delta block (see format above) using an Edit or Write.
3. Confirm the entry is visible in `SCRATCH.md` with a second Read.
4. Proceed with the actual write only after step 3 confirms the delta is logged.

## Integrity Tag Generation

For memory files and playbooks, compute a short CRC32 of the file content:

```powershell
$bytes = [System.IO.File]::ReadAllBytes($path)
$crc   = [System.IO.Hashing.Crc32]::Hash($bytes)
[Convert]::ToHexString($crc)
```

For large files, use the first 8 hex chars of SHA256 instead:

```powershell
$sha   = [System.Security.Cryptography.SHA256]::Create()
$bytes = [System.IO.File]::ReadAllBytes($path)
$hash  = $sha.ComputeHash($bytes)
(($hash | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 8)
```

## Failure Recovery

If the actual write fails AFTER the delta is written:

- The delta entry in `SCRATCH.md` is the recovery artifact.
- Do NOT delete or edit the delta entry.
- Write a ROLLBACK note below the delta entry:
  `## ROLLBACK [timestamp] — [reason write failed]`
- Report to Mark.

## Anti-patterns

| Anti-pattern | Why it breaks |
|---|---|
| Write delta AFTER the destructive action | Defeats the entire audit purpose |
| Use delta-log for read-only tool calls | Noise — pollutes `SCRATCH.md` |
| Edit a delta entry after writing it | Makes the trail untrustworthy |
| Log the delta-log invocation itself | Recursive loop |

## Rules

- Delta entries are **append-only**. Never edit or delete a delta entry within a session.
- If an action fails after the delta is written, the delta entry IS the recovery artifact.
- After session end, `SCRATCH.md` may be cleared — but only after `/checkpoint` is invoked.
- Do NOT invoke delta-log recursively (i.e., do not log the act of logging).
