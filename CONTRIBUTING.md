# Contributing to Morty

## Before your first commit

Install the pre-commit hook once per clone:

```bash
git config core.hooksPath .githooks
```

This enables three local guardrails that match the CI checks:

| Rule | What it blocks |
|---|---|
| G1 | Hard-coded Windows paths (`C:/work/harness-sandbox`, `C:/Users/AMD`). Use `${CLAUDE_PROJECT_DIR}` instead. |
| G2 | Committing `logs/*.jsonl` (runtime journal) or `logs/_tmp_*.ps1` (ad-hoc scratchpads). |
| G3 | Tracking `.claude/settings.local.json` (per-clone local state). |

Bypass with `git commit --no-verify` if you have a genuine reason \u2014 but every G1/G2/G3 violation has historically corresponded to either a broken clone on another machine or months of commit noise, so please don't bypass routinely.

## CI

Every PR runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

- **PSScriptAnalyzer** across `.claude/hooks/*.ps1` and every `.claude/skills/*/scripts/*.ps1`. Errors fail the build; warnings print. This would have caught the B1 `.Reverse()` bug in PR #23.
- **Regression test**: `.claude/hooks/tests/test-post-tool-fallback.ps1` exercises the hook's task-boundary fallback.
- **Hygiene checks** mirror the pre-commit hook, so even a `--no-verify` push fails in CI.

## Before opening a PR

1. Read [`docs/ARCHITECTURE-CANONICAL.md`](docs/ARCHITECTURE-CANONICAL.md). Every change must align with it.
2. If you're adding a skill, follow the convention in [`.claude/skills/README.md`](.claude/skills/README.md): one `SKILL.md`, optional `scripts/` / `references/` / `templates/`.
3. If you change the journal schema or hooks, add a case to [`.claude/cases/`](.claude/cases/) and a validation run under [`docs/validation-runs/`](docs/validation-runs/).
4. Do not resurrect deprecated systems listed in `ARCHITECTURE-CANONICAL.md` \u00a76.
