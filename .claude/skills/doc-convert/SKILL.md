---
name: doc-convert
description: Use this when the user needs to convert a document between formats — .docx, .md, .html, .pdf, .rst, .epub. Wraps Pandoc with safe defaults and refuses to overwrite the source file.
---

# Doc Convert

## Steps

1. Identify input format from file extension.
2. Identify output format from user request.
3. Invoke `scripts/pandoc.ps1 -In <path> -Out <path>`.
4. Report the output path and file size.

## Gotchas

- PDF output requires a TeX engine (MiKTeX). If missing, report clearly.
- DOCX to MD conversion loses some formatting fidelity; warn the user.
- Always write output to a new path; never overwrite the input.
