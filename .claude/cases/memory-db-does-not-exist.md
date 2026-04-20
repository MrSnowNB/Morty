# Case: memory.db referenced but does not exist

**Date:** 2026-04-20  
**Observed during:** Session test (Step 4 self-checkpoint)

## Symptom

Morty attempted to create and query `C:\Users\AMD\.claude\memory.db` via
`System.Data.SQLite.SQLiteConnection`. The assembly is not installed. The DB
file does not exist. All SQLite-based checkpoint and history lookups fail.

## Root Cause

Earlier versions of `03-context-hygiene.md` referenced `mcp__sqlite__read_query`
against a `checkpoints` table in `memory.db`. This path was designed for a
SQLite MCP server that is not active and a DB that was never seeded. The
reference is stale.

## Fix Applied

Removed all `memory.db` and `mcp__sqlite__read_query` references from
`03-context-hygiene.md`. Journal rehydration now uses:
```powershell
Get-Content logs/morty-journal.jsonl -Tail 20
```
as the documented primary path.

## Reusable Heuristics

- `memory.db` does not exist on this system — do not attempt to create or query it
- `System.Data.SQLite` assembly is not installed — PowerShell SQLite calls will fail
- The journal (`logs/morty-journal.jsonl`) is the authoritative history source
- Always use `-Tail <n>` when reading the journal to avoid context overflow
