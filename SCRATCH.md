# FP Solve: architecture-canonical — 2026-04-22

## Problem Statement

The repo has five overlapping systems (hooks, tools, cases, commands, playbooks) all doing task lifecycle management. The task_id propagation bug is a direct symptom: three competing mechanisms for opening a task boundary with no consistency. Each "fix" creates a new surface requiring another fix. The repo needs a single source of truth — an architecture canonical — before any more code is written.

## Known Context

- Five systems: hooks (`.claude/hooks/`), tools (`.claude/tools/`), cases (`cases/` + `.claude/cases/`), commands (`.claude/commands/`), playbooks (`.claude/playbooks/`)
- Five different places doing task lifecycle management
- task_id propagation bug: subprocess env never reaches agent process
- Mine.ps1 modified with timestamp-based boundary matching — a workaround, not a fix
- Chain-seed playbook modified with direct journal writes — also a workaround
- Agent cannot invoke custom slash commands; `/task-begin` is user-only
- `task_util.ps1` runs in subprocess — env changes don't propagate
- Two `cases/` directories: root `/cases/` and `.claude/cases/`

## Ground Truths

- GT-1: Child process env changes never propagate to parent process.
- GT-2: Claude Code injects `task_id` from agent's internal task boundary state.
- GT-3: `/task-begin` is a custom user-facing command; AI agent cannot invoke custom slash commands.
- GT-4: Five overlapping systems all touching task lifecycle with no single source of truth.
- GT-5: Each "fix" creates a new surface requiring another fix — complexity migrates, doesn't disappear.
- GT-6: Hooks fire on every tool call natively in the agent process context.
