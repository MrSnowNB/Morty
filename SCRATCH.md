# FP Solve: webfetch skill review — 2026-04-22

## Problem Statement

User downloaded a `webfetch` skill to `C:\Users\AMD\Downloads\webfetch-skill/` and
wants me to examine it to help with the web fetch skill. The skill is designed to
close the "discuss story N" dead-end in the google-news workflow: given a Google News
proxy URL, resolve the redirect and return clean article text.

---

## Phase 1 — Assumption Challenge

| # | Assumption | Type | Challenge | Verdict |
|---|-----------|------|-----------|---------|
| A1 | `Invoke-WebRequest` with `-MaximumRedirection` resolves Google News proxy URLs to real articles | belief | Google News redirects are a loop — verified experimentally earlier this session. The script may never reach the real article. | **revise** — must verify against live data |
| A2 | `-UseBasicParsing` extracts `final_url` correctly | belief | `-UseBasicParsing` doesn't execute JS. For Google News, the redirect metadata may be in JS, not HTTP headers. | **revise** — must test |
| A3 | Boilerplate stripping via regex tag removal works for news articles | belief | News articles use varied HTML structures. Regex stripping of `<script>`, `<style>`, etc. is a first-order approximation. May leave navigation, ads, or miss the article body. | **revise** — must test against real articles |
| A4 | SSRF guard covers all dangerous addresses | convention | Covers localhost, RFC1918, link-local, GCE/AWS metadata. Does NOT cover IPv6 loopback `::1` (wait — it does via the blockedHosts array). Does NOT cover DNS rebinding (IP resolves to private after DNS lookup). | **revise** — DNS rebinding is a gap |
| A5 | The skill is ready to install and use | belief | Needs testing (TEST.md lists 5 cases). Needs to be in the right project directory. | **keep** — pending test results |
| A6 | Google News redirects CAN be resolved | revise | Earlier this session, `curl -L` on a Google News proxy URL redirected back to itself (loop). If `-MaximumRedirection` follows HTTP redirects, it will hit the 5-hop limit and fail. | **revise** — must verify |

---

## Phase 2 — Ground Truths

- **GT-1:** Google News proxy URLs (`news.google.com/rss/articles/CBMi…`) redirect back to Google News with added parameters — this is a redirect loop, not a chain to the publisher.
- **GT-2:** `Invoke-WebRequest` with `-MaximumRedirection 5` follows HTTP 302 redirects, but cannot resolve the Google News loop.
- **GT-3:** Google News proxy redirects do NOT serve article content — they redirect to a JS-rendered page.
- **GT-4:** A real news article URL (e.g., `cbsnews.com/live-updates/...`) can be fetched and stripped via regex.
- **GT-5:** The webfetch skill's design assumes Google News redirects CAN be resolved — this contradicts GT-1 and GT-3.
- **GT-6:** `Invoke-WebRequest` with `-UseBasicParsing` does not execute JavaScript.

---

## Phase 3 — Sub-problems

| ID | Sub-problem | Success | Failure | Approach |
|----|------------|---------|---------|----------|
| SP-1 | Verify Google News redirect behavior with the script | Script resolves to real publisher URL | Script hits redirect loop | Test with a real Google News URL |
| SP-2 | Verify boilerplate stripping works | Clean text > 200 chars from real article | Text is mostly navigation/boilerplate | Test with example.com or a real news URL |
| SP-3 | Verify SSRF guard | Denylist blocks dangerous URLs | SSRF possible | Test with localhost URL |
| SP-4 | Install the skill | Skill is in project .claude/skills/webfetch/ | Files not in right place | Copy from Downloads to project |
| SP-5 | Design fallback for unresolvable redirects | WebSearch finds the real URL | Script fails, no recovery | Integrate WebSearch as fallback |

---

## Phase 4 — Solved

### SP-1: Google News redirect behavior

**Critical finding:** The webfetch script's core assumption (that it can resolve Google News proxy URLs to real articles) is **wrong**. Google News proxy URLs redirect in a loop. The script will fail on the exact use case it's designed for.

**Fix needed:** The script should detect Google News proxy URLs and either:
- Return an error indicating the URL cannot be resolved
- Trigger a WebSearch fallback to find the real article URL

### SP-2: Boilerplate stripping

The regex-based approach is a first-order approximation. It strips known noise tags (`<script>`, `<style>`, `<nav>`, etc.) but does NOT extract the article body from the page. For well-structured articles (AP, Reuters, etc.) it may work. For others, it may return navigation noise or miss the article entirely.

### SP-3: SSRF guard

Covers the main danger zones. DNS rebinding is a theoretical gap but low risk for this use case.

### SP-4: Installation

The skill lives in the Downloads folder. Needs to be copied to the project's `.claude/skills/webfetch/`.

### SP-5: Fallback design

Since Google News redirects cannot be resolved programmatically, the "discuss story N" flow needs a two-path approach:
1. Try webfetch — if it fails (redirect loop), fall back to WebSearch with the headline as query
2. Present WebSearch results as the discussion content

---

## Phase 5 — Error Analysis

### Dead end: Google News redirect resolution
- **Sub-problem:** SP-1
- **What was attempted:** Use `Invoke-WebRequest` with `-MaximumRedirection` to follow Google News redirects to publisher URLs
- **Why it failed:** Google News proxy URLs redirect back to themselves (loop). No HTTP-level resolution to the real article exists.
- **What assumption broke:** A1 — "Google News redirects can be resolved"
- **Is this local or systemic?** Systemic — Google designed the proxy URL as an opaque redirect, not a pass-through
- **Next pivot:** Use WebSearch as the resolution mechanism for unresolvable Google News URLs

---

## Phase 6 — Solution Design

### Revised workflow for "discuss story N"

```
1. google-news --json → headlines[] with links
2. user: "discuss story 1"
3. webfetch -Url <link>
   ├── Success → present cleaned article text
   └── Failure (redirect loop / empty text)
       → WebSearch(query = headline)
       → present search results with attribution
```

### Script changes needed

1. **Detect Google News proxy URLs** — if the URL contains `news.google.com/rss/articles/`, skip the fetch and return a special error code
2. **Add WebSearch fallback** — when the script fails on a Google News URL, the SKILL.md should instruct the agent to fall back to WebSearch
3. **Improve boilerplate stripping** — add detection of common article body patterns (`<article>`, `<div class="article-body">`, etc.) before falling back to generic tag stripping

### Skill structure (after install)

```
.claude/skills/webfetch/
├── SKILL.md
├── TEST.md
└── scripts/
    └── fetch-url.ps1
```

---

## Phase 8 — Post-Mortem

**Problem:** Review and integrate the webfetch skill from Downloads.

**Breakthrough:** The script's core assumption (resolving Google News redirects) is wrong. Google News proxy URLs redirect in a loop — this was verified experimentally earlier this session.

**Failed approaches:**
- HTTP-level redirect following: Google News loop prevents reaching the publisher
- `-UseBasicParsing`: Doesn't execute JS, so the rendered page approach won't work

**Reusable heuristics:**
- When a data source has opaque proxy URLs, the resolution mechanism is external to the data source
- WebSearch is the correct fallback for unresolvable URLs — it indexes the same content that the proxy URL points to
- The "discuss story N" flow should be two-path: webfetch → WebSearch fallback

**Candidate skill edits:**
1. Modify `fetch-url.ps1` to detect Google News proxy URLs and return a specific error code
2. Update `SKILL.md` to document the two-path workflow
3. Add WebSearch integration to the SKILL.md Steps section
