## 2024-05-24 - Dynamic Context Window Overflow Management in Local LLM setups
**Learning:** Claude Code relies on standard API context management. Local llama.cpp servers (like Lemonade) drop adaptive instructions natively. This creates a hard context overflow crash loop (400 errors) when the context window fills.
**Action:** Always hook into `PreToolUse` to implement a hard cut-off (e.g. `remaining_pct <= 20%`), forcing humans to rotate context (`/checkpoint` -> `/clear`) to prevent crash loops and state loss. Do not block tools that aid checkpointing like `Bash`, `Write`, `Edit`.
