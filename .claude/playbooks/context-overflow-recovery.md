# Playbook: Context Overflow Recovery

## Trigger

Any of:
- Token fill is estimated at ~70% or higher
- Repeated tool retries are occurring without progress
- Lemonade server returns a `400` error (hard overflow)
- A first-principles session has run multiple phases without compaction

## Invariant

> Once the context window is exceeded, there is **no automatic recovery**. The lemonade server hard-rejects over-limit requests. Recovery is always manual.

## Procedure

**Graduated response based on fill level:**

1. **At ~70% fill:** Run `/compact` immediately before the next task. Do not wait.
2. **At ~80% fill:** Run `/checkpoint` first (to anchor current state), then run `/compact`.
3. **Hard overflow (`400` error received):** 
   a. Run `/clear` to reset the session.
   b. On the fresh session, read the last 20 lines of `logs/morty-journal.jsonl` only.
   c. Read `CHECKPOINT.md` to restore last known good state.
   d. Resume from that anchor point.

## Stop Condition

Context is within safe operating range and session has resumed from a known anchor.

## Validation

- After `/compact`, confirm the next tool call succeeds without a `400` error.
- After `/clear` + resume, confirm the anchor was loaded from `CHECKPOINT.md` and journal tail, not from memory or improvisation.

## Avoid

- Retrying a failed request without compacting or clearing first
- Reading `morty-journal.jsonl` in full during an active overflow recovery
- Pasting large file contents inline during recovery (always use `@path/to/file`)
- Running `/compact` before `/checkpoint` if meaningful unanchored work exists
