---
description: Snapshot current session state to CHECKPOINT.md and anchor the journal.
argument-hint: "[one-line outcome summary]"
---

Invoke the `checkpoint-writer` skill, passing `$ARGUMENTS` as the outcome
summary. If `$ARGUMENTS` is empty, ask Mark for a one-line outcome before
proceeding — do not guess.

Report:
- CHECKPOINT.md path
- Journal line count
- next_step
