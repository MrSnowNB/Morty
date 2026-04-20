---
title: Playbook — Tiered Memory Promotion
version: 1.0
---

# Playbook: Tiered Memory Promotion

Use this playbook whenever promoting a finding or procedure from one memory
tier to the next. Do not improvise this flow — follow it exactly.

## Preconditions (check before starting)

- [ ] Current task is complete and output was verified.
- [ ] Pre-Action Gate answered (see `03-context-hygiene.md`).
- [ ] Context fill level is below 70% (if above: defer to next session, write to SCRATCH.md only).
- [ ] Zombie-restore gate was passed at session start (no unverified files in chain).

---

## Tier-0 → Tier-1 (SCRATCH.md finding → .claude/memories/)

**Use when:** A reasoning pattern, constraint, or decision has survived task
completion and is not already covered by an existing memory file.

1. **Invoke Skill: delta-log** — append a DELTA entry to SCRATCH.md documenting
   what you are promoting, why, and how to roll back.
2. **Choose a file name:** next available slot, e.g. `07-*.md`. Keep it under 500 tokens.
3. **Write the memory file** to `.claude/memories/`.
4. **Invoke `/checkpoint`** immediately after the write.
5. **Stop.** Do NOT write any other files after `/checkpoint` this session.

### Abort conditions
- Context fill > 70% → switch to LORA mode, write to SCRATCH.md only, promote next session.
- Source finding is tagged `(unverified)` → do not promote until provenance is confirmed.
- Combined memories size would exceed the 8,000-token cold-start cap → summarize or merge
  before adding a new file.

---

## Tier-1 → Tier-2 (memories/ → playbooks/ or archive)

**Use when:** A memory-encoded procedure has been executed successfully at
least **twice**, as confirmed by journal entries.

1. **Verify execution count:** Search `logs/morty-journal.jsonl` for at least 2
   successful executions of the procedure. Use:
   `powershell -Command "Get-Content logs/morty-journal.jsonl | Select-String 'procedure-name'"`
2. **Invoke Skill: delta-log** — document the promotion.
3. **Write the playbook file** to `.claude/playbooks/`.
4. **Optionally deprecate the source memory file:** add a single line at the top:
   `> Promoted to playbook: .claude/playbooks/[filename].md — [date]`
   Do NOT delete the memory file; it serves as provenance.
5. **Invoke `/checkpoint`** immediately.
6. **Stop.**

### Abort conditions
- Fewer than 2 confirmed successful executions in journal → do not promote.
- Playbook would duplicate an existing one → merge or update instead.

---

## Emergency Rollback

If a promotion was made in error:

1. Identify the DELTA entry in SCRATCH.md for the promotion.
2. Execute the rollback step listed in the delta entry.
3. Invoke `/checkpoint` after rollback.
4. Log a brief note in SCRATCH.md: `## ROLLBACK [timestamp] — [reason]`.
