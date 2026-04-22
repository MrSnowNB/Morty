# Skills Index

Auto-discoverable skills available to Morty. Each skill lives in its own directory and contains a `SKILL.md` with the frontmatter `description:` field that Claude Code matches against. Some skills ship executable `scripts/` or reference material in `references/`.

See [`docs/ARCHITECTURE-CANONICAL.md`](../../docs/ARCHITECTURE-CANONICAL.md) §5 for the skill-vs-playbook boundary.

| Skill | Scripts | Purpose |
|-------|---------|---------|
| [chain-miner](chain-miner/SKILL.md) | yes | Analyzes `logs/morty-journal.jsonl` for recurring high-success tool-call sequences and surfaces codification candidates to `SCRATCH.md`. |
| [checkpoint-writer](checkpoint-writer/SKILL.md) | no | Writes `CHECKPOINT.md` + journal anchor at ~60% context or before `/compact` so state survives compaction. |
| [color](color/SKILL.md) | no | Changes terminal output color via ANSI escape codes. |
| [delta-log](delta-log/SKILL.md) | no | Appends an audit-trail delta entry to `SCRATCH.md` before any destructive write. The progressive-atomic-tooling primitive. |
| [doc-convert](doc-convert/SKILL.md) | yes | Converts documents between `.docx`, `.md`, `.html`, `.pdf`, `.rst`, `.epub` via Pandoc with safe defaults. |
| [first-principles](first-principles/SKILL.md) | no | Disciplined recursive decomposition for complex, ambiguous, or novel problems. Drives `SCRATCH.md` + `POST-MORTEM.md`. |
| [journal-anchor](journal-anchor/SKILL.md) | yes | Appends a single structured JSON line to the project journal with mutex-protected write. Canonical journal writer. |
| [pdf-read](pdf-read/SKILL.md) | yes | Extracts structured text from PDFs (pypdf, OCR fallback). |
| [repo-onboard](repo-onboard/SKILL.md) | no | First-visit read of an unfamiliar repo — README, manifests, entry points, tests — and drafts a minimal `CLAUDE.md` stub. |
| [research-synth](research-synth/SKILL.md) | no | Drives Playwright MCP to search, visit, and synthesize citable web sources into a Markdown brief. |
| [safe-bash](safe-bash/SKILL.md) | yes | Denylist-gated wrapper around every Windows shell invocation. |
| [self-benchmark](self-benchmark/SKILL.md) | yes | Produces a scored performance report of the current session from the journal. |
| [skill-maker](skill-maker/SKILL.md) | no | Creates a new `SKILL.md` at the correct scope when a capability should be codified. |
| [spec-writer](spec-writer/SKILL.md) | no | Produces `SPEC.md` and blocks on user ack before any code is written. |
| [zombie-restore](zombie-restore/SKILL.md) | no | Four-gate memory-integrity re-authentication at every cold start. No reconstruction without verification. |

## Conventions

Per `ARCHITECTURE-CANONICAL.md` §6 (O-4 in the optimization plan):

- Each skill directory contains **exactly one** top-level `SKILL.md`.
- Optional `scripts/` subdirectory for executable code.
- Optional `references/` subdirectory for supporting reference material.
- Optional `templates/` subdirectory for scaffolding files (e.g. `first-principles`).

Skills must NOT manage task lifecycle boundaries — that is the responsibility of the `/task-begin` and `/task-end` slash commands. Skills are atomic operations.
