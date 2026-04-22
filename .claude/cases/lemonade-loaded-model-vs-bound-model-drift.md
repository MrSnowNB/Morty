# Case: lemonade loaded model diverges from MORTY_MODEL

**Date:** 2026-04-20  
**Session:** introspect  
**Severity:** Medium — all inference silently served by wrong model

## Symptom
`$env:MORTY_MODEL` reported `Qwen3-Coder-Next-GGUF` but
`curl http://127.0.0.1:8000/api/v1/health` showed:
```
model_loaded: user.Qwen3.6-35B-A3B-GGUF
all_models_loaded: [user.Qwen3.6-35B-A3B-GGUF]
```
Every inference call in the session was served by `Qwen3.6-35B-A3B-GGUF`,
not the bound model. Model tracking was silently wrong.

## Root Cause
Lemonade server loads whichever model was last selected in the UI — it does
not read `$env:MORTY_MODEL`. If the UI selection and the env var diverge
(e.g. after a model swap in Lemonade without updating settings.json, or
vice versa), all inference runs on the loaded model regardless of what
the env var says.

## Detection
`curl http://127.0.0.1:8000/api/v1/health` — compare `model_loaded` against
`$env:MORTY_MODEL`. Any mismatch is drift.

## Fix
1. Immediate: update `MORTY_MODEL` in `settings.json` and `$env:` to match
   what the health endpoint reports.
2. Structural: add a boot-time guard that compares the two and fails loudly
   if they diverge (tracked as `feat/boot-model-drift-guard`).

## Reusable Invariant
> `$env:MORTY_MODEL` declares intent. `GET /api/v1/health model_loaded`
> reports reality. Always check both at session start. If they diverge,
> correct the env var (or switch the loaded model) before running any task.
