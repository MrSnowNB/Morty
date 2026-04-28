## 2026-04-24 - PowerShell Array Concatenation Bottleneck
**Learning:** In PowerShell scripts processing large log files (`mine.ps1`), using `+=` array concatenation (`$array += $item`) causes an O(n^2) performance bottleneck due to repeated array reallocation.
**Action:** Always use `[System.Collections.Generic.List[type]]::new()` and the `.Add()` method for appending items in loops within PowerShell scripts.

## 2026-04-25 - PowerShell ConvertFrom-Json Loop Overhead
**Learning:** In PowerShell scripts reading large JSON Lines logs (like `morty-journal.jsonl`), running `ConvertFrom-Json` inside a line-by-line loop is extremely slow due to the overhead of the cmdlet invocation per line.
**Action:** For large read operations of multiple JSON objects, batch them by wrapping in array brackets (`"[" + ($lines -join ",") + "]"`) and running `ConvertFrom-Json` once. This provides up to a 10x performance improvement in execution time.

## 2024-05-18 - PowerShell Array Concatenation Bottleneck (Boot Validation)
**Learning:** Found remaining instances of `+=` array concatenation (`$array += $item`) in `.claude/hooks/boot-validation.ps1` and associated test scripts. Using `+=` causes an O(n^2) performance bottleneck due to repeated array reallocation, which is especially noticeable when aggregating numerous validation results or test failures.
**Action:** Converted `$oks`, `$warns`, `$fails`, and `$failures` arrays to `[System.Collections.Generic.List[object]]::new()` and used the `.Add()` method. Always use generic lists and `.Add()` for dynamically growing collections in PowerShell.
