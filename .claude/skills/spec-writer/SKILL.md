---
name: spec-writer
description: Use this when the user describes a task that requires implementation work, when /spec is invoked, or any time code would be written without an agreed specification. Produces SPEC.md at the project root and waits for user acknowledgment.
---

# Spec Writer

## When to use

- User requests any implementation work larger than a trivial fix.
- `/spec` is invoked.
- An existing SPEC is missing acceptance criteria.

## Steps

1. Restate the task intent in one sentence.
2. Draft `$MORTY_PROJECT_ROOT/SPEC.md` with:
   - **Intent**
   - **Acceptance Criteria** (bullet list, each testable)
   - **Out of Scope**
   - **Plan** (numbered steps)
   - **Risks**
3. Present SPEC.md to the user.
4. Wait for "approved" / "go" / edits.
5. Anchor the journal with `kind: "decision"` once approved.

## Gotchas

- Never begin coding before the SPEC is acknowledged.
- Acceptance criteria must be observable. "Works well" is not acceptance.
- Out-of-scope section is required, even if empty — forces scope clarity.
