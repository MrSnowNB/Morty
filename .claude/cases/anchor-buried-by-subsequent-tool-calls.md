# Case: journal anchor buried by subsequent tool calls

**Date:** 2026-04-20  
**Observed during:** Session test (Step 4 self-checkpoint)

## Symptom

Morty successfully wrote a `"kind":"checkpoint"` anchor entry to the journal
(line 118). However, subsequent Bash commands during the same session appended
new `"kind":"tool_call"` entries after it. The anchor was no longer the last
line. `/introspect` reading the last line still displayed a raw tool call.

## Root Cause

No ordering rule existed requiring `/checkpoint` to be the **final** action of
a session. Morty wrote the anchor, then continued working (reading files,
running Bash commands), which pushed the anchor into the middle of the journal.

## Fix Applied

Added rule to `03-context-hygiene.md`:
> `/checkpoint` must be the last meaningful action of a session. Do not run
> Bash commands, file reads, or any other tool calls after it.

## Reusable Heuristics

- An anchor that is not the last journal entry is invisible to `/introspect`
- Write the anchor last — treat it like sealing an envelope before sending
- If post-anchor work is needed, write a second anchor at the true end
- The only safe operation after `/checkpoint` is `/compact` or `/clear`
