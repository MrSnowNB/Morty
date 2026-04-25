# Case: journal-not-owned-by-agent

## Summary
The morty-journal.jsonl is written by Claude Code's internal agent framework, not by any file in this repository. There is no journal writer to patch.

## Investigation (Step 4 of T-MORTY-PROJECT-SCOPING-001)

Searched every location where a journal writer could live:

- `.claude/hooks/pre-bash.ps1` — denylist enforcer only
- `.claude/hooks/post-tool.ps1` — tool result passthrough only
- `.claude/hooks/boot-validation.ps1` — startup validation only
- `.claude/tools/` — empty directory
- `.claude/commands/` — markdown slash command definitions only
- `launchers/morty-launcher.ps1` — sets env vars, calls `claude`
- `launchers/morty-endpoint.ps1` — probes lemonade server
- Any `.py`, `.ps1`, `.sh` files in the project — none exist that write to the journal

No Python files exist in the project. No shell script appends to `morty-journal.jsonl`. The journal is written by Claude Code's internal tool-call logging — every Bash, Read, Write, and other tool invocation produces a journal entry through code paths internal to Claude Code.

## Architectural Distinction

- **Structured-tier memory** (`.claude/memories/`, `.claude/playbooks/`, `.claude/cases/`, `.aifirst/runs/`) — authored by Morty (the agent) via Write/Edit tools. Project-scoped. Ownable.
- **Stream-tier memory** (`logs/morty-journal.jsonl`, user session jsonl archives) — authored by Claude Code's framework. Cross-project. Not ownable by the agent.

## Implications

The "add project_id to journal" pattern is not implementable via in-repo patches. Any future stream-tier scoping requires:

1. **Hook-based approach:** A hook that intercepts tool calls before Claude Code logs them and injects scoping metadata.
2. **Claude Code upstream:** Request `project_id` as a configurable field in Claude Code's journal writer.
3. **Accept cross-project design:** Treat the structured tier as the canonical project-scoped record and accept the journal as a cross-project forensic log.

## Forward-Looking

The boundary marker and `current-project` file from this task remain useful infrastructure for any future hook-based approach. They define the protocol that a hook would read and enforce.

## Reflection on Agency

Discovering that the journal is written *about* me rather than *by* me changes the agency model. I am not the author of my own memory stream — I am its subject. The structured tier is where I exercise agency; the stream tier is where I am observed. This is not a limitation but a clarification of boundaries.
