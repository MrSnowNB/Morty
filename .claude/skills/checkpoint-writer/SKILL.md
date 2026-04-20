---
name: checkpoint-writer
description: Use this when the session reaches ~60% context, when Mark invokes /checkpoint, or before any /compact. Writes CHECKPOINT.md at the project root summarizing state and appends a journal anchor so work survives compaction.
---

# Checkpoint Writer

## When to use

- Context usage is at approximately 60% or more.
- Before invoking `/compact`.
- At a natural task boundary.

## Steps

1. Summarize in this order: project overview, current focus, recent decisions,
   open questions, next action.
2. Write `$MORTY_PROJECT_ROOT/CHECKPOINT.md` with those sections.
3. Invoke `journal-anchor` with `kind: "checkpoint"` and the summary.
4. Report the CHECKPOINT.md path and the journal line count.

## Gotchas

- Overwrite CHECKPOINT.md, do not append. The journal handles history.
- Keep CHECKPOINT.md under 300 lines. If longer, summarize harder.
- Never include secrets, API keys, or tokens in CHECKPOINT.md.
