# TOOLS.md

This file is managed by Nix. A plugin report is appended below.
Most CLIs support `--help` for quick usage.

## Openclaw runtime controls (no sudo)

- `openclaw-reload test` (default)
- `openclaw-reload prod`
- `openclaw-reload both`
- Gateway restart:
  - `launchctl kickstart -k "gui/$UID/com.steipete.openclaw.gateway.prod"`
- UI restart:
  - `osascript -e 'tell application "Openclaw" to quit'`
  - `open -a "@HOME@/Applications/Openclaw.app"`

## qmd (Local Search)

Use qmd to search LORE.md for random flavor during Trump bot conversations:

- Search lore: `qmd search "JD psychosis" --collection lore`
- Random bit: `qmd query "something funny about Elon" --collection lore`
- Get specific: `qmd get documents/LORE.md:50 -l 20`

Index the lore collection:
```bash
qmd collection add ~/code/nix/ai-stack/documents --name lore --mask "LORE.md"
qmd update
```

## Speech-to-Text (openai-whisper)

- Prefer `xuezh` for Chinese audio.
- Example:
  - `whisper audio.m4a --model medium --language en --output_format txt`

## Text-to-Speech (edge-tts)

- Example:
  - `edge-tts --voice zh-CN-XiaoxiaoNeural --text "hello" --write-media out.mp3`
- List voices:
  - `edge-tts --list-voices | rg zh-CN`
