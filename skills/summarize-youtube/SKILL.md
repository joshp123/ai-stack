---
name: summarize-youtube
description: High-quality YouTube transcription from audio using yt-dlp + whisper.cpp through the local summarize CLI. Use when captions are unavailable/untrusted or the user explicitly wants audio transcription. For summarize.sh markdownified YouTube transcripts, use the summarize skill instead.
---

# Summarize YouTube

## Overview
Produce best-quality summaries from YouTube videos by transcribing audio with yt-dlp + whisper.cpp and summarizing with Claude CLI. This avoids caption-track errors and keeps the workflow reproducible.

Do not use this skill for tweet-style markdownified YouTube transcripts from caption tracks. Use the `summarize` skill and run `summarize --extract --format md --markdown-mode llm ...` for that path.

## Quick Start
1. Run the script with the video URL:
   `scripts/summarize_youtube.sh "<youtube-url>"`
2. The summary is printed to stdout. Redirect to a file if needed:
   `scripts/summarize_youtube.sh "<url>" > /tmp/summary.md`

## Workflow
1. Confirm a whisper.cpp GGML model exists at:
   `~/.cache/whisper.cpp/ggml-medium.en.bin`
2. If missing, download it with:
   `nix shell nixpkgs#whisper-cpp --command whisper-cpp-download-ggml-model medium.en --output-dir ~/.cache/whisper.cpp`
3. Run `scripts/summarize_youtube.sh` to transcribe via yt-dlp + whisper.cpp and summarize with Claude.

## Options
- `--cli <provider>`: claude (default), codex, gemini
- `--length <preset>`: short|medium|long|xl|xxl (default: xxl)
- `--model <id>`: whisper.cpp model id (default: medium.en)
- `--timeout <duration>` and `--retries <count>`: pass through to summarize
- `--extract`: transcript only (no LLM summary)

## Script
`scripts/summarize_youtube.sh` is the canonical entry point. Prefer it over hand-crafted commands so the workflow stays consistent.
