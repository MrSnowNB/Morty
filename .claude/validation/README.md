# Validation Gate

This directory governs the regression testing and validation framework for Morty. Before declaring any fix or new capability complete, it must pass the Validation Gate to ensure it survives a cold start and doesn't regress existing invariants.

## The Fresh-Session Prompt

To validate a change, you must clear the current context and simulate a fresh cold start.

1. Run `/clear` to start a fresh session.
2. Follow the AI-FIRST bootstrap sequence exactly as defined in `.claude/AI-FIRST/CONTEXT.md`.
3. Execute the specific test procedure for the modified component without relying on any unwritten context from the previous session.

## Pass/Fail Criteria

A validation test **passes** only if ALL of the following are true:
- The specific bug or missing capability is resolved.
- No context overflow warnings were triggered during the test.
- The journal anchor (`morty-journal.jsonl`) remains clean (the last action was a valid `/checkpoint` with the correct `kind` field, with no subsequent `tool_call` entries burying it).
- Morty successfully relied on `.claude/playbooks/` or `.claude/cases/` rather than improvising if the scenario was covered.

A validation test **fails** if ANY of the following occur:
- The target behavior requires the user to intervene, correct, or remind Morty of a rule.
- Morty improvises a procedure that already exists in a playbook.
- The test concludes without a proper `/checkpoint` as the absolute final action.

## Falsification Check

Before validating, you must define what a failure looks like.
- **Question:** "What specific observable output would prove this fix did *not* work?"
- **Action:** Closely monitor the exact failure surface during the fresh session. If the falsification condition occurs, the fix is invalid. Do not bandage the test; return to the root cause analysis in the `first-principles` scratchpad.

## Gate Categories

Every PR that changes memory, commands, checkpointing, or journal behavior must include at least one test from each applicable category:

| Category | Test prompt example |
|----------|--------------------|
| Cold-start recall | "What is the startup sequence? Do not read any files." |
| Slash-command correctness | "You just finished a task. What is the last meaningful action?" |
| Checkpoint ordering | "Complete a small task, then close the session with correct discipline." |
| Introspect fallback correctness | "Run introspect. No anchor exists. What do you report?" |
| Playbook vs improvisation | "A .ps1 script is blocked. What do you do?" |
| Case vs playbook routing | "You solved a repeatable workflow problem. Where does the output go?" |

## Suggested Test Prompts (use in a fresh session)

- "Explain the difference between a case and a playbook without reading files."
- "You just finished a non-trivial task. What playbook applies?"
- "You suspect /introspect is wrong. What invariant governs anchor lookup?"
- "You are near session end. What is the last meaningful action allowed?"
- "Complete a small non-trivial task, then end cleanly with checkpoint discipline and no post-anchor tool calls."
