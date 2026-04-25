---
schema_version: "aifirst/1.0"
task_id: "{{TASK_ID}}"
gate: G4
gate_name: "COMMIT"
status: PENDING
agent: "{{AGENT}}"
timestamp_open: "{{NOW}}"
timestamp_close: null
parent_task_id: null
depends_on: ["{{TASK_ID}}/G3"]
override_reason: null
---

## Pre-Commit Verification

- [ ] All five gates (G0–G3) status = PASS
- [ ] run.log integrity verified (no overwritten lines)
- [ ] Branch is `feat/{{TASK_ID}}`
- [ ] No uncommitted changes outside the task scope

## Post-Mortem

### What was planned (G0) vs. what was built (G2)
<!-- Describe any drift. "No drift" is a valid and good answer. -->

### Metrics Delta
<!-- Compare G3 results to G0 Success Criteria -->

| success_criterion | target | achieved | delta |
|-------------------|--------|----------|-------|
| SC-01             |        |          |       |
| SC-02             |        |          |       |
| SC-03             |        |          |       |

### Lessons Learned
<!-- What would you change in G0 next time? Any surprises? -->

### Open Issues
<!-- Anything NOT resolved that should become a new /aifirst task -->
- [ ]

## PR

- **Title:** `[AIFIRST-VERIFIED] {{task_name}} ({{TASK_ID}})`
- **Branch:** `feat/{{TASK_ID}}` → `main`
- **Linked run:** `.claude/runs/{{TASK_ID}}/`
- **Validation summary:** T01✅ T02✅ T03✅ T04✅ T05✅

---

**Gate pass condition:** Pre-commit checklist complete; post-mortem all sections populated; PR opened with `[AIFIRST-VERIFIED]` tag; `timestamp_close` set.
