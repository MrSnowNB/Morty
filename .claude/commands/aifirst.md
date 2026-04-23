---
schema_version: "aifirst/1.0"
command: "/aifirst"
version: "1.0.0"
description: >
  Invoke the AiFirst gated validation protocol for a task.
  Creates a runs/<task_id>/ directory and opens G0-plan.md
  for population before any execution begins.
parameters:
  - name: task_name
    required: true
    type: string
    description: "Short human-readable label for the task"
  - name: tier_ceiling
    required: false
    default: T05
    type: "enum[T01,T02,T03,T04,T05]"
    description: "Highest validation tier to run in G3"
  - name: skip_human_ack
    required: false
    default: false
    type: boolean
    description: "Only valid when G0 risk_flags is empty"
behavior:
  on_invoke:
    - "Generate task_id using format T-YYYY-MM-DD-NNN"
    - "Create runs/<task_id>/ directory"
    - "Copy gate templates into runs/<task_id>/"
    - "Populate G0-plan.md YAML header and body"
    - "If risk_flags non-empty AND skip_human_ack=false: pause, surface to user, await ACK"
    - "On ACK: open G1"
  on_gate_fail:
    - "Write BLOCKED entry to run.log"
    - "Set gate status to FAIL"
    - "Surface error and blocked gate to user"
    - "Halt — do not proceed to next gate"
    - "Do not self-correct without re-entering G0"
  on_complete:
    - "Verify all five gates status = PASS"
    - "Write final POST-MORTEM block to G4-commit.md"
    - "Tag PR title with [AIFIRST-VERIFIED]"
    - "Append completion event to run.log"
---

## Usage

```
/aifirst task_name="COBOL-to-MD batch 01" tier_ceiling=T04
/aifirst task_name="NemoClaw tool-router refactor"
/aifirst task_name="Hotfix: introspect anchor bug" skip_human_ack=true
```

## Gate Flow

```
PLAN → SCAFFOLD → EXECUTE → VALIDATE → COMMIT
 G0       G1         G2         G3        G4
```

Each gate writes a `.md` file with a YAML header inside `runs/<task_id>/`.
The agent populates it. If the gate passes, status flips to `PASS` and the next gate opens.
If it fails, status flips to `FAIL` → `BLOCKED` and the run halts.

## Rules

- No gate can be skipped
- No simulated or synthetic data at any validation tier
- `run.log` is append-only JSON-L — never overwrite
- Human ACK required if `risk_flags` is non-empty in G0
- Agent does not self-correct on failure without re-entering G0
- PR title must include `[AIFIRST-VERIFIED]` only when all five gates = PASS
