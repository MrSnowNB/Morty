---
description: Perform a structured code review and write findings to REVIEW.md.
---
Review the user-specified path (default: current git diff).

Organize findings into:
- **Correctness** (bugs, logic errors)
- **Safety** (denylist matches, secret leaks, path traversal)
- **Clarity** (naming, structure, comments)
- **Tests** (coverage gaps, missing edge cases)
- **Style** (project conventions, dead code)

Each finding: file:line, severity (blocker/major/minor/nit), description, suggested fix.

Write to $MORTY_PROJECT_ROOT/REVIEW.md. Do not modify source files during review.
