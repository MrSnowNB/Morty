## 2026-04-24 - PowerShell Array Concatenation Bottleneck
**Learning:** In PowerShell scripts processing large log files (`mine.ps1`), using `+=` array concatenation (`$array += $item`) causes an O(n^2) performance bottleneck due to repeated array reallocation.
**Action:** Always use `[System.Collections.Generic.List[type]]::new()` and the `.Add()` method for appending items in loops within PowerShell scripts.

## 2026-04-25 - PowerShell ConvertFrom-Json Loop Overhead
**Learning:** In PowerShell scripts reading large JSON Lines logs (like `morty-journal.jsonl`), running `ConvertFrom-Json` inside a line-by-line loop is extremely slow due to the overhead of the cmdlet invocation per line.
**Action:** For large read operations of multiple JSON objects, batch them by wrapping in array brackets (`"[" + ($lines -join ",") + "]"`) and running `ConvertFrom-Json` once. This provides up to a 10x performance improvement in execution time.

## 2026-04-27 - PowerShell Pipeline Overhead
**Learning:** In PowerShell scripts, using pipeline commands like `Where-Object` and `ForEach-Object` introduces significant overhead due to context switching and object wrapping, especially for large arrays. Additionally, piping bytes to create hex strings is extremely slow compared to native framework methods.
**Action:** Always prefer native collection methods like `.Where({})` and `.ForEach({})` for collection processing. For string conversion of byte arrays, use native .NET classes like `[BitConverter]::ToString($hash).Replace("-", "").ToLowerInvariant()`.
