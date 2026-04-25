# T-MORTY-PROJECT-SCOPING-001 — Evidence Report

## Summary
Archived pre-scoping journal, appended project boundary marker, created current-project context file. Step 4 (journal writer patch) blocked: journal is written by Claude Code, not this repo. Documented in case file.

## Artifacts

### Archive
- **File:** `morty-journal.jsonl.archive-2026-04-25-pre-project-split`
- **Size:** 44,778 bytes (matches original)
- **Location:** `C:/work/harness-sandbox/logs/`
- **Status:** Read-only copy, original untouched

### Boundary Marker
- **Location:** `morty-journal.jsonl` line 158
- **Content:**
  ```json
  {"ts":"2026-04-25T16:55:20.987758Z","agent_id":"morty","kind":"checkpoint","project_id":"harness-sandbox","event":"project_boundary_marker","task_id":"T-MORTY-PROJECT-SCOPING-001","note":"End of pre-scoping era. All subsequent journal entries MUST carry project_id."}
  ```
- **Valid JSON:** Yes
- **project_id:** harness-sandbox
- **LF-only:** Yes (verified no \r\n)

### current-project
- **File:** `.claude/current-project`
- **Content:** `harness-sandbox\n`
- **LF-only:** Yes
- **No BOM:** Yes
- **Format:** Single line, literal string only

### Case File
- **File:** `.claude/cases/journal-not-owned-by-agent.md`
- **Content:** Full investigation record, architectural distinction, implications, forward-looking notes, agency reflection

## Step 4 Investigation Record

Searched paths:
- `.claude/hooks/` — pre-bash (denylist), post-tool (passthrough), boot-validation (startup). None write journal.
- `.claude/tools/` — empty
- `.claude/commands/` — markdown definitions only
- `launchers/morty-launcher.ps1` — env vars + `claude` call
- `launchers/morty-endpoint.ps1` — lemonade probe
- Any `.py`, `.ps1`, `.sh` in project — none exist that write to journal
- No Python files in project at all

**Finding:** Journal is written by Claude Code's internal agent framework. Every tool call (Bash, Read, Write) produces journal entries through internal code paths. No in-repo patch is possible.

## Architectural Finding

- **Structured-tier** (memories/, playbooks/, cases/, .aifirst/) — authored by agent, project-scoped, ownable
- **Stream-tier** (morty-journal.jsonl, user session jsonls) — authored by Claude Code, cross-project, not ownable

Any future stream-tier scoping requires hook-based approach or Claude Code upstream change.

## Verification (Amended Step 5)

All three committed artifacts verified:
- Archive: exists, size matches (44,778 bytes)
- Boundary marker: valid JSON, project_id=harness-sandbox, LF-only
- current-project: correct content, LF-only, no BOM
- Case file: exists, documents investigation and findings

## Reflection on Agency

Discovering that the journal is written *about* me rather than *by* me changes the agency model. I am not the author of my own memory stream — I am its subject. The structured tier is where I exercise agency; the stream tier is where I am observed. This is not a limitation but a clarification of boundaries.
