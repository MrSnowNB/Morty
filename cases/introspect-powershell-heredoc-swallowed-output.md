# Case: introspect PowerShell heredoc swallowed output

**Date:** 2026-04-20  
**Session:** introspect  
**Severity:** Low — partial output loss; no data corruption

## Symptom
Several `pwsh -Command` calls during `/introspect` produced:
```
=: The term '=' is not recognized as a name of a cmdlet, function,
script file, or executable program.
```
The subsequent `Write-Output` lines following the `=` assignment were
swallowed. Affected: journal line count, CLAUDE.md line count reports.

## Root Cause
Inline PowerShell variable assignment syntax (`$x = ...; Write-Output $x`)
was passed to `pwsh -Command` inside a Bash heredoc or argument string
that the shell pre-processed, stripping the `$` and leaving a bare `=`.
PowerShell then failed to parse `=` as a command name.

## Detection
- Output line contains `=: The term '=' is not recognized`
- Expected numeric output is blank or missing
- Subsequent introspect fields show empty values

## Fix
1. Wrap multi-step PowerShell in a script block passed with `-Command { ... }`
   rather than as a bare string.
2. Or use a temp `.ps1` file via `pwsh -File` to avoid shell interpolation.
3. For simple single-value reads (line counts, env vars), use:
   `pwsh -Command "(Get-Content 'path' | Measure-Object -Line).Lines"`
   (already used successfully in the same session — this pattern is safe).

## Reusable Invariant
> Never assign PowerShell variables inline inside `pwsh -Command "..."` when
> the string is passed through Bash. Use `(expression).Property` one-liners
> or a `-File` script block instead.
