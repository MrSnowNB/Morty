---
description: Propose the top mined chain as a new skill for /teach ratification. Proposes only — never writes to .claude/skills/ without user approval.
argument-hint: "[signature-prefix] (optional — pick a specific candidate)"
---

Review mined chains in `SCRATCH.md` and propose the top candidate as a new
skill for Mark to ratify via `/teach`.

This command is the **PROPOSE** phase of recursive self-improvement. It
performs the synthesis work but stops short of writing anything to
`.claude/skills/`. Memory `05-self-extension.md` is explicit: skills are
never auto-created without `/teach` or explicit user approval.

## Preconditions

1. Pre-Action Gate answered (see `03-context-hygiene.md`).
2. LoRa-mux mode is NOT `LORA` (fill < 70%). If in LORA mode, defer to next
   session and append a SCRATCH note.
3. `SCRATCH.md` contains at least one `## MINE [...]` block from a recent
   `chain-miner` run. If not, run `chain-miner` first.

## Steps

1. Read the **latest** `## MINE` block from `SCRATCH.md`. Do not read prior
   MINE blocks — only the most recent run is authoritative.
2. If `$ARGUMENTS` is provided, select the candidate whose `signature` starts
   with that prefix. Otherwise, select the candidate with the highest
   `count × success_rate` that is not already covered by an existing skill.
3. **Coverage check.** For the selected candidate, scan the `description:`
   frontmatter field of every file in `~/.claude/skills/*/SKILL.md` and
   `.claude/skills/*/SKILL.md`. If the chain's `representative_summary`
   substantially overlaps with an existing skill's description, skip this
   candidate and move to the next. Report the skip with the matched skill
   path so Mark can decide whether to extend the existing skill instead.
4. **Invoke the `delta-log` skill** to append a DELTA entry to SCRATCH.md
   documenting the proposal (action-type: `skill-proposal`). The DELTA is the
   rollback artifact if `/teach` is declined.
5. **Present the proposal to Mark** in a single screen:
   - Proposed `name:` (kebab-case, derived from the dominant tool sequence)
   - Proposed `description:` starting with "Use this when…"
   - `Steps:` — the distilled chain, one line per step, purpose not mechanics
   - `Gotchas:` — derived from `exit_status=error` entries inside any
     same-signature task in the miner's raw data
   - `Evidence:` count, success_rate, sample_task_ids
6. **Stop.** Do NOT write `SKILL.md`. Wait for Mark to invoke `/teach` (which
   calls `skill-maker`) if the proposal is accepted.

## If accepted

Mark invokes `/teach <capability>` referencing this proposal. `skill-maker`
then owns the actual write. After the new skill is saved, Mark invokes
`/checkpoint` to anchor the self-extension event in the journal.

## If declined

No state change is needed — the proposal was never persisted to `.claude/`.
The DELTA entry in SCRATCH.md remains as evidence the proposal existed and
was considered. Optionally, record the decline as a case in `.claude/cases/`
if the rejection reason is generalizable.

## Gotchas

- Never pick more than one candidate per `/codify` run. Batched proposals
  overwhelm review and violate the "one meaningful action per gate" pattern.
- Never codify a chain that includes `/checkpoint`, `/compact`, `/task-begin`,
  `/task-end`, or `/introspect` as inner steps — those are session-control
  primitives and must not be wrapped by skills.
- Never codify a chain whose representative_summary is a single tool call.
  One-step "chains" are not chains.
- If the dominant tool in the chain is `Bash`, scrutinize the `arg_shape`:
  if multiple distinct commands map to the same shape after normalization,
  the chain is probably too loose to codify yet. Ask Mark.
