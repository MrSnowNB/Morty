# Cold-Start Discipline

On every new session, follow the AI-FIRST bootstrap sequence exactly:

**Primary reference: `.claude/AI-FIRST/CONTEXT.md`**

Short form (in order):

1. Read `MORTY.md` (identity) — loaded automatically via @import.
2. Read `CLAUDE.md` (policy) — loaded automatically.
3. Read `.claude/memories/03-context-hygiene.md` — context budget and gate rules.
4. If `$MORTY_PROJECT_ROOT/CLAUDE.md` exists, read it now.
5. Read the **last 20 lines** of `logs/morty-journal.jsonl` — only if the task requires recent session state.
6. Search `.claude/cases/` — only if the current task **resembles a known failure pattern**. Do not scan by default.
7. Check `.claude/playbooks/` — if a playbook matches the current task, follow it before improvising.
8. **Stop. Wait for the user's task or ticket.**

## Hard Rules

- Do NOT open or read additional project files speculatively. Context is a budget. Spend it on what the current task requires.
- Do NOT improvise a startup sequence different from the one above.
- Case search is gated on resemblance — not a default startup action.
- Playbooks take precedence over improvisation for any covered operational flow.
