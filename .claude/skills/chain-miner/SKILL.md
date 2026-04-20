---
name: chain-miner
description: Use this when the user asks Morty to find effective tool chains, mine the journal for recurring patterns, or prepare candidates for /codify. Read-only analysis — writes only to SCRATCH.md, never to skills/, memories/, or playbooks/.
---

# Chain Miner

Analyzes `logs/morty-journal.jsonl` for recurring, high-success tool-call
chains bounded by `task_begin` / `task_end` anchors, and surfaces the top
candidates for codification.

This skill is **read-only with respect to `.claude/`**. It is the OBSERVE
→ MINE phase of recursive self-improvement. The PROPOSE phase lives in
`/codify`; the RATIFY phase lives in `/teach` + `skill-maker`.

## When to use

- User says "mine the journal", "find tool chains", "what patterns should I codify".
- At a task boundary, when preparing to run `/codify`.
- After any session that produced ≥3 new `task_end` anchors.

## When NOT to use

- During a LORA-mux session (fill > 70%). Defer to next session — mining
  reads tail-2000 lines and that is too expensive at high fill. Write a
  note in SCRATCH.md to run on cold-start next session instead.
- If `logs/morty-journal.jsonl` has no `task_end` anchors — there is
  nothing to mine yet. Tell Mark to wrap work in `/task-begin` + `/task-end`
  before running again.

## Steps

1. **Pre-Action Gate.** Confirm fill < 70% and no open `$env:MORTY_TASK_ID`.
2. Invoke `scripts/mine.ps1`. It reads the journal tail (bounded — never full
   file) and emits a normalized JSON report to stdout.
3. Append the report to `SCRATCH.md` under a single block headed
   `## MINE [YYYY-MM-DD HH:MM]`. Do not edit or delete prior MINE blocks.
4. Summarize the top-3 candidates to Mark in one screen: signature, count,
   success_rate, representative task_ids.
5. **Stop.** Do NOT write to `.claude/skills/`, `.claude/memories/`, or
   `.claude/playbooks/`. Codification is `/codify`'s job, and ratification
   is `/teach`'s job.

## Output schema (per candidate chain)

```json
{
  "signature": "<sha8 of normalized tool sequence>",
  "steps": [{"tool": "Read", "arg_shape": "*.md"}, ...],
  "count": 3,
  "success_count": 3,
  "fail_count": 0,
  "success_rate": 1.0,
  "avg_steps": 7.3,
  "sample_task_ids": ["add-readme-section", "fix-anchor-lookup"],
  "representative_summary": "Read → Grep → Edit → journal-anchor"
}
```

## Codification threshold

Only surface chains that meet **both**:
- `count >= 2` (matches the Tier-1 → Tier-2 promotion bar in
  `playbooks/tiered-memory-promote.md`), AND
- `success_rate == 1.0` (no failures — failure modes should be recorded as
  cases in `.claude/cases/`, not codified as skills).

Chains below this bar are silently dropped from the report. Mining noise
is worse than missing a pattern.

## Gotchas

- **Never read `morty-journal.jsonl` with `Get-Content` unbounded.** The
  miner uses `-Tail 2000` by default. See `03-context-hygiene.md`.
- **Normalize arguments before hashing.** Raw file paths and commit SHAs
  create false-unique signatures. `mine.ps1` strips project paths, timestamps,
  and SHAs; keep that list current.
- **Ignore v1 entries without `task_id`.** They have no chain boundary and
  will pollute every signature if included.
- **Do not recurse into mining a mining session.** Exclude entries whose
  `task_id` starts with `skill:chain-miner` from the input set.
- **Present, do not persist.** If Mark wants a candidate codified, that is
  `/codify`'s responsibility — not this skill's.
