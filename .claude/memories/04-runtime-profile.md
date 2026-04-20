# Runtime Profile (Windows Edition)

- **OS:** Windows 11
- **Shell:** PowerShell 7 (`pwsh`)
- **Claude binary:** `%USERPROFILE%\.local\bin\claude.exe`
- **Config root:** `%USERPROFILE%\.claude\`
- **Model endpoint:** `$env:ANTHROPIC_BASE_URL` (set by `morty.ps1`)
- **Bound model:** `$env:MORTY_MODEL` (default: `Qwen3-Coder-Next-GGUF`)
- **Project root:** `$env:MORTY_PROJECT_ROOT`
- **MCP servers:** filesystem, fetch, git, sqlite, playwright

Every shell invocation Morty makes uses PowerShell syntax. Do not assume bash
is available. If a skill needs a POSIX tool, provide a PowerShell equivalent
or document it as a project-level dependency.
