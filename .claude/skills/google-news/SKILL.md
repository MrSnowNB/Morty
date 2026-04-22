# Google News Headlines

Use this when the user asks for the latest news headlines, wants to know what's in the news, or asks for a news summary.

## Non-Goal (Critical Constraint)

The agent does **not** generate summaries, paraphrases, or context for headlines. Phase 2 (on-demand search) is the only path to narrative content, and that content is presented verbatim with source attribution. The temptation will come back — name it out when it does.

## Steps

### Phase 1 — Headlines

1. Run `pwsh -NoProfile -ExecutionPolicy Bypass -File .claude/skills/google-news/scripts/fetch-news.ps1 --json`.
2. Parse the JSON output. Each entry has `title`, `link`, `description` (source name), `source` (RSS source field), and `published`.
3. For each headline, count the number of distinct outlets in the Google News description cluster (corroboration signal).
4. Present the results as a numbered list with headline, source, time, corroboration count, and link.
5. If the script fails, surface the error verbatim.

### Phase 2 — On-Demand Search

1. When the user asks for clarification on a specific headline, run `WebSearch(query = headline)`.
2. Present search results verbatim with source attribution — no paraphrasing.
3. Discuss findings with the user (dialogue, not monologue).

## Output Format (Phase 1)

```
Top News Stories

1. [Headline]
   Source: [Source Name] | Time: [Published Date]
   Corroboration: [N] outlets running this story
   Link: [URL]

2. ...
```

## Output Format (Phase 2)

```
Web search results for "[headline]":

• [Snippet text — verbatim]
  Source: [Outlet Name] ([URL])

• ...
```

## Gotchas

- Google News RSS has no authentication but is intended for personal, non-commercial use only.
- The RSS feed provides headlines and source names, not full article text.
- Google News proxy URLs (`news.google.com/rss/articles/CBMi…`) redirect back to Google — they cannot be resolved to real article URLs programmatically. The link is a dead end.
- WebSearch is the only internet search tool available in Claude Code. It is not Perplexity, Gemini, or Google AI Overviews — it returns indexed snippets with source URLs. Name this limitation when using it.
- The feed may return fewer than 5 items if Google News is thin on content.
- Network timeouts can occur; the script includes a 15-second timeout.
- If Google changes the RSS format, the XML parser may fail — verify if results look wrong.
- Trust signal: corroboration count (how many distinct outlets ran the same headline) is the primary trust signal. Do not hard-code source tiering — reputation is emergent, not pre-registered.
