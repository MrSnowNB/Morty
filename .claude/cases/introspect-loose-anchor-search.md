# Case: /introspect anchor search matches wrong lines

**Date:** 2026-04-20  
**Observed during:** Regression test after PR #6

## Symptom

`/introspect` reported the last anchor as an `AskUserQuestion` tool call whose
payload text happened to contain the word "anchor". The displayed summary was
a raw JSON options array, not a semantic anchor entry.

## Root Cause

The `introspect.md` command gave no specific instructions for how to find
anchor entries. Morty improvised with:
```powershell
Get-Content ... | Select-String 'anchor'
```
This is a loose substring match. It matches any journal line containing the
word "anchor" — including `"kind":"tool_call"` entries whose `summary` JSON
happens to include the word.

The correct filter targets the `kind` field specifically:
```powershell
Where-Object { $_ -match '"kind":"(checkpoint|done|decision|close|issue)"' }
```

## Fix Applied

Added an explicit **"Finding the last anchor summary"** section to
`introspect.md` with the exact PowerShell command to use and a prohibition
against `Select-String 'anchor'`.

## Reusable Heuristics

- Substring search on structured data (JSONL) will produce false positives
- Always filter on the specific field (`kind`) not the word in any field
- When writing commands that parse JSONL, specify the exact field match pattern
- Underdefined instructions produce improvised solutions that are often wrong
