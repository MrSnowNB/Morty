---
description: Close the current task boundary with an outcome, so the chain-miner can score the chain. Must run before /checkpoint.
argument-hint: "success|partial|fail [one-line note]"
---

Close the current task boundary and record its outcome.

1. Read `$env:MORTY_TASK_ID`. If empty, report `no task open` and stop.
2. Parse `$ARGUMENTS`: first token must be `success`, `partial`, or `fail`.
   The remainder (optional) is a one-line note. If the first token is invalid,
   ask Mark — do not guess the outcome.
3. Invoke the `journal-anchor` skill with this payload:

   ```json
   {
     "ts": "<ISO-8601 UTC>",
     "agent_id": "morty",
     "task_id": "<current>",
     "kind": "task_end",
     "summary": "<outcome>: <note or empty>",
     "next_action": null
   }
   ```

4. Clear `$env:MORTY_TASK_ID` and delete `logs/.step-counter`.
5. Report the task_id, the outcome, and the journal line count.

## Gotchas

- `/task-end` must precede `/checkpoint`. Order matters: the checkpoint anchor
  references the most recent task_end outcome. Running them in reverse buries
  the outcome (see case `anchor-buried-by-subsequent-tool-calls.md`).
- Never close a task you did not open. If the task boundary is stale from a
  prior session, run `/task-end partial "resumed from stale boundary"` and
  start fresh with `/task-begin`.
- Outcome `success` has governance weight — it makes the chain eligible for
  codification. Do not claim success unless the user-visible goal was met.
