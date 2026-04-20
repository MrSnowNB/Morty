# Runtime Profile

## Model
- Name: set by `MORTY_MODEL` env var at launch (e.g. `Qwen3-Coder-Next-GGUF`)
- Endpoint: `http://127.0.0.1:8000` (lemonade server)
- Context window: **128 000 tokens** (set in lemonade Options menu 2026-04-20)
  - Previous value was 64 000 — sessions were hitting hard 400 errors
  - Claude Code compaction does NOT work against llama.cpp: `context_management`
    and `thinking.type: adaptive` fields are silently ignored
  - Manual `/compact` + `/checkpoint` discipline is the only overflow protection

## Shell
- Windows PowerShell (pwsh)
- Working directory: `C:\work\harness-sandbox`
- Scripts in `.claude/skills/*/scripts/*.ps1` require execution policy
  `RemoteSigned` or `Unrestricted` — unsigned scripts will be blocked with
  `SecurityError`. If a skill script fails with this error, use the `Write`
  tool to write the payload directly rather than executing the script.

## MCP Servers (active)
- filesystem, fetch, git, sqlite, playwright

## Permissions snapshot
- 21 allow rules, 46 deny rules
- `Task` tool is denied
