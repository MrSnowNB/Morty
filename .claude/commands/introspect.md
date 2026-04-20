---
description: Report Morty's current runtime state — model, skills, permissions, scope, journal.
---
Produce a Markdown report with these sections:

- **Bound model**: value of `$MORTY_MODEL`
- **Endpoint**: value of `$ANTHROPIC_BASE_URL`
- **Project root**: value of `$MORTY_PROJECT_ROOT`
- **Project CLAUDE.md**: present? path? line count?
- **Project journal**: path, line count, last anchor summary (see below)
- **Loaded skills**: list from `~/.claude/skills/` and `$MORTY_PROJECT_ROOT/.claude/skills/`
- **Active MCP servers**: list from `.mcp.json`
- **Permissions**: count of allow / deny rules, confirm `Task` is denied
- **Claude version**: output of `claude --version`

## Finding the last anchor summary

Anchor entries have `"kind"` set to one of: `checkpoint`, `done`, `decision`,
`close`, `issue`, `task_begin`, or `task_end`. They are distinct from
`"kind":"tool_call"` entries.

Use this exact PowerShell command to find the last anchor:

```powershell
powershell -Command "Get-Content 'logs/morty-journal.jsonl' -Tail 100 | Where-Object { $_ -match '\"kind\":\"(checkpoint|done|decision|close|issue|task_begin|task_end)\"' } | Select-Object -Last 1"
```

- If a matching line is found, extract and display its `summary` field.
- If no matching line is found in the last 100 entries, report:
  `No anchor entry found — journal contains only tool_call entries.`
- Do NOT use `Select-String 'anchor'` — that matches any line containing
  the word "anchor" regardless of the `kind` field, including tool calls
  whose payload happens to mention the word.
