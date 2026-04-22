# First-Principles Gotchas

Recurring failure modes harvested from past solves. Read this before
starting any non-trivial solve; re-read after a solve that did not go
cleanly.

## G1. `revise` verdicts must be verified against real data

When an assumption table row is marked `revise`, the revision is a
**new** assumption. It must be checked against actual data from the real
system — not re-reasoned from priors.

**Example — Google News RSS solve (2026-04):**

| Assumption | Verdict | Revision |
|---|---|---|
| A4: "RSS `<description>` contains the first paragraph of the article" | revise | "RSS description is a snippet, use it" |

The revision was wrong. RSS `<description>` for Google News is a
structured `<ol><li>` HTML list of *related headlines*, not article
text. The revision was never verified against a live feed response, so
Phase 4 committed to RSS as the paragraph source and had to be rewritten
five times before the skill was narrowed to headlines-only with
agent-generated summaries.

**Rule:** If a `revise` verdict changes the data-source contract, the
Phase 1 pass does not close until a live probe of the source confirms
the new assumption.

## G2. Breadth before depth

Do not recurse into a sub-problem until every top-level assumption has
been challenged. A correctly-solved sub-problem under a wrong top-level
assumption is still wrong, and deeper to untangle.

## G3. The representation must shrink

Recursion is only valid if each level reduces the size of the problem
representation (inputs, branches, state). If a sub-problem restates the
parent at the same complexity, pivot — do not descend.

## G4. SCRATCH.md is the working set, not the chat

Every major phase, dead end, and solved sub-problem writes to
`SCRATCH.md`. Do not keep intermediate state in chat context — it will
get compacted away.

## G5. Durable lessons leave the SCRATCH

`SCRATCH.md` is disposable. Ground truths, reusable heuristics, and new
invariants must migrate to: the post-mortem, the journal, or a skill
edit. A lesson that only lives in a SCRATCH file is a lesson that will
be repeated.

## G6. Every conclusion cites a ground truth

A Phase 6 conclusion that cannot name the numbered ground truth or
verified sub-result it rests on is a guess. Either find the trace or
the conclusion is invalid.

## G7. `_tmp_*` debug scripts must be cleaned up

When debugging a script under `logs/` or near the solve, use `_tmp_`
prefixes so they are easy to grep and remove. Hygiene CI forbids
tracking them, but uncommitted clutter in the working copy is still a
distraction. Delete before moving to Phase 5 (validation).

## G8. String interpolation vs member access

PowerShell: `"$obj.property"` stringifies the object then appends
`.property` as literal text. Use `"$($obj.property)"`. This is the
single most common slip in PowerShell skill scripts. If a string
contains a literal `.property` substring that should have been a value,
this is the cause.
