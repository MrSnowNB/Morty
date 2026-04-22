# FP Solve: internet-sourced news with AI mode — 2026-04-22

## Problem Statement

Redesign the google-news workflow:
1. **Phase 1:** Present only headlines (no agent-generated summaries)
2. **Phase 2:** When user asks for clarification on a headline, use WebSearch (AI mode) to gather real information
3. **Long-term:** Learn how to source truthful, trusted internet content

---

## Phase 1 — Assumption Challenge

| # | Assumption | Type | Challenge | Verdict |
|---|-----------|------|-----------|---------|
| A1 | WebSearch can replace article fetching | belief | WebSearch is a text-based index, not a browser. It returns snippets, not full articles. But it does return URLs to authoritative sources. | **keep** — better than agent hallucination |
| A2 | Agent-generated summaries are unreliable | belief | The model generates content based on training data, not real-time facts. For news, this means outdated or fabricated context. | **keep** — well-documented LLM limitation |
| A3 | "AI mode" = WebSearch in this context | belief | The user references "AI mode" — in Claude Code, this maps to WebSearch (real-time internet search). Not Playwright/browser. | **keep** — WebSearch is the internet tool available |
| A4 | We need a two-phase workflow (headlines → search) | convention | Could just always search. But that's slow and noisy. Headlines first, then drill down on demand. | **keep** — user explicitly requested this |
| A5 | Trustworthiness is solvable | belief | No single source is perfectly trustworthy. But we can build a heuristic: multiple sources, established outlets, transparent attribution. | **revise** — trustworthiness is probabilistic, not binary |

---

## Phase 2 — Ground Truths

- **GT-1:** WebSearch is a built-in Claude Code tool that queries the real internet and returns indexed snippets with source URLs.
- **GT-2:** WebSearch has a 500-character query limit and returns up to 250 chars per snippet.
- **GT-3:** The current `google-news` skill generates agent summaries from headlines — this is a known hallucination risk.
- **GT-4:** Google News RSS provides clean headlines + source + timestamp but NO article content.
- **GT-5:** A skill's SKILL.md defines `description:`, `Steps:`, `Gotchas:` for agent discovery.

---

## Phase 3 — Sub-problems

| ID | Sub-problem | Success | Failure | Approach |
|----|------------|---------|---------|----------|
| SP-1 | Simplify output to headlines only | Script outputs clean headline list | Output still contains summaries | Modify SKILL.md + script |
| SP-2 | Enable WebSearch on demand | User asks for clarification → agent searches | Search returns irrelevant results | Design search query pattern |
| SP-3 | Present search results credibly | User sees source, snippet, link | Agent paraphrases without attribution | Always cite source, show snippet verbatim |
| SP-4 | Build trustworthiness heuristics | Agent can distinguish quality sources | Agent treats all sources equally | Source tiering by outlet reputation |

---

## Phase 4 — Solving

### SP-1: Headlines-only output

**Approach:** Modify SKILL.md to stop generating summaries. Script outputs clean headline list. Agent presents only:
- Headline
- Source name
- Timestamp
- Link (for user to click)

No agent-generated content.

### SP-2: WebSearch on demand

**Approach:** When user asks for details on a headline, the agent uses WebSearch with the headline as the query. Returns real indexed content from actual sources.

### SP-3 + SP-4: Trustworthy presentation

**Approach:** Search results are presented verbatim with source attribution. No paraphrasing. Source tiering:
- Tier 1: Major wire services (AP, Reuters, AFP)
- Tier 2: Established national outlets
- Tier 3: Regional/local outlets
- Tier 4: Blogs, opinion, unverified

---

## Phase 5 — Error Handling

| Error | Cause | Mitigation |
|-------|-------|------------|
| WebSearch returns no results | Query too specific or new story | Broaden query, try alternative keywords |
| WebSearch returns low-quality sources | Topic is fringe or emerging | Flag source quality, note uncertainty |
| WebSearch timeout | Network issue | Surface error, try once more |

---

## Phase 6 — Solution Design

**Workflow:**
```
1. User: "tell me the news"
   → Script: headlines only (title, source, time, link)
   → Agent: presents cleanly, no summaries

2. User: "tell me more about #2"
   → Agent: WebSearch(query = headline + keywords)
   → Agent: presents search results with source attribution
   → Agent: discusses with user (dialogue, not monologue)
```

**Key principle:** Agent is a conductor, not an author. It surfaces real information, doesn't manufacture it.

---

## Phase 7 — Validation

- GT-1 → WebSearch returns real internet content (tested in previous sessions)
- GT-3 → Agent summaries are a known hallucination pattern (well-documented)
- GT-4 → RSS headlines are factual metadata (verified)

**What would falsify this:** WebSearch goes unavailable, or RSS feed disappears.

---

## Phase 8 — Self-Improvement

**Candidate skill: internet-news**
- General pattern: fetch headlines → search on demand → present with attribution
- Applies to any topic where real-time factual accuracy matters
- Trustworthiness heuristic: source tiering + multiple-source corroboration
