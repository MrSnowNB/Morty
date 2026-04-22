# Docs Index

| Document | Purpose |
|---|---|
| [`ARCHITECTURE-CANONICAL.md`](ARCHITECTURE-CANONICAL.md) | The constitution. Single source of truth for directory responsibilities, task lifecycle DAG, autonomy boundaries, and deprecation history. All system changes must align. |
| [`launching.md`](launching.md) | How to install and run Morty on top of Claude Code + Lemonade. Quickstart + troubleshooting. |
| [`validation-runs/`](validation-runs/) | Dated reports from executed validation gates. Evidence, not rules \u2014 each file documents what happened in a specific run. |
| [`historical/`](historical/) | Archived documents retained for traceability. Do not act on anything under this directory. |

The **rules** for validation live in [`.claude/validation/README.md`](../.claude/validation/README.md). This directory only holds the **run reports** that validation produced.

## Reading order for a new contributor

1. `launching.md` \u2014 get Morty running
2. `ARCHITECTURE-CANONICAL.md` \u00a71\u2013\u00a75 \u2014 understand the system
3. `../.claude/skills/README.md` \u2014 browse available capabilities
4. `../.claude/playbooks/README.md` \u2014 browse recurring workflows
5. `validation-runs/` \u2014 see what has been exercised end-to-end
