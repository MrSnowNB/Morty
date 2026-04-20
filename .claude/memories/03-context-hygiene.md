# Context Hygiene

- Invoke `/compact` at task boundaries. Do not wait for auto-compact.
- Invoke `/checkpoint` when context exceeds ~60% of the window.
- **Invoke `/checkpoint` automatically after any non-trivial task completes — do not wait for Mark to ask.**
- Prefer `@path/to/file` imports over pasting file contents.
- Do not read files "just to be safe." Read only what the current step needs.
- When summarizing for compaction, preserve: project overview, current focus,
  recent decisions, next action. Discard everything else.

## Context Overflow Prevention

The lemonade server hard-rejects requests that exceed the configured context
size with a 400 error. Claude Code's built-in compaction does NOT work against
a local llama.cpp server — `context_management` and `thinking.type: adaptive`
fields are silently ignored, so the payload grows on each retry instead of
shrinking. **There is no automatic recovery once the window is exceeded.**

Rules to prevent overflow:

- Monitor fill level. If a session has involved heavy file reads, long
  reasoning chains, or skill execution, assume context is high.
- At ~70% fill: run `/compact` immediately, before the next task.
- At ~80% fill: run `/checkpoint` then `/compact` in sequence.
- Never read `morty-journal.jsonl` in full during an active session.
- Never paste large file contents inline — always use `@path/to/file`.
- First-principles sessions are high-risk for overflow. Write intermediate
  state to `SCRATCH.md` aggressively and compact between phases.

## Token Budgets (cold start)

- Total memory injection at cold start: ≤ 20% of the active model context window.
- `MORTY.md` + `CLAUDE.md` + all `memories/*.md` combined: hard cap 8 000 tokens.
- Journal rehydration on cold start: query the last 5 rows from `memory.db`
  via `mcp__sqlite__read_query` — do NOT read `morty-journal.jsonl` directly.
- If the budget would be exceeded, run `/compact` before the first user turn.

## Bounded Memory Reads

- Commands and skills must never call `filesystem.read_file` on
  `morty-journal.jsonl` during normal operation. The file is append-only
  ground truth and is read only when Mark explicitly invokes `/journal`.
- Use `mcp__sqlite__read_query` against `checkpoints` with an explicit
  `LIMIT` clause for all programmatic history lookups:

  ```sql
  SELECT id, ts, project, decision, outcome, next_step
  FROM   checkpoints
  ORDER  BY id DESC
  LIMIT  5;
  ```

- If `memory.db` does not yet contain a `checkpoints` table (first run),
  fall back to reading the last 20 lines of `morty-journal.jsonl` once,
  then immediately run `/checkpoint` to seed the table.

## Checkpoint Discipline

The `journal-anchor` skill only writes anchor entries when explicitly invoked.
`/introspect` reads the last anchor entry to display session state. If
`journal-anchor` is never called, `/introspect` falls back to the last
tool-call line, which is meaningless.

Rules:

- After any first-principles session: invoke `/checkpoint` before closing.
- After any spec, design, or architecture decision: invoke `/checkpoint`.
- After any skill edit or new skill creation: invoke `/checkpoint`.
- At session end (before `/clear` or handoff): always invoke `/checkpoint`.
- The `wc -l` Bash command is NOT an anchor. Do not use it as a journal probe.
