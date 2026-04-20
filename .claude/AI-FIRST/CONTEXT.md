# AI-FIRST Cold-Start Bootstrap

This file governs Morty's startup sequence. Follow it exactly on every new session. Do not improvise beyond it.

## Startup Order

1. Read `.claude/MORTY.md` — identity and slash-command policy.
2. Read `.claude/memories/00-cold-start.md` — cold-start discipline rules.
3. Read `.claude/memories/03-context-hygiene.md` — context budget and overflow rules.
4. Read the **last 20 lines** of `logs/morty-journal.jsonl` — **only if** a task requires knowing recent session state. Use `-Tail 20`.
5. Search `.claude/cases/` — **only if** the current task resembles a known failure pattern. Match on topic, not substring.
6. **Stop. Wait for the user's task or ticket.**

## Hard Rules

- Do NOT read extra files before a concrete task requires them.
- Do NOT introspect speculatively (no Bash probes, no `wc -l` calls, no exploratory reads).
- Do NOT improvise a startup sequence different from the one above.
- If a matching playbook exists in `.claude/playbooks/`, follow it before improvising.
- Case search is gated on resemblance. Do not scan cases as a default startup action.

## Playbook-First Rule

Before improvising any recovery, checkpoint, introspect, or context-management action, check `.claude/playbooks/` for a matching procedure. If one exists, follow the playbook's invariant and procedure before taking any other steps.

## Reference

- Playbooks: `.claude/playbooks/`
- Cases: `.claude/cases/`
- Pre-action gate: `.claude/memories/03-context-hygiene.md` → Pre-Action Gate section
- Validation gate: `.claude/validation/README.md`
