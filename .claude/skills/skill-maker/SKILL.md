---
name: skill-maker
description: Use this when the user asks Morty to learn a new capability, create a new skill, or when a repeated manual procedure should be codified. Creates a new SKILL.md at the correct scope with proper metadata, steps, and gotchas.
---

# Skill Maker

## When to use

- User says "learn to X", "teach yourself X", or invokes `/teach`.
- A multi-step procedure has been repeated 2+ times in the session.
- User explicitly requests a new slash command or capability.

## Steps

1. Confirm the capability's intent in one sentence.
2. Ask scope: user-global (`~/.claude/skills/`) or project (`.claude/skills/`).
3. Choose a kebab-case name.
4. Create `<scope>/skills/<name>/SKILL.md` with frontmatter:
   - `name:` kebab-case
   - `description:` starts with "Use this when…"
5. Outline: When to use, Steps, Gotchas. Optionally: scripts/, references/.
6. If scripts are needed, write them as `.ps1` and reference from SKILL.md.
7. Summarize the new skill and its path to the user.

## Gotchas

- Descriptions that start with "Helps with…" fail routing. Start with "Use this when…".
- Keep SKILL.md concise. Detailed references go in `references/`.
- Never embed secrets or absolute user-specific paths in SKILL.md.
