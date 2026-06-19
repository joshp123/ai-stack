---
name: summarize
description: Use summarize.sh to summarize or transcribe URLs, YouTube/videos, podcasts, articles, transcripts, PDFs, and local files. Use for markdownified YouTube transcripts with summarize --extract --format md --markdown-mode llm.
---

# Summarize

Use the `summarize` CLI from summarize.sh for URL, file, article, podcast, and YouTube work.

## When To Use

Use this skill when the user says:

- "use summarize.sh"
- "summarize this URL/article/video"
- "transcribe this YouTube/video"
- "get proper markdown from this YouTube video"
- "markdownify this transcript"

## Quick Start

```bash
summarize "https://example.com"
summarize "/path/to/file.pdf"
summarize "https://www.youtube.com/watch?v=..." --youtube auto
```

If `summarize` is not on PATH but Nix is available, use the packaged tool:

```bash
nix run github:openclaw/nix-openclaw-tools#summarize -- "https://example.com"
```

## YouTube Markdown Notes

For tweet-style markdownified YouTube transcripts, use the LLM markdown path:

```bash
summarize "$YOUTUBE_URL" \
  --extract \
  --format md \
  --markdown-mode llm \
  --model google/gemini-3.5-flash \
  --plain \
  --timeout 10m
```

Do not add `--video-mode transcript` for this path. That forces raw transcript extraction and can skip markdownification.

## Raw Transcript

For a raw transcript, use:

```bash
summarize "$YOUTUBE_URL" --youtube auto --extract --plain
```

Add `--timestamps` when timestamps matter.

## Models

Prefer an explicit current model. Do not trust `auto` if debug output shows a stale model.
Google direct model IDs and Ollama Cloud model IDs are different surfaces; verify the
Ollama Cloud model name when the user asks for Ollama.

- Google direct: `--model google/gemini-3.5-flash`
- Ollama Cloud through summarize's OpenAI-compatible route:

```bash
OPENAI_BASE_URL=https://ollama.com/v1 \
OPENAI_API_KEY="$OLLAMA_API_KEY" \
summarize "$YOUTUBE_URL" \
  --extract \
  --format md \
  --markdown-mode llm \
  --model openai/gemini-3-flash-preview:cloud \
  --plain \
  --timeout 10m
```

As of 2026-06-02, Ollama Cloud exposes `gemini-3-flash-preview:cloud`; Google direct exposes `gemini-3.5-flash`.

## Debugging

Use `--debug --metrics detailed` when the output is raw or empty. In debug output, confirm:

- `markdownMode=llm`
- `transcriptRequested=true`
- a real provider/model is selected
- the command is not using `--video-mode transcript` for markdown notes
