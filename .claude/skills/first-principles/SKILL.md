---
name: first-principles
description: Use this for complex, ambiguous, high-stakes, or novel problems where Morty must reason from bedrock truths, manage context pressure with an external scratchpad, recurse carefully into sub-problems, and leave behind reusable improvements after the solve.
---

# First Principles

## When to use

**This skill is the default framing for every non-trivial request.** See
`.claude/memories/07-default-framing.md` for the trivial-bypass criteria.
If a request does not match the trivial whitelist, Phases 0–2
(problem statement, assumption challenge, ground truths) run before any
code, config, or network call is produced — no explicit invocation
required.

Explicit invocation is still useful when:

- The user names the method ("reason from first principles", "ground up").
- The problem is hard, ambiguous, novel, or has resisted normal debugging.
- The task is likely to overflow context unless intermediate state is written to disk.
- Morty needs to produce not just an answer, but a reusable method, invariant, or skill improvement.

## Opt-out

The user may skip the default Phase 0–2 pass by starting a request with
`/skip-fp` or "just do it". Record the bypass in the journal so the
pattern is visible on review. Do not silently skip.

## Steps

1. Create or refresh `$MORTY_PROJECT_ROOT/SCRATCH.md` from `templates/SCRATCH.md.template` before deep reasoning begins.
2. Read the methodology in `references/methodology.md` and execute the phases in order.
3. Treat `SCRATCH.md` as short-term working memory: write to it after each major phase, dead end, and solved sub-problem.
4. Load only the reference material needed for the current phase to avoid context bloat.
5. If the solve yields a reusable invariant, heuristic, or workflow, record it in the post-mortem and propose either a skill edit or a new skill.

## Files

- `references/methodology.md` — full phase engine, recursion rules, convergence checks, and self-improvement loop.
- `references/domain-axioms.md` — reusable systems, software, networking, and agentic reasoning bedrock truths.
- `references/assumption-table.md` — strict table format for assumption audits and Five Whys traces.
- `references/gotchas.md` — recurring failure modes harvested from past solves.
- `templates/SCRATCH.md.template` — ephemeral short-term memory for the active solve.
- `templates/POST-MORTEM.md.template` — structured reflection artifact written at the end.

## Gotchas

See `references/gotchas.md` for the full list (including lessons captured from past solves).

Inline quick-reference:

- Do not keep the entire solve in chat context; page state into `SCRATCH.md` instead.
- Breadth-first challenge comes before depth-first recursion; do not dive into sub-problems until top-level assumptions have been stress-tested.
- Recursion is only valid if the problem representation is shrinking. If not, pivot instead of going deeper.
- Every major conclusion must trace to a numbered ground truth or a verified sub-result.
- `SCRATCH.md` is disposable working memory; durable lessons belong in post-mortems, journals, or reusable skill artifacts.
- **`revise` verdicts in the assumption table must be re-verified against real data, not re-reasoned from priors.** (See gotchas for the RSS-paragraph example.)
