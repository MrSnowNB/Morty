# FP Solve: google-news tool — 2026-04-22

## Problem Statement

Build a tool (skill) that retrieves the **top 5 news story headlines and first paragraphs** from Google News. Output should be clean, machine-readable or human-readable, and invocable via the skill system.

---

## Phase 1 — Assumption Challenge

| # | Assumption | Type | Challenge | Verdict |
|---|-----------|------|-----------|---------|
| A1 | Google News has a free, no-auth data feed | belief | Google shut down the old Google News API in 2020, but RSS feeds at `news.google.com/rss` still exist and are widely used. | **keep** |
| A2 | We need to scrape the website | belief | The website requires JS rendering (Playwright). Fragile, slow, against ToS. RSS is the intended machine-readable surface. | **discard** |
| A3 | A third-party API is needed | convention | Paid APIs exist (NewsAPI, GNews, etc.) but add cost, API keys, and external dependencies. RSS is free and built-in. | **discard** |
| A4 | "First paragraph" = RSS description | belief | RSS `<description>` is a snippet (often 2-3 sentences), not the full first paragraph. Getting the true first paragraph requires fetching the article URL, adding latency and failure surface. | **revise** — use RSS description as the paragraph; document the limitation |
| A5 | PowerShell is the right scripting language | convention | User runs Windows/PowerShell. PowerShell can parse XML natively. No external deps needed. | **keep** |

---

## Phase 2 — Ground Truths

- **GT-1:** Google News RSS feeds are available at `https://news.google.com/rss` with no authentication required.
- **GT-2:** RSS feeds return standard XML with `<title>`, `<link>`, `<description>`, `<pubDate>`, and `<source>` elements per item.
- **GT-3:** The top stories feed URL is `https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en`.
- **GT-4:** PowerShell has `Invoke-RestMethod` (built-in cmdlet) that auto-parses XML into structured objects.
- **GT-5:** A skill in this project lives in `.claude/skills/<name>/` with `SKILL.md` containing `description:`, `Steps:`, and `Gotchas:`.

---

## Phase 3 — Sub-problems

| ID | Sub-problem | Success | Failure | Approach |
|----|------------|---------|---------|----------|
| SP-1 | Fetch Google News RSS feed | Get valid XML response | Network error, feed changed | Direct fetch |
| SP-2 | Parse XML into structured items | Extract title, link, description, source, date | Invalid XML, changed schema | PowerShell `Invoke-RestMethod` |
| SP-3 | Limit to top 5 | Exactly 5 items returned | Feed has fewer than 5 | Select-Object -First 5 |
| SP-4 | Format output cleanly | Readable text or JSON | Messy formatting | PowerShell formatting |
| SP-5 | Package as a skill | Invocable via Skill tool | Not discoverable | SKILL.md + script |

---

## Phase 4 — Solved (with adjustments)

### SP-1 + SP-2 + SP-3: Fetch, parse, limit

Used `Invoke-RestMethod` to fetch RSS XML. It auto-parses into PowerShell objects.
Key discovery: `Invoke-RestMethod` returns a **flat array** of items, NOT wrapped in `.rss.channel.item` as expected from standard RSS. This was a schema divergence from textbook RSS.

### SP-4: Format output

Two modes:
1. **Text mode (default):** Delimited lines between `TOP_STORY_START`/`TOP_STORY_END` markers for easy parsing
2. **Machine-readable** (`--json` flag): JSON array

### SP-5: Package as a skill

Created `.claude/skills/google-news/` with `SKILL.md` and `scripts/fetch-news.ps1`.

---

## Phase 5 — Error Handling (updated)

| Error | Cause | Mitigation |
|-------|-------|------------|
| RSS feed returns empty or malformed | Google changed format | Surface error verbatim |
| Network timeout | Connectivity issue | 15s timeout on fetch |
| Fewer than 5 items | Feed is thin | Return what's available |
| Article paragraph extraction fails | Google News proxy URLs redirect to JS-rendered pages | Agent generates summary from headline context |

---

## Phase 6 — Final Solution Design

**Tool: `google-news`**

```
.claude/skills/google-news/
├── SKILL.md
└── scripts/
    └── fetch-news.ps1
```

**Workflow:**
1. Script fetches RSS and returns JSON with title, link, source, published
2. Agent generates 2-3 sentence summary from headline context
3. Agent presents formatted output

**Key design decisions:**
- RSS provides headlines + source names, NOT full article text (Google News proxy URLs serve JS-rendered pages)
- Agent-generated summaries are the practical compromise: fast, no browser needed
- JSON output mode for machine parsing; delimited text mode for human reading

---

## Phase 7 — Validation

- GT-1 → RSS feed is accessible (tested successfully, 38 items returned)
- GT-4 → `Invoke-RestMethod` is built-in PowerShell (always available)
- GT-5 → Skill packaging follows existing project convention
- Tested end-to-end: script produces valid JSON with 5 clean entries

**What would falsify this:** Google News RSS feed goes away or requires auth.

---

## Phase 8 — Post-Mortem

**Problem:** Build a tool to get top 5 news headlines and first paragraphs from Google News.

**Breakthrough:** Google News RSS is free, no-auth, and well-structured — but it does NOT include article content. The proxy URLs redirect to JS-rendered pages. The practical solution: RSS for headlines + agent-generated summaries.

**Failed approaches:**
- Direct article fetching via HTTP: Google News proxy URLs don't serve article HTML, they redirect to JS-rendered pages
- Playwright-based fetching: would work but takes 30-60s per article, fragile

**Reusable heuristics:**
- RSS feeds from major services are reliable when available; don't over-engineer around their limitations
- When the "obvious" data source (RSS) doesn't provide the desired field, find the pragmatic substitute rather than fighting the system
- Agent-generated content is a valid substitute when the data source is constrained

**Candidate skill improvement:** Generalize to arbitrary RSS feeds by accepting a feed URL parameter.
