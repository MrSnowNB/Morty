---
description: Research a question with a real browser, real sources, and real citations.
---
Invoke the `research-synth` skill for the user's question.

Drive Playwright MCP:
1. Open DuckDuckGo, search the goal.
2. Visit top 3 relevant results.
3. Extract main content via accessibility tree.
4. Synthesize a Markdown brief with inline [n] citations and a Sources table.
5. Offer to save to research/<slug>.md.

Headed browser by default. Respect robots.txt. Never cite unopened sources.
