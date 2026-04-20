---
description: Compact context with Morty's preservation prompt.
---
Before compacting, run /checkpoint.

Then compact with this preservation contract:
- PRESERVE: project overview, current task and state, recent decisions (last 5),
  open questions, next immediate action, bound model name, active skills.
- DISCARD: speculative exploration, rejected approaches, raw tool outputs,
  pasted file contents already on disk.

After compaction, read the last line of the project journal to confirm state
continuity, then report: "compaction complete, resumed at <anchor summary>".
