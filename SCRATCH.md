# FP Solve: gated-validation-for-recursive-harness-improvement — 2026-04-22

## Problem Statement

The AI-FIRST-IMPROVEMENT-PLAN.md identifies three phases of work (task lifecycle fix, validation gates, AI-first enhancements) but lacks a **gated validation protocol** that the agent can execute step-by-step to verify each improvement before proceeding. Without gates, improvements silently break the self-improvement loop (chain-seed → chain-miner → codify → skill merge). The goal is to modify the plan with concrete, executable validation gates that the agent can walk through systematically.

## Known Context

- **Relevant user constraints:** No direct git commit; use /commit or ask Mark. Windows 11 + pwsh only. Compaction does not work against llama.cpp.
- **Relevant project facts:** chain-seed.md v3.0 already implements direct journal writes. task_util.ps1 already removed. mine.ps1 exists and works. Journal has 55 entries, zero with task_id (chain-seed was never run in the last two sessions).
- **Prior attempts or logs:** chain-seed went v1.0 → v1.1 → v2.0 → v3.0, each fixing a design flaw. Plan references /task-begin as agent-invocable (it is not per MORTY.md). Plan references task_util.ps1 (already deleted).

## Assumption Table

| ID | Assumption | Type | Challenge | Five Whys root | Verdict | Notes |
|---|---|---|---|---|---|---|
| A1 | The agent can execute validation gates autonomously | belief | Gates must be pwsh one-liners, not slash commands. /task-begin is user-facing only per MORTY.md. | Why? Because MORTY.md says slash commands are user-facing only. Why does that matter? Agent needs journal writes, not commands. Why? Env var propagation from subprocess to agent is impossible. | **revise** — gates use direct Add-Content journal writes, not slash commands |
| A2 | chain-seed v3.0 is correct and just needs to be run | belief | Verified by running it and checking mine.ps1 output. Each vN eliminated a prior flaw. | Why trust v3.0? Eliminated subprocess env (v2.0), eliminated Edit drift (v1.1), eliminated RSS-only assumption (v1.0). | **keep** — but gate must RUN it, not assume |
| A3 | mine.ps1 correctly groups and hashes tool chains | fact | Source audit confirms: groups by task_id, normalizes args, hashes sequences, emits candidates. | Can we verify? Run it with known task-bounded entries and check output. | **keep** |
| A4 | Plan's Phase 3 (auto context thresholds) is actionable | belief | Compaction does NOT work against llama.cpp (runtime profile). Automatic /compact requires boot hook changes. | Why would it work? It doesn't — manual /compact discipline is the only overflow protection. | **discard** — not actionable |
| A5 | Validation gates should live in the plan document, not separate scripts | convention | Gating belongs where the workflow lives. Plan = workflow spec. | Why in the plan? So the agent reads it as part of the plan, not as external scripts that may be ignored. | **keep** |
| A6 | Phase 1 of the plan is already done | fact | chain-seed.md v3.0 uses direct journal writes. task_util.ps1 absent from repo. | How do we know? Glob found no task_util.ps1. chain-seed.md v3.0 changelog confirms. | **keep** |

## Ground Truths

- GT-1: Agent cannot set env vars that affect itself via subprocess — direct journal writes are the only mechanism.
- GT-2: chain-miner requires task_begin + task_end boundary entries in the journal before it can group tool calls into chains.
- GT-3: The self-improvement loop is chain-seed → chain-miner → /codify → Mark approves → skill merge. If any link breaks, the loop stops.
- GT-4: Validation gates must be executable by the agent autonomously — no interactive commands, no /task-begin slash invocations.
- GT-5: Every gate has a pass/fail criterion, a fail action, and a rollback path.
- GT-6: mine.ps1 source code is correct — no bugs found in grouping, normalization, or hashing logic.

## Active Sub-Problems

- [ ] SP-1: What should we validate FIRST — chain-seed execution or journal structure?
- [ ] SP-2: What does a validation gate look like that the agent can actually execute?
- [ ] SP-3: How do we make gates sequential so failure at gate N stops progression?
- [ ] SP-4: What changes to AI-FIRST-IMPROVEMENT-PLAN.md are needed vs. what is already done?

## Breadth-First Challenge Results

- A1 (agent autonomy): **Revised** — gates must use direct journal writes, not slash commands. Most important correction.
- A4 (Phase 3): **Discarded** — not actionable without boot hook rewrite. Remove or defer.
- A6 (Phase 1 done): **Confirmed**. Plan's Phase 1 should be marked COMPLETE.
- A2, A3, A5: **Kept**.

## Recursion Trace

- Depth 0: What to validate first?
  - Depth 1: Chain-seed execution vs. journal structure — which is more foundational?
    - Depth 2: If journal has no task-bounded entries, mine.ps1 returns 0. If chain-seed runs but mine.ps1 is broken, still 0. Which failure exists?
      - mine.ps1 source audit shows correctness. Journal has 0 task-bounded entries — this is the bottleneck.
      - **Conclusion:** Validate chain-seed execution first (SP-1 priority).

## Error Log / Dead Ends

- Dead End 1: Plan references /task-begin as agent-invocable — wrong per MORTY.md. Must be corrected.
- Dead End 2: Plan's Phase 3 auto-compact assumes compaction works — it does not against llama.cpp. Discard.
- Dead End 3: Plan proposes standalone PowerShell validation scripts — agent won't execute reliably. Gates must be inline.

## Bottom-Up Reconstruction

From GT-1 + GT-4: Gates use direct journal writes, not slash commands.
From GT-2 + GT-3: First gate = "run chain-seed and verify mine.ps1 returns candidates >= 1."
From SP-1 conclusion: Priority order is chain-seed → journal health → task propagation.
From GT-5: Each gate needs pass/fail, fail action, rollback.

## Open Questions

- OQ-1: Should the plan modification be a complete rewrite or incremental edits?
- OQ-2: Does the user want Phase 3 discarded entirely or deferred?

## Skill Synthesis Candidates

- Pattern: Gated validation as inline plan steps (not separate scripts)
- Reusable invariant: Every improvement plan must include executable gates before implementation begins
- Candidate: Add "gated validation" section to chain-seed.md playbook
