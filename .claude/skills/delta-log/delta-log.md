---
title: delta-log — implementation reference
version: 1.0
---

# delta-log — Implementation Reference

This file documents the runtime procedure for writing a delta entry.
It is the companion doc to SKILL.md which defines the schema.

## Step-by-step

1. Before any destructive write, open SCRATCH.md with a Read call.
2. Append the delta block (see SKILL.md for format) using an Edit or Write.
3. Confirm the entry is visible in SCRATCH.md with a second Read.
4. Proceed with the actual write only after step 3 confirms the delta is logged.

## Integrity tag generation

For memory files and playbooks, compute a short CRC32 of the file content:
```powershell
$bytes = [System.IO.File]::ReadAllBytes($path)
$crc = [System.IO.Hashing.Crc32]::Hash($bytes)
[Convert]::ToHexString($crc)
```

For large files, use the first 8 hex chars of SHA256 instead:
```powershell
$sha = [System.Security.Cryptography.SHA256]::Create()
$bytes = [System.IO.File]::ReadAllBytes($path)
$hash = $sha.ComputeHash($bytes)
($hash | ForEach-Object { $_.ToString('x2') }) -join '' | Select-Object -First 1 |
  ForEach-Object { $_.Substring(0,8) }
```

## Failure recovery

If the actual write fails AFTER the delta is written:
- The delta entry in SCRATCH.md is the recovery artifact.
- Do NOT delete or edit the delta entry.
- Write a ROLLBACK note below the delta entry:
  `## ROLLBACK [timestamp] — [reason write failed]`
- Report to Mark.

## Anti-patterns

| Anti-pattern | Why it breaks |
|---|---|
| Write delta AFTER the destructive action | Defeats the entire audit purpose |
| Use delta-log for read-only tool calls | Noise — pollutes SCRATCH.md |
| Edit a delta entry after writing it | Makes the trail untrustworthy |
| Log the delta-log invocation itself | Recursive loop |
