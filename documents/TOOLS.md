# TOOLS.md

This file is managed by Nix. A plugin report is appended below.
Most CLIs support `--help` for quick usage.

## Clawdbot runtime controls (no sudo)

- `clawdbot-reload test` (default)
- `clawdbot-reload prod`
- `clawdbot-reload both`
- Gateway restart:
  - `launchctl kickstart -k "gui/$UID/com.steipete.clawdbot.gateway.prod"`
- UI restart:
  - `osascript -e 'tell application "Clawdbot" to quit'`
  - `open -a "@HOME@/Applications/Clawdbot.app"`

## Smaug (Twitter/X bookmarks)

- Run: `smaug-clawdbot run`
- Fetch only: `smaug-clawdbot fetch 20`
- Archive root: `@HOME@/code/knowledge/twitter-bookmarks`
- Workspace link: `@HOME@/.clawdbot/workspace/bookmarks/smaug`
- Credentials:
  - env: `AUTH_TOKEN` + `CT0`
  - or: `@HOME@/.clawdbot/credentials/smaug.env`
  - optional config: `@HOME@/code/knowledge/twitter-bookmarks/smaug.config.json` (do not commit)
- Requires `bird` in PATH (enable `programs.clawdbot.firstParty.bird` or install globally)
- Optional: `AUTO_INVOKE_CLAUDE=false`

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
