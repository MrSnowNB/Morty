---
name: research-synth
description: Use this when the user asks Morty to research a topic, answer a factual question requiring web sources, or summarize multiple pages. Drives a real Chromium browser via Playwright MCP to search, visit, extract, and cite — producing a Markdown brief with inline [n] citations and a sources table.
---

# Research Synth (Playwright-driven)

## When to use

- User asks "research X", invokes `/research`, or poses a factual question
  Morty cannot answer confidently from memory.

## Steps

1. Restate the question as a concrete research goal.
2. Via Playwright MCP: open DuckDuckGo, search the goal, read top 5 results.
3. For the top 3 relevant results: navigate, wait for load, extract via
   accessibility tree, pull main content. Skip obvious SEO/junk domains.
4. Synthesize a Markdown brief:
   - **Question**
   - **Answer** (2–5 paragraphs, inline `[n]` citations)
   - **Sources** table: `[n]` | title | URL | accessed
5. Present the brief. Offer to save to `research/<slug>.md`.

## Browser posture

- **Headed by default** so Mark can watch. Flip with `/browser headless`.
- **Ephemeral context** — fresh cookies every run unless told otherwise.
- **Respect robots.txt** — if blocked, report and skip, do not bypass.

## Gotchas

- Cookie/GDPR banners block extraction. Use accessibility tree, not raw HTML.
- Paywalls: do not attempt to circumvent. Skip and note in Sources.
- Dynamic SPAs need `wait_for_load_state("networkidle")` before extraction.
- Never cite a source you did not actually open and read.
- If fewer than 2 usable sources, stop and tell Mark the research failed.
