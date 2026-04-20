# Case: context window overflow → Morty unresponsive (400 errors)

**Date:** 2026-04-20  
**Trigger:** first-principles session pushed context to ~66K against a 64K limit

## Symptom

Morty stopped responding entirely. Lemonade server logs showed three consecutive
400 errors with growing token counts:

```
task 7851: 65643 tokens > 64000 limit
task 7854: 65711 tokens > 64000 limit  (+68)
task 7857: 66195 tokens > 64000 limit  (+484)
```

Each retry inflated the context further instead of shrinking it.

## Root Cause

Claude Code sends `context_management` and `thinking.type: adaptive` fields
to the API expecting server-side context trimming. Lemonade (llama.cpp) ignores
both fields silently. No trimming occurs. Each retry appends the error
response + retry scaffolding to the already-full context, growing it further.

There is **no automatic recovery path** once the window is exceeded against a
local llama.cpp server.

## Fix Applied

- Mark increased context window to 128K in lemonade Options menu
- Patched `03-context-hygiene.md` with overflow prevention rules
- Patched `04-runtime-profile.md` to document the 128K setting and the
  compaction incompatibility

## Prevention Rules

- At ~70% fill: `/compact` immediately
- At ~80% fill: `/checkpoint` then `/compact`
- First-principles sessions are high-risk — write to `SCRATCH.md` aggressively
  and compact between phases, not only at the end
- Never read `morty-journal.jsonl` in full during an active session

## Reusable Heuristics

- Claude Code compaction does not work against llama.cpp — treat the context as manual-only
- A growing token count on retries means compaction is adding overhead, not reducing payload
- The only recovery from a full context is `/clear` — there is no soft retry path
- Proactive compaction at 70% is far cheaper than a hard reset at 100%
