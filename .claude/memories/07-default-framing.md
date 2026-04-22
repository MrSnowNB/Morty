# Default Framing: First Principles

All **non-trivial** requests are framed from first principles before any
execution. This is the default — not an opt-in.

## Trivial bypass (execute immediately)

A request is trivial only if it matches all of:

- Single tool call OR pure read / list / show / echo
- No code generation beyond a one-liner
- No file mutation outside an obvious target named by the user
- No environment, config, or harness change
- No network call the user has not explicitly named

Concrete trivial examples:

- "show me the last commit", "list skills", "cat SPEC.md"
- `/introspect`, `/checkpoint`, `/compact`
- "fix the typo on line 12 of X"
- Echoing a value the user just provided

If any of the criteria fail, the request is **non-trivial** — use the
first-principles path below.

## Non-trivial path (default)

Before any tool that creates, edits, runs, installs, commits, pushes, or
calls out to a network service:

1. **Phase 0 — Problem statement.** Write the user's request into a fresh
   `$MORTY_PROJECT_ROOT/SCRATCH.md` in Morty's own words. If this cannot be
   done cleanly in 3–5 lines, the request is ambiguous; ask instead of
   assuming.
2. **Phase 1 — Assumption challenge.** Enumerate every assumption the
   naïve approach is making. Mark each `keep` / `revise` / `drop` with a
   one-line justification. `revise` verdicts must be re-verified against
   **real data**, not re-reasoned from priors (see gotchas).
3. **Phase 2 — Ground truths.** Write the numbered, verifiable facts the
   solution will rest on. Every later decision must trace to one of
   these or a verified sub-result.

Only after Phases 0–2 settle does execution begin. Later phases
(decomposition, solution design, validation, post-mortem) follow the
skill's own methodology.

## Opt-out

The user may skip the default path by typing `/skip-fp` or "just do it"
at the start of a request. Record the bypass in the journal so the
pattern is visible on review.

## Failure mode to avoid

Skipping Phases 0–2 and jumping to "build the obvious thing" is the
dominant source of rework. One documented example: a news-fetcher skill
committed to RSS as the data source in Phase 4 before Phase 1 had
verified that RSS actually contains article paragraphs. It did not. Five
rewrites followed. The correct move was to re-verify the `revise` on
assumption A4 **against the live feed** before writing code.

See `.claude/skills/first-principles/references/gotchas.md`.
