description: Use this when the user wants to change the terminal output color. Supports: red, blue, green, yellow, purple, orange, pink, cyan, default.

Steps the agent will take:

1. Ask the user which color they want (unless already specified)
2. Output text in the selected color using ANSI escape codes
3. Report the change to the user

Gotchas:
- ANSI color codes only work in terminals that support them (not all Claude Code clients)
- Colors may appear differently depending on the terminal's color scheme
- This is a visual change only - no settings file is modified
