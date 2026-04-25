## 2026-04-24 - PowerShell Array Concatenation Bottleneck
**Learning:** In PowerShell scripts processing large log files (`mine.ps1`), using `+=` array concatenation (`$array += $item`) causes an O(n^2) performance bottleneck due to repeated array reallocation.
**Action:** Always use `[System.Collections.Generic.List[type]]::new()` and the `.Add()` method for appending items in loops within PowerShell scripts.

## 2026-04-25 - Dynamic Context Window Overflow Management in Local LLM setups
**Learning:** Claude Code relies on standard API context management. Local llama.cpp servers (like Lemonade) drop adaptive instructions natively. This creates a hard context overflow crash loop (400 errors) when the context window fills.
**Action:** Always hook into `PreToolUse` to implement a hard cut-off (e.g. `remaining_pct <= 20%`), forcing humans to rotate context (`/checkpoint` -> `/clear`) to prevent crash loops and state loss. Do not block tools that aid checkpointing like `Bash`, `Write`, `Edit`.

## 2026-04-25 - PowerShell ConvertFrom-Json Performance Bottleneck
**Learning:** In PowerShell scripts processing large log files (`mine.ps1`), using `ConvertFrom-Json` inside a `foreach` loop creates massive pipeline overhead.
**Action:** Always batch parse JSON Lines logs by joining them into a single JSON array string (e.g., ` "[" + ($lines -join ",") + "]" `) and parsing once with `ConvertFrom-Json`. Include a `try/catch` fallback to line-by-line parsing to handle malformed entries gracefully.
