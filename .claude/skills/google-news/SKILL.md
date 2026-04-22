# Google News Headlines

Use this when the user asks for the latest news headlines, wants to know what's in the news, or asks for a news summary.

## Steps

1. Run `pwsh -NoProfile -ExecutionPolicy Bypass -File .claude/skills/google-news/scripts/fetch-news.ps1 --json`.
2. Parse the JSON output. Each entry has `title`, `link`, `description` (source name), `source` (RSS source field), and `published`.
3. For each headline, write a 2-3 sentence summary paragraph based on the headline and source context. Be honest about what you know vs. what you're inferring.
4. Present the results as a numbered list with headline, source, time, summary paragraph, and link.
5. If the script fails, surface the error verbatim.

## Output Format

```
Top News Stories

1. [Headline]
   Source: [Source Name] | Time: [Published Date]
   [2-3 sentence summary]
   Link: [URL]

2. ...
```

## Gotchas

- Google News RSS has no authentication but is intended for personal, non-commercial use only.
- The RSS feed provides headlines and source names, not full article text. Paragraphs are agent-generated from the headline context.
- The feed may return fewer than 5 items if Google News is thin on content.
- Network timeouts can occur; the script includes a 15-second timeout.
- If Google changes the RSS format, the XML parser may fail — verify if results look wrong.
