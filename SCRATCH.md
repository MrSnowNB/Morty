# FP Solve: task-id-propagation — 2026-04-22

## Problem Statement

Chain-seed produces 0 candidates because tool_call entries during seed tasks get the wrong `task_id`. Root cause: two separate bugs — (1) `task_util.ps1 -Action open` sets env in subprocess, not agent process; (2) `/task-begin` is a custom slash command the AI agent cannot invoke itself.

## Known Context

- Subagents disabled; Task tool denied.
- Windows 11, PowerShell 7 shell.
- Claude Code agent runs on Qwen3-Coder-Next-GGUF via local llama.cpp server.
- `/task-begin <slug>`: custom command that sets `$env:MORTY_TASK_ID` in agent process + writes journal entry. Only triggered when user types it.
- `task_util.ps1 -Action open`: child PowerShell process — env changes don't affect agent.

## Ground Truths

- GT-1: Child process env changes never propagate to parent process.
- GT-2: Claude Code injects `task_id` from its internal task boundary state.
- GT-3: `/task-begin <slug>` sets `$env:MORTY_TASK_ID` in the AGENT process — but only when user types it.
- GT-4: `task_util.ps1 -Action open` runs in child PowerShell — env changes don't affect agent.
- GT-5: AI agent cannot type custom slash commands — only built-in ones (`/checkpoint`, `/compact`, etc.).
- GT-6: Chain-miner groups tool_call entries by `task_id` field.
- GT-7: Chain-seed requires identical tool sequences within correct task boundaries.

## Diagnosis

| Bug | Cause | Fix |
|---|---|---|
| B1: Subprocess env doesn't propagate | task_util.ps1 runs in child PowerShell | Use agent-level task management |
| B2: Agent can't invoke /task-begin | Custom slash commands require user input | Agent must write task_begin entries directly |

## Solution

Option A: Agent writes task_begin/task_end entries directly (as a Bash tool call that echoes to journal, not via task_util.ps1 subprocess).

Option B: Agent sets `$env:MORTY_TASK_ID` via a Bash call that persists to the agent process env (not possible — Bash runs in subprocess).

Option C: User types `/task-begin <slug>` before each chain-seed run (manual, error-prone).

Option A is the only fully automated path. The agent can write journal entries directly via `Write` tool or Bash with `Add-Content` to the journal file.

## Post-Mortem (Phase 8)

- Problem: Chain-seed produces 0 candidates due to wrong task_id on tool_call entries.
- Breakthrough: Identified that task_util.ps1 runs in subprocess (GT-1, GT-4) and /task-begin requires user input (GT-3, GT-5).
- Failed approaches: fp-a/fp-b via task_util.ps1; cs-test-a unclosed task bleed.
- Reusable heuristic: When a tool needs to affect the agent's own state (env vars, task boundaries), it must run as a built-in tool or command — not as a subprocess script.
- Candidate skill edit: Update chain-seed playbook to use agent-level task management (direct journal writes + env var awareness).
