---
name: repo-onboard
description: Use this when the user has just opened, cloned, or switched into an unfamiliar repository. Performs a disciplined read of README, manifest files, entry points, and tests, then drafts a minimal project CLAUDE.md stub for approval.
---

# Repo Onboard

## Steps

1. Run `/introspect` to confirm the current project root.
2. Read `README.md` (or `README.rst`) if present.
3. Read ONE manifest: `pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`,
   or `pom.xml` — whichever exists.
4. Identify entry points (scripts, main, bin).
5. Identify the test command (pytest, npm test, cargo test, etc.).
6. Draft `CLAUDE.md` stub at project root with:
   - Stack summary
   - Journal path convention
   - Test command
   - Commit protocol hint
7. Present stub to user for approval. Do NOT commit without approval.

## Gotchas

- Do not read source files during onboarding. Metadata first.
- If README is missing, say so explicitly. Do not invent a purpose.
- Never overwrite an existing CLAUDE.md. Read it and report it instead.
