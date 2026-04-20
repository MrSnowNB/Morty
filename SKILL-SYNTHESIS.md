# Skill Synthesis — Morty's Recursive Self-Improvement Loop

> **Status:** v1 (landed in `feat/recursive-self-improvement`).
> **Scope:** How Morty grows its own capability library over time without
> violating governance, context budget, or the "one rule" from `MORTY.md`.

## The Loop

```
OBSERVE → STRUCTURE → MINE → PROPOSE → RATIFY → VALIDATE → PROMOTE
   ↑                                                            │
   └─────────────────── (next session) ─────────────────────────┘
```

Each arrow is gated. Nothing is silent. Everything leaves an auditable trace
(journal anchor, DELTA entry, or both).

| Phase     | Who does it                               | Output                              |
|-----------|-------------------------------------------|-------------------------------------|
| OBSERVE   | `post-tool.ps1` hook (automatic)          | `tool_call` entries in journal      |
| STRUCTURE | `/task-begin` + `/task-end` (user-driven) | `task_begin` / `task_end` anchors   |
| MINE      | `chain-miner` skill (read-only)           | `## MINE` block in `SCRATCH.md`     |
| PROPOSE   | `/codify` command                         | One proposal, presented to Mark     |
| RATIFY    | `/teach` → `skill-maker`                  | New `SKILL.md` at chosen scope      |
| VALIDATE  | Next session uses the new skill           | New journal entries tagged with it  |
| PROMOTE   | `tiered-memory-promote` playbook          | `.claude/playbooks/*.md`            |

## Governance constraints this loop respects

- **Memory `05-self-extension.md`:** skills are never auto-created without
  `/teach` or explicit user approval. `/codify` proposes; it never writes.
- **Memory `03-context-hygiene.md`:** the miner is tail-bounded (default
  2000 lines) and refuses to run in LORA mode.
- **Memory `06-tiered-memory.md`:** mining writes only to Tier-0 (`SCRATCH.md`).
  Proposals live in Tier-0 until ratified.
- **`MORTY.md` One Rule:** every step that could be unsafe is gated by an
  explicit user turn (`/task-end success`, `/teach`, `/checkpoint`).

## Why this actually improves performance

- **The library grows, not the active context.** Skills are auto-discovered
  by `description:` matching, so Morty's resident tokens stay ~constant
  even as the tool inventory 10×'s.
- **Codified chains compress future chains.** A 7-step chain becomes a
  1-step skill invocation. The chain-miner will subsequently discover
  *longer* higher-order chains that use the new skill as a primitive —
  this is the HaloClaw-style hierarchical compression applied to skill
  abstractions.
- **Small model stays small.** Mining is pure PowerShell
  (`Get-Content -Tail`, `Group-Object`, SHA-256). The LLM is only invoked
  during PROPOSE, and only to draft a good `description:` and `Gotchas:`
  from pre-distilled input — a small-context task Qwen3-Coder-Next handles
  cleanly.

## The threshold for codification

A chain is eligible for `/codify` only when:

- `count >= 2` (matches the Tier-1 → Tier-2 promotion bar in
  `playbooks/tiered-memory-promote.md`), AND
- `success_rate == 1.0` (zero failures in same-signature tasks).

Failure modes do not become skills — they become **cases** under
`.claude/cases/`. The library encodes what works; the case book encodes what
breaks.

## Operating rhythm

Typical session using the loop:

```
morty /task-begin add-readme-section
... work ...
morty /task-end success "readme section landed, tests green"
morty /checkpoint "added readme section"
```

Periodically (every ~10 `task_end` anchors, or when Mark wants to curate):

```
morty  (invoke chain-miner skill by describing the intent)
morty /codify
# review proposal
morty /teach <if accepted>
morty /checkpoint "codified <skill-name>"
```

## What this is not

- Not autonomous. Ratification is always a user turn.
- Not a RL loop. Outcome is user-reported (`success|partial|fail`), not
  learned from rewards.
- Not a meta-agent. The miner is a ~150-line PowerShell script. The only
  "intelligence" is Morty's own drafting of the skill's description and
  gotchas during PROPOSE.
- Not a replacement for `/spec`. For net-new capabilities that do not yet
  have a discovered chain, `/spec` → implement → ship remains the path.
  `/codify` only applies when the work has already been done successfully
  at least twice.

## References

- Journal schema: `.claude/skills/journal-anchor/SKILL.md` (task_begin, task_end)
- Miner: `.claude/skills/chain-miner/SKILL.md` + `scripts/mine.ps1`
- Task boundaries: `.claude/commands/task-begin.md`, `task-end.md`
- Proposal: `.claude/commands/codify.md`
- Ratification: `.claude/commands/teach.md` → `skills/skill-maker/SKILL.md`
- Promotion: `.claude/playbooks/tiered-memory-promote.md`
- Audit primitive: `.claude/skills/delta-log/SKILL.md`
