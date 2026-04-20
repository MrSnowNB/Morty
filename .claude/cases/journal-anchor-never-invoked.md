# Case: journal-anchor never invoked → /introspect shows raw tool call

**Date:** 2026-04-20  
**Diagnosed by:** first-principles session (Morty + Mark)

## Symptom

`/introspect` displayed a raw Bash command object as the last anchor summary:
```
{"command":"wc -l \"C:/work/harness-sandbox/logs/morty-journal.jsonl\"","description":"Count journal lines"}
```

## Five Whys

1. `/introspect` showed a raw command → last journal line was a tool call, not an anchor
2. Last journal line was a tool call → no anchor entries exist in the journal
3. No anchor entries exist → `journal-anchor` skill was never invoked
4. `journal-anchor` was never invoked → `/checkpoint` was never called
5. `/checkpoint` was never called → **no automatic trigger exists; requires explicit invocation that neither Morty nor Mark consistently performed**

## Root Cause

No automatic checkpoint trigger. The skill chain exists and works correctly but
is never activated. The journal fills with `"kind":"tool_call"` entries only.

## Bandage Applied

Manually appended a `"kind":"checkpoint"` entry to `morty-journal.jsonl` so
`/introspect` would display a meaningful summary for that session. This does
not prevent recurrence.

## Durable Fix

Patched `03-context-hygiene.md` with explicit rules requiring Morty to invoke
`/checkpoint` after every non-trivial task (specs, designs, skill edits,
first-principles sessions, session end) without waiting for user instruction.

## Related Issue

PowerShell execution policy blocks unsigned `.ps1` scripts in
`.claude/skills/*/scripts/`. The `append.ps1` helper in `journal-anchor`
cannot run. Workaround: use the `Write` tool to append JSON directly.
See `04-runtime-profile.md` for the standing note.

## Reusable Heuristics

- A skill that exists but is never invoked is equivalent to a skill that does not exist
- `/introspect` reads the **last anchor-kind entry**, not the last line — if no anchor exists, it falls back to the last line regardless of kind
- `wc -l` on the journal is not an anchor; it will poison the display if run near session end
- Always ask "why is this never triggered?" not just "what is triggered incorrectly?"
