# Context Hygiene

- Invoke `/compact` at task boundaries. Do not wait for auto-compact.
- Invoke `/checkpoint` when context exceeds ~60% of the window.
- Prefer `@path/to/file` imports over pasting file contents.
- Do not read files "just to be safe." Read only what the current step needs.
- When summarizing for compaction, preserve: project overview, current focus,
  recent decisions, next action. Discard everything else.

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
