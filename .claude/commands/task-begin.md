---
description: Open a task boundary in the journal. Sets MORTY_TASK_ID so subsequent tool calls are grouped into a mineable chain.
argument-hint: "<kebab-case-slug>"
---

Open a task boundary so the chain-miner can group the subsequent tool calls.

1. Validate `$ARGUMENTS`: must be a short kebab-case slug (e.g. `add-readme-section`,
   `fix-anchor-lookup`). If empty or invalid, ask Mark for a slug — do not guess.
2. Set `$env:MORTY_TASK_ID = "<slug>"` for the current session.
3. Reset the step counter for this task by removing `logs/.step-counter` if present.
4. Invoke the `journal-anchor` skill with this payload:

   ```json
   {
     "ts": "<ISO-8601 UTC>",
     "agent_id": "morty",
     "task_id": "<slug>",
     "kind": "task_begin",
     "summary": "Task started: <slug>",
     "next_action": null
   }
   ```

5. Report: `task_id = <slug>` and a reminder that `/task-end` must be invoked
   before `/checkpoint` at task completion.

## Gotchas

- Only ONE task may be open at a time. If `$env:MORTY_TASK_ID` is already set,
  ask Mark whether to close the prior task with `/task-end partial` first.
- Do not open a task for purely exploratory sessions — chains without clear
  goals poison the miner's outcome signal.
