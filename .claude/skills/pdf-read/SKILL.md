---
name: pdf-read
description: Use this when the user references a PDF file or URL ending in .pdf and asks Morty to summarize, extract, or answer questions about its contents. Extracts structured text locally with pypdf, falls back to OCR for image-based PDFs.
---

# PDF Read

## When to use

- File path or URL ends in `.pdf`.
- User asks to summarize, search, or extract from a PDF.

## Steps

1. Invoke `scripts/extract.ps1 -Path <pdf>`.
2. If extracted text is under 100 chars and page count is above 0, re-run with `-Ocr`.
3. Parse the returned Markdown and proceed with the user's request.

## Gotchas

- OCR requires `ocrmypdf` and Tesseract. If missing, report the gap.
- PDFs over 100 pages: chunk by page range to avoid context blowout.
- Always report page count and whether OCR was used.
