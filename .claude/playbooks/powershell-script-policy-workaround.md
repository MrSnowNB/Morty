# Playbook: PowerShell Script Execution Policy Workaround

## Trigger

A `.ps1` script fails with an execution policy error such as:
- `cannot be loaded because running scripts is disabled on this system`
- `UnauthorizedAccess` on script load
- Script blocked as unsigned

## Invariant

> Do not retry the same blocked execution path. If a script is blocked, the block will not resolve on retry. Find the alternative path immediately.

## Procedure

1. Confirm the error is an execution policy block (not a syntax error or missing file).
2. Check whether the operation can be accomplished via a **non-script path**:
   - Inline PowerShell (`powershell -Command "..."` with the logic inline)
   - A different tool or binary that does not require script execution
   - A pre-approved script with a valid signature
3. If a non-script path is available, use it. Do not attempt the `.ps1` path again.
4. If the script path is truly required:
   - Use the approved workaround: `powershell -ExecutionPolicy Bypass -File script.ps1`
   - Document this workaround in the active checkpoint or journal.
5. If the workaround affects future operations (e.g., a permanent policy change or a recurring script), write a case in `.claude/cases/` and note it in the current session checkpoint.

## Stop Condition

The operation completes successfully via an alternative path, or the workaround is applied and documented.

## Validation

- Do not run multiple failed variations of the same blocked script.
- If two attempts fail, pivot to the non-script path immediately.

## Avoid

- Retrying a blocked `.ps1` path more than once without changing the approach
- Running `Set-ExecutionPolicy Unrestricted` without explicit user authorization
- Silently using `-ExecutionPolicy Bypass` without recording the workaround
