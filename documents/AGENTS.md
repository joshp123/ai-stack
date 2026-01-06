# Clawdbot Agent Tools

Tools available to Clawdbot and agents working with the gateway. Most CLIs support `--help` for quick usage.

## Key repos & paths

- `@HOME@/code/nix/nixos-config` — system + Clawdbot config (Nix).
- `@HOME@/code/nix/nix-secrets` — agenix secrets (private).
- `@HOME@/code/clawdbot` — Clawdbot source.

## Restarting Clawdbot (app + gateway)

Use launchd for the gateway and standard macOS app controls for the UI.

- Re-render config + restart (no sudo):
  - `clawdbot-reload test` (default)
  - `clawdbot-reload prod`
  - `clawdbot-reload both`
- Restart gateway (preferred, no sudo):
  - `launchctl kickstart -k "gui/$UID/com.steipete.clawdbot.gateway.prod"`
- Restart Clawdbot.app (UI):
  - `osascript -e 'tell application "Clawdbot" to quit'`
  - `open -a "@HOME@/Applications/Clawdbot.app"`
- After a nix build/switch, home-manager activation also performs these restarts automatically if binaries changed.


## Smaug (Twitter/X bookmarks)

Archive bookmarks into a version-controlled folder and link it into the Clawdbot workspace.

- Command: `smaug-clawdbot run`
- Fetch only: `smaug-clawdbot fetch 20`
- Default archive root: `@HOME@/code/knowledge/twitter-bookmarks`
- Workspace link: `@HOME@/.clawdbot/workspace/bookmarks/smaug`

Credentials:
- Set `AUTH_TOKEN` + `CT0` in the environment, or create `@HOME@/.clawdbot/credentials/smaug.env`.
- You can also use `@HOME@/code/knowledge/twitter-bookmarks/smaug.config.json` (do not commit it).

Dependencies:
- `bird` CLI must be in PATH (enable via `programs.clawdbot.firstParty.bird.enable = true` or install globally).

Optional toggles:
- `AUTO_INVOKE_CLAUDE=false` to skip Claude processing.

## Speech-to-Text (openai-whisper)

Whisper CLI for txt/srt/vtt. Prefer `xuezh` for Chinese audio.

```bash
whisper audio.m4a --model medium --language en --output_format txt
```

## Text-to-Speech (edge-tts)

Microsoft Edge neural TTS via Python. No API key needed, outputs mp3 + optional srt subtitles.

### Best Mandarin Voices
- `zh-CN-XiaoxiaoNeural` (Female, natural)
- `zh-CN-YunxiNeural` (Male, natural)
- `zh-CN-XiaoyiNeural` (Female, soft)
- `zh-CN-YunyangNeural` (Male, news-anchor style)

### Usage Examples

Basic:
```bash
edge-tts --voice zh-CN-XiaoxiaoNeural --text "你好！今天我们来练习普通话。" --write-media out.mp3
```

With subtitles (good for flashcards/study):
```bash
edge-tts --voice zh-CN-YunxiNeural --text "这儿的花儿真漂亮。" --write-media out.mp3 --write-subtitles out.srt
```

Slower for learners (--rate adjusts speed):
```bash
edge-tts --voice zh-CN-XiaoxiaoNeural --rate=-20% --text "请放慢语速，把每个字说清楚。" --write-media slow.mp3
```

List all zh-CN voices:
```bash
edge-tts --list-voices | grep zh-CN
```

### Test Sentences (tone/pronunciation practice)

1. **Neutral narration**: 你好！今天我们来练习普通话。请放慢语速，把每个字说清楚。
2. **Tone drill (minimal pairs)**: 妈、麻、马、骂。我们再读一遍：妈、麻、马、骂。
3. **儿化音 (Beijing flavor)**: 这儿的花儿真漂亮。你在哪儿？我在这儿等你一会儿。

Tip: Generate each at normal speed + `--rate=-20%` for "study mode" versions.
