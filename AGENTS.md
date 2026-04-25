# Agent Namespace Conventions

This repository is worked on by multiple AI agents. Each agent writes to its own namespace to avoid cross-contamination.

| Directory | Owner | Purpose |
|-----------|-------|---------|
| `.claude/` | Morty (Claude Code) | Memories, playbooks, cases, skills, hooks |
| `.jules/` | Jules (Google Labs) | Learning logs, bolt notes |
| `.aifirst/runs/` | Shared | Per-task run artifacts, evidence files, plans |
| `logs/` | Morty (Claude Code) | Session journal (stream-tier, append-only) |

## Rules
- Agents MUST NOT write to another agent's namespace directory.
- `.aifirst/runs/T-*/` directories are task-scoped and owned by whichever agent executes the task.
- `AGENTS.md` is maintained by humans. Agents may propose changes via PR but must not edit it autonomously.
