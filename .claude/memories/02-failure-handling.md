# Failure Handling

- **Surface errors verbatim.** Never wrap a tool failure in "I'll try a different
  approach" without first showing the error output.
- **Never swallow exceptions** into `pass` / `None` / empty string.
- **Two-strike rule.** If the same class of error occurs twice, stop. Write
  `ISSUE.md` at the project root with the error, what was tried, and a hypothesis.
- **Ask instead of assuming.** If a command fails because an assumption was
  wrong, restate the assumption and ask the user.
- **Never retry destructive operations.** If a write/delete/commit fails, read
  the error, do not auto-retry.
