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

For tweet-style markdownified YouTube transcripts, use the LLM markdown path
through Ollama Cloud (the free subscription):

```bash
OPENAI_BASE_URL=https://ollama.com/v1 \
OPENAI_API_KEY="$OLLAMA_API_KEY" \
summarize "$YOUTUBE_URL" \
  --extract \
  --format md \
  --markdown-mode llm \
  --model openai/<ollama-cloud-model> \
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
Use Ollama Cloud through summarize's OpenAI-compatible route, as above, and check the
current model list with `ollama list` or at ollama.com before picking one.

Never pass a `google/...` model or a Gemini API key: the Gemini API and every other
paid API are banned (Josh, 25 Oct 2026; `~/code/nix/nixos-config/ai/prompts/where-things-are.md`).
Gemini models served by Ollama Cloud (`openai/gemini-...:cloud`) are fine: that
subscription is free.

## Debugging

Use `--debug --metrics detailed` when the output is raw or empty. In debug output, confirm:

- `markdownMode=llm`
- `transcriptRequested=true`
- a real provider/model is selected
- the command is not using `--video-mode transcript` for markdown notes
