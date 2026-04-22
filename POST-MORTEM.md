# First Principles Post-Mortem — task-id-propagation

## Problem

Chain-seed produces 0 candidates because tool_call entries during seed tasks get the wrong `task_id`. The `task_util.ps1 -Action open` subprocess sets `$env:MORTY_TASK_ID` in a child PowerShell process, but Claude Code's agent runtime injects `task_id` into tool_call entries from its own internal task boundary state. Child process env changes never propagate to the parent process.

## Outcome

Two distinct bugs identified:
- **B1**: `task_util.ps1` runs in subprocess — env changes don't affect agent process.
- **B2**: `/task-begin` is a custom slash command that AI agent cannot invoke (requires user input).
- **Solution path**: Agent should write task_begin/task_end entries directly to the journal file, bypassing the subprocess env barrier entirely.

## Breakthrough

Realizing that `/task-begin` is a user-facing custom command (not callable by the agent) while `task_util.ps1` is a subprocess-only helper. The agent needs to write journal entries directly — there's no middle layer between agent process and journal file.

## Failed Paths

- FP-a/fp-b via `task_util.ps1 -Action open`: all tool calls got `task_id: mine-fix-1`.
- cs-test-a unclosed task bleed: caused stale task_id to persist.
- Grep for `MORTY_TASK_ID` in hook files: confirmed no hook bridges subprocess→agent env.

## Ground Truths That Mattered Most

- GT-1: Child process environment changes never propagate to parent process (OS guarantee).
- GT-2: Claude Code injects `task_id` from agent's internal task boundary state.
- GT-3: `/task-begin` is a custom user-facing command; AI agent cannot invoke custom slash commands.
- GT-5: Subprocess env = one-way channel (parent → child), never child → parent.

## Reusable Heuristics

- When a tool needs to affect the agent's own state (env vars, task boundaries), it must run as a built-in tool or command — not as a subprocess script.
- If the agent can't type it, the agent can't invoke it. Custom slash commands are user-only.
- A dead end that is logged is progress. The journal analysis revealed the task_id mismatch pattern.

## Candidate Durable Updates

- Update `chain-seed.md` playbook: replace `task_util.ps1 -Action open` with direct journal writes.
- Update `task-begin.md` command: document that `/task-begin` is user-facing only; agent must use direct journal writes.
- Consider: `task_util.ps1` should be deprecated or refactored to write journal entries directly (not just set subprocess env).

## Handoff

Next session should:
1. Update `chain-seed.md` playbook to use direct journal writes for task_begin/task_end entries.
2. Run chain-seed pair (`/task-begin journal-health-1` and `/task-begin journal-health-2` — user types the commands).
3. Verify mine.ps1 returns `candidates >= 1`.
