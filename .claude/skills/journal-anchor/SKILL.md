---
name: journal-anchor
description: Use this when Morty needs to record a durable trace of work — a completed task, a decision, a checkpoint, or a session boundary. Appends a structured anchor entry to the project journal so state survives context compaction.
---

# Journal Anchor

## When to use

- After completing a task (anchor kind: "done").
- Before `/compact` (anchor kind: "checkpoint").
- When making a non-obvious decision (anchor kind: "decision").
- At session close (anchor kind: "close").

## Steps

1. Determine journal path: `$MORTY_PROJECT_ROOT/logs/morty-journal.jsonl`.
2. If `logs/` does not exist, create it.
3. Invoke `scripts/append.ps1` with JSON payload on stdin.
4. Confirm the append succeeded by reading the last line back.

## Payload schema

```json
{
  "ts": "ISO-8601 UTC",
  "agent_id": "morty",
  "task_id": "<slug or null>",
  "kind": "done|checkpoint|decision|close|issue|task_begin|task_end",
  "summary": "one line",
  "next_action": "one line or null"
}
```

## Task boundary kinds (v2)

- `task_begin` — emitted by `/task-begin`. Marks the start of a mineable chain.
- `task_end`   — emitted by `/task-end`. `summary` must start with `success:`,
  `partial:`, or `fail:` so the chain-miner can score the chain without
  parsing free text.

## Gotchas

- Writes must be atomic. Use the mutex in `append.ps1`, never direct `Out-File`.
- Never edit previous lines. Append only.
- Keep `summary` under 200 characters.
