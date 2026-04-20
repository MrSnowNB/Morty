# Case: Skill() wrapper used for built-in slash commands

**Date:** 2026-04-20  
**Observed during:** Session test (context hygiene + case library validation)

## Symptom

Morty called `Skill(/introspect)` and then `Task Output introspect`, received
`Error: No task found with ID: introspect`, and repeated the same pattern for
`/checkpoint`. Neither command executed. Morty then fell back to reading the
journal directly by accident, which happened to work.

## Root Cause

Morty conflated two distinct invocation systems:

- **`Skill(name)`** loads a `.md` skill file into context. It does not execute
  any slash command behavior.
- **`/checkpoint`, `/introspect`, `/compact`** are native Claude Code built-in
  slash commands. They are typed directly into the session prompt, not wrapped
  in any tool call.

No documentation in `MORTY.md` or `memories/` distinguished these two systems.

## Fix Applied

Added a **"Slash Commands vs Skills"** section to `MORTY.md` with explicit
rules. Added a matching clarification block to `03-context-hygiene.md`.

## Reusable Heuristics

- If a slash command returns `No task found`, Morty is calling it wrong
- Built-in slash commands: `/checkpoint`, `/compact`, `/introspect`, `/clear`, `/init`
- These are typed directly — never wrapped in `Skill()`, `Task Output`, or `Bash()`
- Custom slash commands in `.claude/commands/` are also typed directly, not via `Skill()`
