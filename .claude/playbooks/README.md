# Playbooks

This directory contains **executable operational procedures** for Morty.

## Cases vs Playbooks

| Type | Purpose | When to create |
|------|---------|----------------|
| **Case** (`.claude/cases/`) | Descriptive postmortem of a failure | After any non-trivial failure; documents what happened and why |
| **Playbook** (`.claude/playbooks/`) | Executable operational procedure | When a first-principles solve yields a **repeatable operational path** |

A case explains. A playbook instructs. If you find yourself writing a case with a "how to fix it" section that reads like steps, that section belongs in a playbook.

## Playbook Schema

Every playbook must include all six fields:

```
## Trigger
The condition that activates this playbook.

## Invariant
The rule that must remain true throughout. State this before acting.

## Procedure
Numbered minimal steps. No improvisation beyond these steps.

## Stop Condition
When to stop following this playbook.

## Validation
How to confirm the playbook succeeded.

## Avoid
Actions explicitly forbidden after or during this playbook.
```

## Rule

> If a first-principles solve yields a repeatable operational workflow, synthesize a playbook here. If the solve yields only a failure analysis without reusable steps, write a case instead.

## Index

- [checkpoint-session-end.md](./checkpoint-session-end.md) — Correct session-close checkpoint sequence
- [introspect-anchor-diagnosis.md](./introspect-anchor-diagnosis.md) — Diagnosing missing or incorrect `/introspect` anchors
- [context-overflow-recovery.md](./context-overflow-recovery.md) — Context window overflow recovery procedure
- [powershell-script-policy-workaround.md](./powershell-script-policy-workaround.md) — Handling execution policy blocks on `.ps1` scripts
