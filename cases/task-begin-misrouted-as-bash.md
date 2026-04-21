# Case: task-begin misrouted as Bash command

**Date:** 2026-04-20  
**Session:** test-self-improvement  
**Severity:** Low — task recoverable; journal entry lost, not corrupted

## Symptom
`/task-begin test-self-improvement` was invoked via `Bash(/TaskBegin)`,
producing `Exit code 127: /usr/bin/bash: /TaskBegin: No such file or directory`.
No `kind:task_begin` entry was written to the journal. The task opened via
the task-list UI but had no journal anchor.

## Root Cause
Slash commands are Claude Code UI primitives — they must be typed directly
in the prompt, not wrapped inside a `Bash(...)` tool call. The model
attempted to invoke the command programmatically instead.

## Detection
- `Bash(type /task-begin)` error: `/task-begin: not found`
- Journal tail missing `kind:task_begin` for the task ID
- Chain-miner will silently discard the task (no valid boundary pair)

## Fix
1. Type `/task-begin <id>` directly at the prompt — never inside a tool call.
2. If a task opens without a clean anchor, close it with `/task-end` using
   `exit_status=aborted` and log the reason in `logs/close-dangling-task.md`.

## Reusable Invariant
> Slash commands (`/task-begin`, `/task-end`, `/checkpoint`, `/compact`,
> `/introspect`, `/codify`) are UI primitives. They cannot be invoked via
> `Bash(...)`, `pwsh -Command`, or any tool call. Always type them directly.
