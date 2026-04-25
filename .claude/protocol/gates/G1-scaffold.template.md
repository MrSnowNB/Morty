---
schema_version: "aifirst/1.0"
task_id: "{{TASK_ID}}"
gate: G1
gate_name: "SCAFFOLD"
status: PENDING
agent: "{{AGENT}}"
timestamp_open: "{{NOW}}"
timestamp_close: null
parent_task_id: null
depends_on: ["{{TASK_ID}}/G0"]
override_reason: null
---

## File Manifest

<!-- Every file that will be created, modified, or deleted.
     Record current SHA for all modified/deleted files (for rollback).
     New files: sha = null -->

| Action   | Path                          | Current SHA  | Notes           |
|----------|-------------------------------|--------------|------------------|
| CREATE   | path/to/new-file.md           | null         |                 |
| MODIFY   | path/to/existing-file.md      | abc1234      |                 |
| DELETE   | path/to/old-file.md           | def5678      | confirm backup  |

## Branch

<!-- Feature branch to be used for this task -->
branch: "feat/{{TASK_ID}}"

## Stub Verification

<!-- After scaffold commit, confirm each file exists with correct structure -->
- [ ] All CREATE files exist with correct YAML headers
- [ ] All MODIFY files backed up to rollback branch
- [ ] Scaffold commit pushed to branch

## Dry-Run Notes

<!-- Anything observed during scaffolding that changes the G0 plan -->

---

**Gate pass condition:** All files in manifest exist; stub verification checklist complete; no implementation code yet committed; `timestamp_close` set.
