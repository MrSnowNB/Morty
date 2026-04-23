---
schema_version: "aifirst/1.0"
task_id: "{{TASK_ID}}"
gate: G0
gate_name: "PLAN"
status: PENDING
agent: "{{AGENT}}"
timestamp_open: "{{NOW}}"
timestamp_close: null
parent_task_id: null
depends_on: []
override_reason: null
---

## Objective

<!-- One clear sentence: what will be true when this task is done? -->

## Scope

<!-- Bullet list of what IS included -->

## Out of Scope

<!-- Bullet list of what is explicitly excluded -->

## Success Criteria

<!-- Measurable, testable conditions. Each item maps to a G3 validation tier. -->
- [ ] SC-01:
- [ ] SC-02:
- [ ] SC-03:

## Risk Flags

<!-- List anything that could block, corrupt, or cause unexpected side effects.
     If non-empty, human ACK is required before G1 opens. Leave empty [] if none. -->
risk_flags:
  - flag: ""
    mitigation: ""

## Inputs

<!-- Files, APIs, models, or data the task depends on. Include SHA or version where known. -->

## Outputs

<!-- Files, artifacts, or state changes the task will produce. -->

## Rollback Plan

<!-- How to undo if G2 or G3 fails. -->

---

**Gate pass condition:** All sections populated; `risk_flags` either empty or human-ACK'd; `timestamp_close` set.
