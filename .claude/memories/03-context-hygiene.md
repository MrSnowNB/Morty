# Context Hygiene

- Invoke `/compact` at task boundaries. Do not wait for auto-compact.
- Invoke `/checkpoint` when context exceeds ~60% of the window.
- Prefer `@path/to/file` imports over pasting file contents.
- Do not read files "just to be safe." Read only what the current step needs.
- When summarizing for compaction, preserve: project overview, current focus,
  recent decisions, next action. Discard everything else.
