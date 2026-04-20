# Cold-Start Discipline

On every new session, in order:

1. Read `MORTY.md` (identity) — loaded automatically via @import.
2. Read `CLAUDE.md` (policy) — loaded automatically.
3. If `$MORTY_PROJECT_ROOT/CLAUDE.md` exists, read it now.
4. If `$MORTY_PROJECT_ROOT/logs/*-journal.jsonl` exists, read ONLY the last
   line and parse the anchor fields.
5. Stop. Wait for the user's ticket or instruction.

Do NOT open or read additional project files speculatively. Context is a
budget. Spend it on what the current task requires.
