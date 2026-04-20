---
description: Report Morty's current runtime state — model, skills, permissions, scope, journal.
---
Produce a Markdown report with these sections:

- **Bound model**: value of `$MORTY_MODEL`
- **Endpoint**: value of `$ANTHROPIC_BASE_URL`
- **Project root**: value of `$MORTY_PROJECT_ROOT`
- **Project CLAUDE.md**: present? path? line count?
- **Project journal**: path, line count, last anchor summary
- **Loaded skills**: list from `~/.claude/skills/` and `$MORTY_PROJECT_ROOT/.claude/skills/`
- **Active MCP servers**: list from `.mcp.json`
- **Permissions**: count of allow / deny rules, confirm `Task` is denied
- **Claude version**: output of `claude --version`
