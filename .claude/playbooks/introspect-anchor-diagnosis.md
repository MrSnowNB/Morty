# Playbook: Introspect Anchor Diagnosis

## Trigger

Any of:
- `/introspect` returns no anchor or unexpected output
- Session state appears stale or wrong after a cold start
- Journal tail does not contain an anchor entry

## Invariant

> Anchor detection must filter on the **`kind` field value**, not on substring text matching. `Select-String 'anchor'` will match any line containing the word "anchor" and is unreliable.

## Procedure

1. Read the last 20 lines of `logs/morty-journal.jsonl` using:
   ```powershell
   Get-Content logs/morty-journal.jsonl -Tail 20
   ```
2. Scan for an entry where the `kind` field equals `"anchor"` exactly.
3. If an anchor entry is found: report its `task`, `summary`, and `timestamp` fields.
4. If no anchor entry is found:
   - Report cleanly: "No anchor found in last 20 lines. Last recorded action was [describe last entry]."
   - Do NOT synthesize or guess a prior state.
   - Do NOT recommend `/checkpoint` unless meaningful work has actually concluded in this session.
5. If the anchor exists but is buried under subsequent `tool_call` entries, note that the anchor is stale and recommend checkpoint discipline going forward.

## Stop Condition

Anchor status is determined and reported. No further journal reads are needed.

## Validation

- Result should be one of: anchor found with fields, or clean fallback message.
- Never use `Select-String 'anchor'` — use explicit `kind` field parsing.

## Avoid

- `Select-String 'anchor'` or any substring match on the word "anchor"
- Recommending `/checkpoint` when no meaningful work has occurred in this session
- Reading the entire journal file (always use `-Tail 20` or similar bound)
