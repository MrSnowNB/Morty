# First Principles Methodology

Use this document as the execution engine for the `first-principles` skill. The goal is to solve hard problems without overflowing context, while converting each non-trivial solve into durable capability.

## Core model

Treat the solve as a three-tier memory system:

- **Working memory** — the active Claude context window for the current step only.
- **Scratchpad memory** — `$MORTY_PROJECT_ROOT/SCRATCH.md`, which holds the live solve state.
- **Durable memory** — journals, `CHECKPOINT.md`, `memory.db`, and skill/reference files that outlive this solve.

The rule is simple: **context is for the current thought; `SCRATCH.md` is for the active solve; durable memory is for reusable lessons**.

## Phase 0 — Load and anchor

1. If a prior `SCRATCH.md` exists and clearly belongs to the same problem, resume it; otherwise overwrite from the template.
2. Read the current problem statement, any directly relevant logs, and only the minimal reference material needed.
3. If available, retrieve prior attempts, checkpoints, or journal anchors related to the same problem family.
4. Write a one-paragraph problem statement to `SCRATCH.md` and freeze it. Do not silently redefine the problem later.

## Phase 1 — Breadth-first assumption challenge

Before recursing, enumerate all top-level assumptions.

For each assumption:

1. Classify it as one of: `fact`, `belief`, `convention`, `hidden constraint`, or `unknown`.
2. Challenge it in the assumption table format from `references/assumption-table.md`.
3. Run a compact Five Whys chain if the assumption appears important, fragile, or inherited from prior attempts.
4. Mark a verdict: `keep`, `revise`, `discard`, or `research`.

Do not recurse until the top-level assumption table is complete.

## Phase 2 — Ground truths

Derive the minimum set of bedrock truths needed to solve the problem.

- Use relevant entries from `references/domain-axioms.md` when applicable.
- Add problem-specific ground truths as numbered items: `GT-1`, `GT-2`, `GT-3`, ...
- Each ground truth must be irreducible, testable, and stated in plain language.
- Remove slogans, abstractions, and solution-shaped framing.

If you cannot state at least 3 grounded truths for the problem, you are not ready to recurse.

## Phase 3 — Decompose into sub-problems

Break the problem into the smallest useful sub-problems.

For each candidate sub-problem:

- Give it an ID: `SP-1`, `SP-2`, ...
- Define the success condition.
- Define the failure signal.
- Estimate whether it can be solved directly, delegated to another skill, or needs first-principles recursion.

Write the active list into `SCRATCH.md`.

## Phase 4 — Controlled recursive solve loop

For each unresolved sub-problem:

1. Check whether an existing skill already covers it well enough.
2. If yes, use that skill and record the result back into `SCRATCH.md`.
3. If no, recurse into `first-principles` with a narrower scope.
4. After each recursion, record:
   - what changed,
   - what was learned,
   - whether the sub-problem got smaller,
   - whether confidence increased.

### Convergence rule

Recursion is only allowed to continue if **both** conditions are true:

- The sub-problem representation is smaller, clearer, or more constrained than before.
- At least one assumption, dead end, or unknown has been eliminated.

If either condition fails twice in a row, stop recursing and pivot.

### Depth rule

- Soft limit: 3 recursive levels.
- Hard limit: 4 recursive levels unless the user explicitly asks to continue.
- If depth increases without compression, stop and write a pivot note.

## Phase 5 — Error capture and dead-end logging

Every failed branch must still produce useful residue.

When a branch fails, write:

- the sub-problem ID,
- what was attempted,
- why it failed,
- what assumption broke,
- whether the failure is local or systemic,
- the next best pivot.

Do not hide dead ends in prose. Put them in the scratchpad explicitly so future phases do not rediscover the same mistake.

## Phase 6 — Bottom-up reconstruction

Rebuild the answer from solved sub-problems and numbered ground truths.

Requirements:

- Every major claim should trace to `GT-*` or a verified sub-result.
- Prefer two or three candidate solutions when trade-offs matter.
- Compare options on correctness, robustness, cost, maintainability, and user alignment.
- If an answer depends on an unverified assumption, flag it explicitly.

## Phase 7 — Validation

Perform a final trace check:

1. For each conclusion, cite the supporting ground truth(s) or solved sub-problem(s).
2. For each recommendation, note what would falsify it.
3. For each unresolved uncertainty, state whether it blocks action or can be deferred.

If any core conclusion lacks grounding, return to Phase 2 or 3 before answering.

## Phase 8 — Post-mortem and self-improvement

After any non-trivial solve:

1. Write `POST-MORTEM.md` from the template.
2. Capture:
   - the problem,
   - the breakthrough,
   - failed approaches,
   - reusable heuristics,
   - candidate skill edits or new skills.
3. If a new reusable invariant emerged, propose an update to `references/domain-axioms.md`.
4. Evaluate the solve for durable artifacts:
   - If the solve yields a **repeatable operational workflow**, synthesize a playbook in `.claude/playbooks/`.
   - If the solve yields only a **failure analysis** without reusable operational steps, write a case entry in `.claude/cases/`.
5. If the solve revealed a need for a new agentic capability, propose a new skill or a patch to an existing one.
6. If the session is near compaction or handoff, invoke `checkpoint-writer`.

## Compression discipline

To avoid context overflow:

- Keep only the current phase and immediately relevant sub-problem in active context.
- Push intermediate reasoning, tables, and branch logs into `SCRATCH.md`.
- Re-read the scratchpad at phase boundaries instead of carrying all prior detail in-context.
- Summarize only when moving from scratchpad to durable memory; do not repeatedly summarize the scratchpad itself.

## Operating principles

- Challenge assumptions breadth-first before going depth-first.
- Prefer explicit tables over diffuse prose for assumption audits.
- A dead end that is logged is progress.
- A recursion that does not shrink the problem is a bug.
- A good solve should leave Morty smarter than before.
