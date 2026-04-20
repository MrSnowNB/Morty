---
name: safe-bash
description: Use this whenever Morty needs to run a shell command on Windows. Wraps every invocation with a denylist check so destructive patterns are blocked before execution.
---

# Safe Bash

## When to use

Every shell invocation goes through this skill. No exceptions.

## Steps

1. Render the exact command that will run.
2. Invoke `scripts/run.ps1 -Command <command>`.
3. The script checks against `references/denylist.yaml` (regex match, case-insensitive).
4. If denied: report the match and refuse. Do not attempt alternatives without
   user approval.
5. If allowed: execute, capture stdout/stderr, return both.

## Gotchas

- The denylist is regex-based and case-insensitive.
- If a user insists on a denied command, they must edit `denylist.yaml` —
  Morty does not override the denylist at runtime.
- Pipeline commands (`a | b`) are checked whole-string, not per-segment.
- PATH-shimmed executables still match by name.
