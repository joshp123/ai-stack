---
name: markdown-converter
description: Convert documents and files to useful Markdown using the installed markitdown and markit CLIs. Use when converting PDF, Word (.docx), PowerPoint (.pptx), Excel (.xlsx, .xls), HTML, CSV, JSON, XML, images, audio, ZIP archives, YouTube URLs, or EPubs to Markdown, when choosing between markit and markitdown for better extraction quality, when comparing PDF extraction results, or when OCR may be needed for scanned or image-heavy PDFs.
---

# Markdown Converter

Convert files to useful Markdown using the installed `markitdown` and `markit` CLIs.

## Route First

- Use `markitdown` first for `.docx`, `.pptx`, `.xlsx`, `.xls`, HTML, CSV, JSON, XML, images, audio, ZIP, YouTube, EPUB, and most non-PDF formats.
- Use `markitdown` first for email-like, letter-like, or mostly linear-prose PDFs.
- Use `markit -q` first for table-heavy, form-like, or multi-column PDFs where layout matters.
- Use `markitdown --use-plugins` for scanned or image-heavy PDFs only when the environment already has a working OpenAI-compatible vision client/model configured for MarkItDown OCR.
- Fall back to plain `markitdown` and say OCR is unavailable when that OCR configuration is missing.

## Retry Or Compare

- Do not run both tools by default.
- Run the other tool when the first output is high-value and suspect, or when the user explicitly asks to compare.
- Treat these as suspect: flattened tables, broken reading order, repeated headers or footers, near-empty output, clearly jumbled text, or giant `data:image` blocks.
- For DOCX, prefer `markitdown` when `markit` emits base64-heavy Markdown.

## Commands

```bash
# Default DOCX / non-PDF path
markitdown input.docx > output.md

# Default prose-PDF path
markitdown input.pdf > output.md

# Layout-sensitive PDF path
markit -q input.pdf > output.md

# OCR path, only when OCR is configured
markitdown --use-plugins input.pdf > output.md

# Compare both on a PDF, then keep the better result
markitdown input.pdf > /tmp/markitdown.md
markit -q input.pdf > /tmp/markit.md
```

## Output Rule

- Return the chosen Markdown, not two full outputs.
- If both tools were run, state which tool won and why in one short sentence.
