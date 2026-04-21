---
title: Memory — 03-context-hygiene
tier: 1
version: 1.1
changelog:
  1.1: Add SCRATCH.md anchor preservation rule and raw-dump prohibition
---

# Context Hygiene

## Rule 1 — No raw journal dumps into response context

Never pipe full journal JSON objects into a Bash response or include them
in tool output summaries. Use `Select-Object` to extract only the fields
you need (e.g. `ts`, `kind`, `task_id`). Violating this rule causes rapid
context fill and risks 400 overflow errors.

Correct:
```powershell
Get-Content logs/morty-journal.jsonl -Tail 20 |
  ConvertFrom-Json |
  Select-Object ts, kind, task_id |
  Format-Table -AutoSize
```

Wrong:
```powershell
Get-Content logs/morty-journal.jsonl -Tail 20
```

## Rule 2 — Temp scripts must be cleaned up

Any `_tmp_*.ps1` file written to `logs/` must be deleted at the end of the
task that created it. Do not accumulate temp files across sessions.

## Rule 3 — SCRATCH.md anchor must be preserved

SCRATCH.md must always contain the line:
```
<!-- CHAIN-SEED-ANCHOR -->
```
This line is the fixed Edit target for chain-seed warm-up tasks. If it is
missing (e.g. SCRATCH.md was overwritten), restore it before running
chain-seed. Never remove or modify this line outside of the chain-seed
warm-up sequence.

## Rule 4 — zombie-restore context extraction only

During zombie-restore Gate 1, read journal tail for timestamps only.
Do not echo full JSON blobs into the response. Extract `ts` and `kind`
fields only.
