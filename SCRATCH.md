# FP Solve: internet-sourced news with AI mode — 2026-04-22

## Problem Statement

Redesign the google-news workflow:
1. **Phase 1:** Present only headlines (no agent summaries)
2. **Phase 2:** When user asks for clarification, use WebSearch (the only "AI mode" tool available) to gather real information
3. **Long-term:** Learn how to source truthful, trusted internet content

---

## Phase 1 — Assumption Challenge (updated per user feedback)

| # | Assumption | Type | Challenge | Verdict |
|---|-----------|------|-----------|---------|
| A1 | WebSearch can replace article fetching | belief | WebSearch returns indexed snippets, not full articles. But it returns URLs to actual sources. | **keep** |
| A2 | Agent-generated summaries are unreliable | belief | Model generates from training data, not real-time facts. For news this means hallucination. | **keep** |
| A3 | "AI mode" = WebSearch | revise | User asked for Perplexity/Gemini/Google AI Overviews. WebSearch is the only tool available. Must name this explicitly: WebSearch is the pragmatic substitute, not the ideal. | **revise** — WebSearch is the only option; name it |
| A4 | Two-phase workflow (headlines → search) | convention | User explicitly requested this. | **keep** |
| A5 | Trustworthiness is probabilistic | belief | No source is perfectly trustworthy. Corroboration count is the first real signal. Tier table is a belief, not a ground truth. | **keep** |

---

## Phase 2 — Ground Truths

- **GT-1:** WebSearch is the only internet search tool available in Claude Code. It returns indexed snippets with source URLs.
- **GT-2:** WebSearch has a 500-char query limit and returns up to 250 chars per snippet.
- **GT-3:** Agent-generated summaries from headlines are a known hallucination pattern.
- **GT-4:** Google News RSS provides clean headlines + source + timestamp but NO article content.
- **GT-5:** Google News proxy URLs (`news.google.com/rss/articles/CBMi…`) redirect back to Google — no programmatic resolution to real article URLs.
- **GT-6:** A skill's SKILL.md defines `description:`, `Steps:`, `Gotchas:`.
- **GT-7:** Google News RSS descriptions contain clustered related headlines from multiple outlets — corroboration count is naturally available.

---

## Phase 3 — Sub-problems

| ID | Sub-problem | Success | Failure | Approach |
|----|------------|---------|---------|----------|
| SP-1 | Output headlines only (no summaries) | Script outputs clean headline list | Output still contains summaries | Modify SKILL.md only (script is fine) |
| SP-2 | WebSearch on demand | User asks → agent searches → presents results | Search returns irrelevant results | Use headline as search query |
| SP-3 | Present results with attribution | Verbatim snippets, source names, no paraphrasing | Agent paraphrases without attribution | Always cite, show snippet verbatim |
| SP-4 | Corroboration count as trust signal | Agent counts distinct outlets per headline | Agent can't count reliably | Count from Google News description cluster |

---

## Phase 4 — Solved

### SP-1: Headlines-only output

**Approach:** Modify SKILL.md. Script already outputs clean JSON. Agent presents only: title, source, time, link. No summaries.

### SP-2: WebSearch on demand

**Approach:** When user asks for details on a headline, the agent uses WebSearch with the headline as the query. Returns real indexed content from actual sources.

### SP-3 + SP-4: Attribution + corroboration

**Approach:** Search results presented verbatim with source attribution. No paraphrasing. Corroboration count from Google News description cluster (how many distinct outlets ran the same headline). No pre-registered source tier table.

---

## Phase 5 — Error Handling

| Error | Cause | Mitigation |
|-------|-------|------------|
| WebSearch returns no results | Query too specific | Broaden query |
| WebSearch returns low-quality sources | Topic is fringe | Flag quality, note uncertainty |
| WebSearch timeout | Network issue | Surface error, retry once |

---

## Phase 6 — Final Design

**Workflow:**
```
1. User: "tell me the news"
   → Script: headlines only (title, source, time, link)
   → Agent: presents cleanly, no summaries

2. User: "tell me more about #2"
   → Agent: WebSearch(query = headline)
   → Agent: presents search results verbatim with attribution
   → Agent: discusses with user (dialogue, not monologue)
```

**Non-goal (explicit):** The agent does not generate summaries, paraphrases, or context for headlines. Phase 2 (on-demand search) is the only path to narrative content, and that content is presented verbatim with source attribution.

**Trust signals:**
- Corroboration count (from Google News cluster)
- Source names verbatim (no tiering — reputation is emergent)

---

## Phase 8 — Post-Mortem

**Problem:** Agent-generated news summaries are hallucination by proxy.

**Breakthrough:** Two-phase workflow with explicit non-goal. Headlines-only first, WebSearch on demand.

**Key insight from user:** Hard-coded source tiering is a belief, not a ground truth. Corroboration count is the first real trust signal — it's derived from data, not opinion.

**Pragmatic compromise:** WebSearch is not "AI mode" (Perplexity/Gemini), but it's the only internet tool available. Must name this assumption explicitly.
