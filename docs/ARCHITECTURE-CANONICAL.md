# Architecture Canonical

**Status:** constitution — every system change must align with this document.
**Created:** 2026-04-22
**Author:** First-principles analysis

## 1. Single Responsibility for Each Directory

| Directory | Responsibility | Forbidden |
|---|---|---|
| `.claude/hooks/` | Intercept agent tool calls at runtime; write tool_call entries to journal; manage task_id fallback. | Define task lifecycle (open/close tasks). |
| `.claude/commands/` | Define user-facing slash commands that trigger agent behavior. | Execute anything directly — they are documentation only. |
| `.claude/tools/` | Standalone agent-callable scripts (e.g. task-util.ps1). | Touch the agent's task_id context — subprocess env never reaches agent. |
| `.claude/playbooks/` | Step-by-step recipes (sequences of skills) for recurring workflows. | Contain executable scripts — they are instructions, not code. |
| `.claude/skills/` | Reusable atomic operations that inject context into the agent. | Manage task lifecycle boundaries. |
| `.claude/cases/` | Recorded failures with diagnosis and resolution — for skill codification. | Duplicate cases in root `/cases/`. |
| `cases/` (root) | Legacy — do not add new entries. Delete when all cases migrated. | Serve as the active cases directory. |
| `logs/` | Runtime journal (`.jsonl`), step counter, temp files. | Persist business logic — only data and process artifacts. |

## 2. The One Path: task_id Flow

```
User types /task-begin <slug>
  → Agent executes task-begin command (reads .claude/commands/task-begin.md)
  → Agent sets $env:MORTY_TASK_ID = "<slug>" in its own process
  → Agent writes task_begin entry to journal via journal-anchor skill
  → Agent performs tool calls
  → post-tool.ps1 hook fires (subprocess)
    → Reads $env:MORTY_TASK_ID — empty (subprocess isolation)
    → Falls back: reads journal tail, finds open task_begin
    → Writes tool_call entry with task_id from journal
  → User types /task-end <outcome>
  → Agent executes task-end command (reads .claude/commands/task-end.md)
  → Agent writes task_end entry to journal via journal-anchor skill
  → Agent clears $env:MORTY_TASK_ID
```

**Rule:** `task_begin` and `task_end` are written by the agent via slash commands.
`tool_call` entries are written by `post-tool.ps1` hook reading from the journal.
**No other system may write task lifecycle entries.**

## 2b. Autonomous vs Human-Assisted Paths

Both paths converge on the same journal state and produce identical mine.ps1 results.

| Path | How task_begin is written | Hook fallback | Outcome |
|---|---|---|---|
| **HUMAN SESSION** | User types `/task-begin` → agent sets env var → agent writes journal entry | Hook reads env var if set; falls back to journal | Identical |
| **AUTONOMOUS SESSION** | Agent writes `task_begin` to journal directly (no env var set) | Hook reads journal tail, finds open `task_begin` | Identical |

The journal is the shared medium. Whether the agent sets `$env:MORTY_TASK_ID` or writes `task_begin` directly to the journal, the hook's fallback mechanism produces the same `tool_call` entries with the correct `task_id`.


## 3. Morty's Autonomy Boundaries

| What | Autonomy | Reason |
|---|---|---|
| Playbooks (`.claude/playbooks/`) | **Yes** — Morty may edit freely | Recipes, not code |
| Journal (`logs/morty-journal.jsonl`) | **Yes** — append only | Append-only memory law |
| SCRATCH.md | **Yes** — Morty's working memory | Ephemeral state |
| Skills (`.claude/skills/`) | **No** — human-approved PR only | Skills inject agent behavior |
| Hooks (`.claude/hooks/`) | **No** — human-approved PR only | Hooks fire on every tool call |
| Tools (`.claude/tools/`) | **No** — human-approved PR only | Tools are agent-callable code |
| Mine.ps1 | **No** — human-approved PR only | Core chain-mining logic |
| Cases | **Yes** — Morty may add new cases | Failure records, not code |

## 4. Task Lifecycle DAG

```
  /task-begin <slug>          ← User action (slash command)
        │
        ▼
  Agent sets $env:MORTY_TASK_ID   ← Agent process (not subprocess)
        │
        ▼
  Agent writes task_begin → journal   ← journal-anchor skill
        │
        ▼
  Agent performs tool calls
        │
        ▼
  post-tool.ps1 hook fires   ← Subprocess
        │
        ├── Reads journal (no env var)
        ├── Finds open task_begin
        └── Writes tool_call → journal   ← Hook
        │
        ▼
  /task-end <outcome>          ← User action (slash command)
        │
        ▼
  Agent writes task_end → journal   ← journal-anchor skill
        │
        ▼
  Agent clears $env:MORTY_TASK_ID
```

**Invariant:** The journal is the shared medium between agent process and hook subprocess.
**Invariant:** Only the hook writes `tool_call` entries. Only the agent writes `task_begin`/`task_end` entries.

## 5. Skill vs Playbook Boundary

- **Skill:** A reusable atomic operation. Takes a description, performs a bounded set of tool calls. Lives in `.claude/skills/<name>/SKILL.md`.
- **Playbook:** A sequence of skills for a recurring workflow. Lives in `.claude/playbooks/<name>.md`.
- **Playbooks contain NO executable scripts.** They are instructions for the agent, not code.
- **Skills contain NO task lifecycle management.** They perform their domain operation only.

## 6. Deprecation Decisions

| System | Action | Reason |
|---|---|---|
| `cases/` (root) | Delete after migration to `.claude/cases/` | Duplicate directory, chain-miner scans `.claude/cases/` |
| `task_util.ps1` | Deprecated — superseded by hook + slash commands | Subprocess env never reaches agent; hook fallback reads journal instead |
| `chain-seed` skill | Merge into `chain-seed.md` playbook | `.claude/skills/chain-seed/PLAYBOOK.md` is a playbook, not a skill |
| `task-begin` skill | Merge into `task-begin.md` command | `.claude/skills/task-begin/SKILL.md` duplicates the command |
| `task-end` skill | Merge into `task-end.md` command | `.claude/skills/task-end/SKILL.md` duplicates the command |

## 7. What This Fixes

The task_id propagation bug was a symptom of five overlapping systems. With this canonical:

1. **Hooks** handle tool_call journaling via journal fallback — no subprocess env needed.
2. **Commands** define task lifecycle — user-only, agent-invoked via slash.
3. **Playbooks** define workflows — no inline scripts, just instructions.
4. **Tools** are standalone scripts — not for task lifecycle.
5. **Skills** are atomic operations — not for task boundaries.

Chain-seed, mine.ps1, and all downstream work proceed from this single source of truth.
