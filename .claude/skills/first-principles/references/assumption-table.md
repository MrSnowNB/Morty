# Assumption Table Format

Use this exact structure during Phase 1.

| ID | Assumption | Type | Challenge | Five Whys root | Verdict | Notes |
|---|---|---|---|---|---|---|
| A-1 | We need a new queue | belief | Why is the current queue insufficient? What evidence proves that? | Backpressure is invisible because metrics are missing | research | Could be observability, not queue design |

## Field meanings

- `ID` — stable identifier such as `A-1`, `A-2`, ...
- `Assumption` — the claim being tested, written plainly.
- `Type` — one of `fact`, `belief`, `convention`, `hidden constraint`, or `unknown`.
- `Challenge` — the direct adversarial question or counter-hypothesis.
- `Five Whys root` — the compact root cause or root justification after asking why repeatedly.
- `Verdict` — one of `keep`, `revise`, `discard`, or `research`.
- `Notes` — what changed, what evidence is missing, or which sub-problem it maps to.

## Usage rules

- Complete the table for top-level assumptions before recursing.
- If an assumption survives challenge, keep it only in the weakest form supported by evidence.
- If an assumption is ungrounded but still operationally necessary, mark it `research` rather than pretending it is true.
- When multiple sub-problems depend on the same assumption, reference the same assumption ID rather than cloning rows.
- If a row changes verdict later, preserve the old row and append an updated note rather than erasing history.
