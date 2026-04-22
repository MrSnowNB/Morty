# Case: chain-miner mine.ps1 foreach pipeline parse error

**Date:** 2026-04-21  
**Session:** loop-validation-v1  
**Severity:** High — miner completely non-functional until fixed

## Symptom
`pwsh -File .claude/skills/chain-miner/scripts/mine.ps1` failed with:
```
ParserError: C:\work\harness-sandbox\.claude\skills\chain-miner\scripts\mine.ps1:33
Line |
  33 |  } | Where-Object { $_ -ne $null }
     |    ~
     | An empty pipe element is not allowed.
```
The miner could not run at all.

## Root Cause
PowerShell does not allow a `foreach` statement as the left-hand side
of a pipeline. The original code:
```powershell
$entries = foreach ($line in $lines) {
  try { $line | ConvertFrom-Json } catch { $null }
} | Where-Object { $_ -ne $null }
```
...treats `foreach` as a statement, not an expression, so the `|`
operator has nothing on its left side.

## Fix
Wrap the `foreach` block in `@(...)` to force it into an array
expression that can be piped:
```powershell
$entries = @(foreach ($line in $lines) {
  try { $line | ConvertFrom-Json } catch { $null }
}) | Where-Object { $_ -ne $null }
```

## Detection
- `ParserError` on the line after the closing `}` of a `foreach` block
- Message: `An empty pipe element is not allowed`

## Reusable Invariant
> In PowerShell, `foreach` is a statement, not a pipeline expression.
> To pipe the output of a `foreach` block, always wrap it in `@(...)`.
> Alternatively, use `$lines | ForEach-Object { ... }` which IS a
> pipeline-native cmdlet.
