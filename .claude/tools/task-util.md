---
title: Tool — task-util
version: 1.0
purpose: Unified task lifecycle management — open, close, list, status
author: Morty (based on journal pattern analysis)
trigger: when Morty needs to manage task boundaries during any session
---

# Tool: task-util

## Purpose

Unified tool for task lifecycle management. Replaces separate task-begin and
task-end skill invocations with a single, idempotent tool that:
1. Opens tasks with automatic task_id tracking
2. Closes tasks with configurable exit status
3. Lists open tasks
4. Reports task status

## Interface

The tool is invoked as a Bash command:
```powershell
pwsh -NoProfile -Command "& 'C:/work/harness-sandbox/.claude/tools/task-util.ps1' <action> [options]"
```

## Actions

### open
Open a new task boundary.
```powershell
task-util open <task-id> --summary "<brief description>"
```
- Creates task_begin anchor in journal
- Sets MORTY_TASK_ID env var for subsequent tool calls
- Returns: task_id, timestamp

### close
Close the current task.
```powershell
task-util close --status <success|partial|fail|skip> --summary "<outcome>"
```
- Creates task_end anchor in journal
- Clears MORTY_TASK_ID
- Returns: task_id, exit_status

### list
List all open tasks.
```powershell
task-util list
```
- Returns: JSON array of open task_ids with timestamps

### status
Get status of a specific task.
```powershell
task-util status <task-id>
```
- Returns: task_id, begin_ts, end_ts (if closed), exit_status

## Architecture

The tool is a single PowerShell script at:
`.claude/tools/task-util.ps1`

It handles:
- Journal writing (same mutex approach as post-tool.ps1)
- Step counter management (same as task-begin)
- Env var propagation (MORTY_TASK_ID)
- Task state validation (no double-open, no double-close)

## Design Decisions

1. **Single script**: Simpler to maintain than separate skills
2. **JSON output**: Consistent parsing for chain-miner
3. **Idempotent open/close**: Safe to retry
4. **No file writes**: All state in journal + env vars
5. **Backward compatible**: Doesn't break existing task-begin/task-end skills

## Gotchas

- Must use `pwsh -NoProfile -Command` wrapper (Windows PowerShell compatibility)
- Env var MORTY_TASK_ID is session-scoped, not persistent
- Task states are journal-only (no database)
- Step counter uses file-based mutex (Global\MortyStepCounter)
