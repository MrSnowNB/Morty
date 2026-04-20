# Launching Morty

Morty runs on top of Claude Code, pointed at a local [Lemonade Server](https://github.com/lemonade-hq/lemonade) instance serving `Qwen3-Coder-Next-GGUF`.

## Quick Start

### 1. Install the launcher (one time)

```powershell
powershell -ExecutionPolicy Bypass -File install\add-morty-profile.ps1
. $PROFILE
```

### 2. Start Lemonade Server

Open the Lemonade GUI and confirm:
- **STATUS: CONNECTED** in the bottom bar
- **Qwen3-Coder-Next-GGUF** appears under Active Models

### 3. Launch Morty

```powershell
cd C:\work\harness-sandbox   # or any project directory
morty
```

The launcher will print three confirmation lines:

```
[morty] endpoint : http://127.0.0.1:8000
[morty] model    : Qwen3-Coder-Next-GGUF
[morty] project  : C:\work\harness-sandbox
```

Then Claude Code opens. First prompt: `/introspect`

---

## How Endpoint Detection Works

`launchers/morty-endpoint.ps1` probes ports `8000, 8001, 8004, 8080` in order.
It hits `/api/v1/models` on each and checks the response for `Qwen3-Coder-Next`.
The first port that matches is returned. If none match, the launcher aborts with a clear error before touching Claude.

Lemonade's **router** is stable on port 8000. The internal `llama-server` subprocess
uses a different ephemeral port — that port is internal only and should be ignored.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Lemonade not reachable` | Server not running | Open Lemonade GUI, wait for CONNECTED |
| `Connection failed: Failed to read connection` | Launched before server fully up | Wait ~5s and retry |
| `No endpoint found on ports: 8000, 8001...` | Model not loaded | In Lemonade GUI, load Qwen3-Coder-Next-GGUF |
| Hook errors (`%USERPROFILE%...`) | Old path syntax in `settings.json` | Run `install\fix-settings-paths.ps1` (see below) |
| `morty: command not found` | Profile not reloaded | Run `. $PROFILE` |

---

## Uninstall

Remove the `# <morty-launcher>` block from your `$PROFILE`:

```powershell
$p = Get-Content $PROFILE -Raw
$p = $p -replace '(?s)\r?\n# <morty-launcher>.*?# </morty-launcher>', ''
Set-Content $PROFILE $p -Encoding utf8
```

---

## Environment Variables Set by `morty`

| Variable | Value | Purpose |
|---|---|---|
| `ANTHROPIC_BASE_URL` | Detected Lemonade URL | Directs Claude Code to local LLM |
| `ANTHROPIC_API_KEY` | `lemonade-local` | Satisfies Claude Code's auth check |
| `ANTHROPIC_MODEL` | `Qwen3-Coder-Next-GGUF` | Model selection |
| `MORTY_MODEL` | `Qwen3-Coder-Next-GGUF` | Available to hooks and skills |
| `MORTY_PROJECT_ROOT` | Current directory at launch | Used by journal-anchor and skills |
