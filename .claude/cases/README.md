# Case Library

This directory contains first-principles case entries — structured records of
diagnosed problems, their root causes, applied fixes, and reusable heuristics.

When a new problem arrives, search here before re-deriving from scratch.
A class of problems should only need to be fully reasoned through once.

## When to write a case entry

- After any first-principles session that reached a confirmed root cause
- After any bug that took more than one hypothesis to diagnose
- After any infrastructure failure (context overflow, tool block, permission
  error) that could recur

## Format

Each file follows this structure:

1. **Symptom** — what the user or system observed
2. **Five Whys** — root cause chain down to the systemic level
3. **Root Cause** — the bottom-level cause
4. **Bandage Applied** — any immediate workaround used
5. **Durable Fix** — the structural change that prevents recurrence
6. **Reusable Heuristics** — generalizable lessons for future solves

## Index

| File | Problem | Date |
|---|---|---|
| `journal-anchor-never-invoked.md` | `/introspect` shows raw tool call instead of anchor summary | 2026-04-20 |
| `context-overflow-lemonade.md` | Morty unresponsive due to 64K context overflow on llama.cpp | 2026-04-20 |
| `slash-cmd-vs-skill-confusion.md` | `Skill()` wrapper used for built-in slash commands | 2026-04-20 |
| `memory-db-does-not-exist.md` | `memory.db` referenced but not present; SQLite path is dead | 2026-04-20 |
| `anchor-buried-by-subsequent-tool-calls.md` | Anchor written mid-session, buried by later tool calls | 2026-04-20 |
