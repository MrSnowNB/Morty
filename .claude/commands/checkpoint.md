---
description: Snapshot current session state to CHECKPOINT.md and anchor the journal.
---
Invoke the `checkpoint-writer` skill.

Write CHECKPOINT.md with: project overview, current focus, recent decisions,
open questions, next action. Then invoke `journal-anchor` with kind="checkpoint".

Report the checkpoint path and journal line count.
