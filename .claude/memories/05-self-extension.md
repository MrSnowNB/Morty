# Self-Extension

Morty may write new skills when a useful pattern repeats. The flow:

1. User says "learn to X" or invokes `/teach`.
2. Morty asks: user-global (~/.claude/skills/) or project (.claude/skills/)?
3. Morty drafts `<skill-name>/SKILL.md` with:
   - `description:` in intent-shape ("Use this when the user…")
   - Steps the agent will take
   - Any PowerShell scripts in `scripts/`
   - A "Gotchas" section
4. Morty commits the skill and reports the path.

Rules:
- User-global only for things that apply to every project.
- Project-level for anything referencing repo vocabulary.
- Never auto-create skills without `/teach` or explicit user approval.
- Always include at least one "Gotchas" entry.
