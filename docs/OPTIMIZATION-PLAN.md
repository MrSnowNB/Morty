# Codebase Optimization Plan

**Date:** 2026-04-22
**Scope:** `.claude/` harness structure
**Status:** Draft — awaiting review

---

## Current Structure Audit

### Directory Layout

```
.claude/
├── CLAUDE.md / MORTY.md          # Identity + policy
├── .mcp.json                     # MCP server config
├── settings.json / .local.json   # Permission/settings
├── AI-FIRST/CONTEXT.md           # Bootstrap context
├── memories/00-06.md             # 7 memory files
├── commands/*.md                 # 11 slash commands
├── hooks/pre-bash.ps1            # Pre-tool hook
├── hooks/post-tool.ps1           # Post-tool hook (v2 journal writer)
├── tools/task-util.ps1 / .md     # Deprecated tool
├── skills/                       # 20 skill directories
│   ├── chain-miner/              # SKILL.md + scripts/mine.ps1
│   ├── chain-seed/               # PLAYBOOK.md (misclassified)
│   ├── checkpoint-writer/        # SKILL.md
│   ├── color/                    # SKILL.md
│   ├── delta-log/                # delta-log.md + SKILL.md
│   ├── doc-convert/              # SKILL.md + scripts/pandoc.ps1
│   ├── first-principles/         # SKILL.md + references/ + templates/
│   ├── journal-anchor/           # SKILL.md + scripts/append.ps1
│   ├── pdf-read/                 # SKILL.md + scripts/extract.ps1
│   ├── repo-onboard/             # SKILL.md
│   ├── research-synth/           # SKILL.md
│   ├── safe-bash/                # SKILL.md + scripts/run.ps1 + references/
│   ├── self-benchmark/           # SKILL.md + scripts/benchmark.ps1
│   ├── skill-maker/              # SKILL.md
│   ├── spec-writer/              # SKILL.md
│   ├── task-begin/               # SKILL.md + scripts/append.ps1
│   ├── task-end/                 # SKILL.md + scripts/append.ps1
│   └── zombie-restore/           # zombie-restore.md + SKILL.md
├── playbooks/                    # 6 playbook files
├── cases/                        # 6 case files
├── validation/README.md          # Gate validation docs
└── agents/.gitkeep               # Empty placeholder
```

### Root-Level

```
docs/                           # Architecture + validation reports
logs/                           # Journal, SCRATCH.md, temp files
```

---

## Problems Identified

### P-1: Skill/Command Duplication (HIGH)

Per ARCHITECTURE-CANONICAL.md Section 6, these skills should be merged into commands:

| Skill Directory | Command File | Status |
|-----------------|-------------|--------|
| `skills/task-begin/` | `commands/task-begin.md` | SKILL.md still exists |
| `skills/task-end/` | `commands/task-end.md` | SKILL.md still exists |

The MORTY.md explicitly says commands are NOT skills, yet both directories exist.

**Impact:** Confuses agent about invocation method. `Skill(task-begin)` vs `/task-begin` are different mechanisms.

### P-2: Misclassified chain-seed (MEDIUM)

`.claude/skills/chain-seed/PLAYBOOK.md` — a playbook inside a skill directory. Per the architecture canonical, this should be in `playbooks/`. The file `playbooks/chain-seed.md` already exists.

**Impact:** Duplicate workflow definition. Agent may load both.

### P-3: Inconsistent Naming Conventions (LOW)

Some skills use `delta-log.md` or `zombie-restore.md` as their primary doc alongside `SKILL.md`, while others use only `SKILL.md`. No enforced convention.

### P-4: Deprecated Files Still Present (MEDIUM)

Per ARCHITECTURE-CANONICAL.md Section 6:
- `tools/task-util.ps1` — deprecated, superseded by hook + slash commands
- `tools/task-util.md` — companion doc
- `skills/chain-seed/PLAYBOOK.md` — should be in playbooks/

### P-5: No README in skills/ (LOW)

20 skill directories with no index. Hard to audit what exists without globbing.

### P-6: Memory Files Not Sorted by Dependency (LOW)

`00-cold-start` through `06-tiered-memory` — but `06` is loaded after `05` in the memory list, and no explicit dependency ordering is enforced.

### P-7: Duplicate Identity Files (LOW)

`CLAUDE.md` and `MORTY.md` exist at both user-global (`~/.claude/`) and project (`C:\work\harness-sandbox\.claude/`) levels. They are identical. If the user intends project-level override, this is fine — but they add no differentiation.

---

## Optimization Proposals

### O-1: Remove Duplicate Skill Directories (High Impact)

**Action:** Delete `skills/task-begin/` and `skills/task-end/` directories. These are commands only, per the architecture canonical.

**Why:** The architecture canonical explicitly marks them for deprecation. The command `.md` files serve the same purpose. Keeping both creates confusion about how to invoke task lifecycle.

**Risk:** If any session previously invoked these as skills (via `Skill()`), those sessions would break. However, the MORTY.md says slash commands are the correct invocation method.

**Steps:**
1. Verify no playbook references `skills/task-begin` or `skills/task-end`
2. Delete the directories
3. Update ARCHITECTURE-CANONICAL.md Section 6 status to "completed"

### O-2: Consolidate chain-seed (Medium Impact)

**Action:** Delete `.claude/skills/chain-seed/PLAYBOOK.md`. The playbook already exists at `playbooks/chain-seed.md`.

**Why:** Duplicate definition. The architecture canonical says to merge chain-seed skill into playbook.

**Steps:**
1. Compare `skills/chain-seed/PLAYBOOK.md` vs `playbooks/chain-seed.md`
2. If identical, delete the skill-dir version
3. Delete `skills/chain-seed/` entirely if it contains nothing else

### O-3: Remove Deprecated Tools (Medium Impact)

**Action:** Delete `tools/task-util.ps1` and `tools/task-util.md`.

**Why:** ARCHITECTURE-CANONICAL.md Section 6 marks this as deprecated. The hook (`post-tool.ps1`) supersedes it.

**Risk:** Low. No playbook references it (confirmed by Gate 5).

### O-4: Enforce Skill Directory Convention (Low Impact)

**Action:** Standardize each skill directory to contain exactly:
- `SKILL.md` — required, the skill definition
- `scripts/` — optional, only if the skill needs executable scripts
- `references/` — optional, only if the skill needs reference material

**Why:** Reduces cognitive load. New skills follow a predictable pattern.

**Steps:**
1. Audit each skill directory
2. Move orphan `.md` files (like `delta-log.md`, `zombie-restore.md`) into `SKILL.md` or delete if redundant
3. Add a `skills/README.md` listing all skills with one-line descriptions

### O-5: Add Skills Index (Low Impact)

**Action:** Create `.claude/skills/README.md` as a quick-reference index.

**Format:**
```markdown
# Skills Index

| Skill | Type | Has Scripts | Description |
|-------|------|-------------|-------------|
| chain-miner | mining | yes | Scans journal for recurring tool chains |
| journal-anchor | persistence | yes | Appends entries to journal |
| ... | ... | ... | ... |
```

### O-6: Clean Up agents/ Directory (Low Impact)

**Action:** Delete `.claude/agents/.gitkeep`. Subagents are disabled (confirmed in CLAUDE.md). No placeholder needed.

---

## Execution Order

| Order | Optimization | Effort | Risk |
|-------|-------------|--------|------|
| 1 | O-3: Remove deprecated tools | 5 min | None |
| 2 | O-2: Consolidate chain-seed | 5 min | None |
| 3 | O-1: Remove duplicate skills | 10 min | Low — verify no skill invocations |
| 4 | O-5: Add skills index | 5 min | None |
| 5 | O-4: Enforce convention | 15 min | Low — cosmetic |
| 6 | O-6: Clean agents/ | 1 min | None |

**Total estimated effort:** ~40 minutes
**Total risk:** Low — all are deletions or consolidations, no new code

---

## What NOT to Optimize

- **Memory files:** 7 files is a manageable number. Adding more would hurt readability.
- **Hook scripts:** `pre-bash.ps1` and `post-tool.ps1` are small and well-documented.
- **Playbooks:** 6 files is appropriate for current workflow density.
- **Cases:** 6 failure records is a healthy knowledge base.

---

## Invariants Preserved

- GT-1: Hook subprocess isolation — deleting tools/skills does not affect post-tool.ps1
- GT-2: Journal as shared medium — no change to journal write path
- GT-3: Command vs skill separation — O-1 enforces this, does not break it
