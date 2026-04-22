# Boot-loop validation

`boot-validation.ps1` is a SessionStart hook that fails loud when the harness is misconfigured in ways that otherwise produce silent degradation — hooks that don't fire, journals that write to literal `${CLAUDE_PROJECT_DIR}/logs/` directories, env vars that drift from `settings.json`, denylists that point at missing files, etc.

## What it checks

| # | Check | Severity |
|---|-------|----------|
| 1 | `CLAUDE_PROJECT_DIR` is exported AND expanded AND resolves to a real directory | FAIL |
| 2 | `MORTY_MODEL` env var agrees with the one in `settings.json` (env wins; mismatch is misleading) | WARN |
| 3 | `logs/` exists and is writable under the project root | FAIL (write failure) / WARN (missing) |
| 4 | No literal `${CLAUDE_PROJECT_DIR}` directory exists under the project root — the smoking gun for an unexpanded-placeholder write | FAIL |
| 5 | `PreToolUse` (pre-bash.ps1) AND `PostToolUse` (post-tool.ps1 → journal) hooks are wired in `settings.json` | FAIL on PostToolUse missing, WARN on PreToolUse |
| 6 | If `MORTY_DENYLIST` env is set in `settings.json`, the file exists at that path | FAIL |
| 7 | Core skills present (`first-principles`, `journal-anchor`, `safe-bash`, `checkpoint-writer`) | WARN |

## How to wire it

Add a `SessionStart` hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File ${CLAUDE_PROJECT_DIR}/.claude/hooks/boot-validation.ps1"
          }
        ]
      }
    ]
  }
}
```

If any check fails, the script exits 1 and prints a remediation checklist with the exact fix for each failure. Warnings do not abort the session unless you pass `-Strict`.

## Flags

| Flag | Purpose |
|------|---------|
| `-ProjectRoot <path>` | Override `CLAUDE_PROJECT_DIR`. Default: env var, falling back to `$PWD`. |
| `-SettingsPath <path>` | Override the settings.json path. Default: `$HOME/.claude/settings.json`. |
| `-Strict` | Fail on warnings too. Intended for CI smoke tests. |
| `-Json` | Emit a JSON summary alongside the text report. |

## Why this hook exists

This hook is a direct response to observed harness failures:

1. **Unexpanded placeholder directories.** A post-tool hook wrote to `${CLAUDE_PROJECT_DIR}/logs/morty-journal.jsonl` as a literal path string — creating an actual directory called `${CLAUDE_PROJECT_DIR}` in the workspace root. Silent. No error surfaced. Only caught when a human noticed the weird directory in `git status`.
2. **Env vs settings.json drift.** `MORTY_MODEL` was set to `Qwen3-Coder-Next-GGUF` in `settings.json` but an older shell export was injecting `user.Qwen3.6-35B-A3B-GGUF`. Runtime used the shell export; `/introspect` reported the settings value. Disagreement was invisible until someone manually diffed them.
3. **Post-tool hook absence.** A hook can be silently missing from `settings.json` — no journal gets written, chain-miner sees nothing, and nobody notices until a `/introspect` check shows zero journal lines.

All three of these became case studies under `.claude/cases/`. This hook catches them at boot instead of hours into a session.

## Running the smoke test

CI runs the script against the repo checkout with `-Strict` (passes when the repo is in a clean, wired state):

```
pwsh -NoProfile -File .claude/hooks/boot-validation.ps1 -ProjectRoot . -Strict -SettingsPath .claude/settings.example.json
```

The example settings file ships a known-good config so CI has something to diff against.
