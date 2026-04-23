---
schema_version: "aifirst/1.0"
task_id: "{{TASK_ID}}"
gate: G3
gate_name: "VALIDATE"
status: PENDING
agent: "{{AGENT}}"
timestamp_open: "{{NOW}}"
timestamp_close: null
parent_task_id: null
depends_on: ["{{TASK_ID}}/G2"]
tier_ceiling: T05
override_reason: null
---

## Validation Tier Results

<!-- Run tiers sequentially. Any FAIL halts further tiers and sets gate to BLOCKED.
     Do NOT use mocked, synthetic, or simulated data at any tier. -->

### T01 — Schema Validity
**Threshold:** 100% pass
**Test:** YAML front-matter parseable; all required fields present; status enum valid; override_reason rules enforced.

| file | yaml_valid | fields_complete | status_enum_valid | result |
|------|-----------|-----------------|-------------------|---------|
|      |           |                 |                   |        |

**T01 Result:** PENDING

---

### T02 — Structural Correctness
**Threshold:** 100% pass
**Test:** All scaffold files exist; no empty stub bodies; no placeholder text remaining (`{{TASK_ID}}`, `{{AGENT}}`, `{{NOW}}` all resolved).

| file | exists | no_empty_stubs | placeholders_resolved | result |
|------|--------|----------------|----------------------|---------|
|      |        |                |                      |        |

**T02 Result:** PENDING

---

### T03 — Functional Output
**Threshold:** ≥95% pass
**Test:** Task-specific functional correctness (e.g., COBOL→MD translation parseable; tool-router routes correct tool; introspect returns valid anchor).

| test_case_id | description | expected | actual | pass |
|-------------|-------------|----------|--------|------|
|             |             |          |        |      |

**T03 Score:** 0/0 (0%)
**T03 Result:** PENDING

---

### T04 — Semantic Accuracy
**Threshold:** ≥85% pass
**Test:** Human rubric or LLM-as-judge evaluation. Rubric defined per task in G0 Success Criteria.

| item_id | criterion | score_0_to_5 | notes |
|---------|-----------|--------------|-------|
|         |           |              |       |

**T04 Score:** 0/0 (0%)
**T04 Result:** PENDING

---

### T05 — Regression
**Threshold:** ≥ prior baseline (no regression)
**Test:** SWE-bench Lite/Verified, or prior task baseline, run with identical harness and submission tooling.

| benchmark | baseline_score | current_score | delta | pass |
|-----------|---------------|---------------|-------|------|
|           |               |               |       |      |

**T05 Result:** PENDING

---

## Gate Summary

| Tier | Threshold | Result  |
|------|-----------|----------|
| T01  | 100%      | PENDING |
| T02  | 100%      | PENDING |
| T03  | ≥95%      | PENDING |
| T04  | ≥85%      | PENDING |
| T05  | ≥baseline | PENDING |

**G3 Overall:** PENDING

---

**Gate pass condition:** All tiers up to `tier_ceiling` return `PASS`; no synthetic data used; `timestamp_close` set.
