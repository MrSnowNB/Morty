# Playbook: Checkpoint at Session End

## Trigger

Any of:
- Session is closing
- A spec has been completed
- A first-principles solve has concluded
- A skill or memory file has been edited
- Mark requests a session wrap

## Invariant

> `/checkpoint` must be the **last meaningful action** of the session. Any tool call after `/checkpoint` buries the anchor under `kind: tool_call` entries, making `/introspect` unreliable.

## Procedure

1. Confirm task state is stable and no in-flight writes are pending.
2. Run `/checkpoint` directly (type it as a slash command — do NOT invoke via `Skill(/checkpoint)`).
3. Stop. Do not execute Bash, Read, Grep, Write, or any other tool after this.

## Stop Condition

Checkpoint is written and no further tool calls are needed.

## Validation

- If any tool call was run after `/checkpoint`, write a **second `/checkpoint`** immediately to restore anchor correctness.
- The final journal entry should have `"kind": "anchor"` or equivalent checkpoint marker, not `"kind": "tool_call"`.

## Avoid

- Running Bash after `/checkpoint` (even `wc -l` or diagnostic probes)
- Using `Skill(/checkpoint)` — this only loads the skill file, does not invoke the command
- Reading files after checkpoint to "verify" state
- Running `/compact` before `/checkpoint` if meaningful work has not yet been anchored

## Allowed After Checkpoint

`/compact` or `/clear` only.
