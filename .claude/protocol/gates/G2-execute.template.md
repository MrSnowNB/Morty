---
schema_version: "aifirst/1.0"
task_id: "{{TASK_ID}}"
gate: G2
gate_name: "EXECUTE"
status: PENDING
agent: "{{AGENT}}"
timestamp_open: "{{NOW}}"
timestamp_close: null
parent_task_id: null
depends_on: ["{{TASK_ID}}/G1"]
override_reason: null
---

## Step Log

<!-- Each sub-step is appended here AND to run.log as a JSON-L event.
     step_id format: {{TASK_ID}}-S-NNN -->

| step_id              | description                    | status  | timestamp            | notes |
|----------------------|-------------------------------|---------|----------------------|-------|
| {{TASK_ID}}-S-001    |                               | PENDING |                      |       |
| {{TASK_ID}}-S-002    |                               | PENDING |                      |       |

## Error Log

<!-- Any errors encountered during execution.
     If ANY error is logged here, gate status = FAIL → BLOCKED immediately. -->

| step_id | error_type | message | action_taken |
|---------|-----------|---------|---------------|

## Drift Notes

<!-- Any deviation from G0 Scope or G1 File Manifest. Document here AND re-open G0 if scope changes. -->

## Completion Checklist

- [ ] All steps PASS
- [ ] Error log empty (or OVERRIDE with reason)
- [ ] run.log append-only integrity confirmed
- [ ] No scope drift (or G0 re-opened)

---

**Gate pass condition:** All steps `PASS`; error log empty (or `OVERRIDE` with reason documented); `timestamp_close` set.
