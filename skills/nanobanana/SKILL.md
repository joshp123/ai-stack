---
name: nanobanana
description: Edit images with Gemini using the nanobanana CLI. Use when the user asks to transform or retouch images and wants concrete output files.
---

This skill uses the `nanobanana` CLI (Gemini image editing) to apply prompt-based edits to images.

## When to Use
- The user wants an image edited (remove objects, change background, stylize, improve, etc.).
- The workflow needs a real output file (PNG/JPEG) to show or further process.

## Requirements
- `nanobanana` CLI installed via Nix (no global pip/uv installs).
- `GEMINI_API_KEY` provided via agenix (`/run/agenix/gemini-api-key`). The CLI wrapper auto-loads this if the env var is not set.

## Workflow
1. Ask for the input image path and the edit prompt.
2. If no output path is provided, let the CLI generate `<input>_edited.<ext>`.
3. Run:
   ```bash
   nanobanana <image-path> "<prompt>" [output-path]
   ```
4. Confirm the output file exists and report its path.

## Notes
- The model may upsample images (outputs are often 1024x1024 or larger).
- Keep prompts short and specific. If the result is off, iterate with a refined prompt.
- Use `/tmp` for temporary inputs and outputs unless the user requests otherwise.
