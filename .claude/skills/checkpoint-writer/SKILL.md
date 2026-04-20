---
name: checkpoint-writer
description: Use this when the session reaches ~60% context, when Mark invokes /checkpoint, or before any /compact. Writes CHECKPOINT.md at the project root summarizing state, appends a journal anchor so work survives compaction, and writes a typed row to memory.db for queryable history.
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
5. Write a structured row to `memory.db` via `mcp__sqlite__write_query`.

### Step 5 detail — SQLite memory write

First ensure the table exists:

```sql
CREATE TABLE IF NOT EXISTS checkpoints (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  ts            TEXT    NOT NULL,
  project       TEXT    NOT NULL,
  spec_path     TEXT,
  files_touched TEXT,
  decision      TEXT    NOT NULL,
  outcome       TEXT    NOT NULL,
  next_step     TEXT,
  journal_line  INTEGER
);
```

Then INSERT using `mcp__sqlite__write_query` with the values collected in
Step 1. Map fields as follows:

| Column         | Source                                                      |
|----------------|-------------------------------------------------------------|
| `ts`           | Current ISO-8601 UTC timestamp                              |
| `project`      | Basename of `$MORTY_PROJECT_ROOT`                           |
| `spec_path`    | Path to SPEC.md if one governs this session, else NULL      |
| `files_touched`| Comma-separated list of files written/edited this session   |
| `decision`     | One-line summary of the primary decision made               |
| `outcome`      | `$ARGUMENTS` passed to /checkpoint, or the next_action text |
| `next_step`    | One-line handoff to the next session                        |
| `journal_line` | Line count returned by journal-anchor                       |

Confirm `affected_rows == 1`. If the write fails, surface the MCP error
verbatim — do not silently skip.

Report the inserted `id` alongside the CHECKPOINT.md path.

## Gotchas

- Overwrite CHECKPOINT.md, do not append. The journal handles history.
- Keep CHECKPOINT.md under 300 lines. If longer, summarize harder.
- Never include secrets, API keys, or tokens in CHECKPOINT.md or memory.db.
- Never construct the INSERT by string-concatenating user input. Use the
  parameterized form that mcp__sqlite__write_query accepts.
- If `mcp__sqlite__list_tables` is unavailable, attempt CREATE TABLE anyway;
  SQLite's IF NOT EXISTS makes it idempotent.
- The SQLite write is supplementary — a failure here must not suppress the
  CHECKPOINT.md write or journal anchor that already succeeded.
