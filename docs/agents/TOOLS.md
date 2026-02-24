# Tools

## Tools

All tools support `--help` for full usage. Prefer CLI over MCP where possible.

### Dev Environments
- **devenv.sh**: Per-project isolated environments. `devenv init` creates `devenv.nix` + `.envrc`.
  - Add `direnv allow` for auto-activation on cd. Commit `devenv.lock`.
  - Commands: `devenv shell`, `devenv up` (services), `devenv search <pkg>`. Never install globally.

### Documentation
- **Dash MCP**: Query local Dash docsets. `mcp__dash__search_documentation`, `mcp__dash__list_installed_docsets`.
  - Keep queries short for best hits (e.g., `LanguageModelSession` not full sentences).

### Printable Markdown (pandoc)
- HTML print: `pandoc --from gfm+hard_line_breaks --to html5 --standalone --embed-resources --lua-filter $HOME/code/nix/ai-stack/docs/agents/print-list-fix.lua --css $HOME/code/nix/ai-stack/docs/agents/print.css -o out.html in.md`

### Steipete Tap Tools
- **codexbar**: Codex/Claude usage menu bar monitor (cask).
- **peekaboo**: macOS screenshots + AI vision CLI.
- **gogcli**: Google Suite CLI (Gmail, Calendar, Drive).
- **camsnap**: RTSP/ONVIF camera capture CLI.
- **bird**: Twitter/X CLI.
- **mcporter**: MCP runtime/CLI wrapper (Homebrew; see “Other” for usage).
- **poltergeist**: Screenshots + OCR/vision helpers.
- **sag**: Screenshot/annotation CLI.
- **sonoscli**: Sonos speaker control CLI.
- **wacli**: WhatsApp CLI built on whatsmeow.
- **summarize**: URL → clean text → summary.
- **tmuxwatch**: Tmux session monitor.

### Browser Automation
- **dev-browser** (preferred): Long-lived daemon owns browser. Safe to retry/kill without losing state.
  - **CLI, not MCP**: invoke directly as a shell command (`dev-browser ...`). Do not look for it in MCP tool lists.
  - Workflow: `goto <url>` → `snapshot` → `click-ref eN` / `fill-ref eN "text"`.
  - For shadow DOM/iframes: `snapshot --engine aria`. For batching: `dev-browser actions` (JSON).
  - **UI verification pass (dev tasks only)**: After any dev-browser interaction that changes UI state, take a screenshot and do a quick visual QA:
    - Capture: `dev-browser screenshot --full-page` (or `--annotate-refs` if it helps).
    - Describe what you see (layout, hierarchy, visible text, key controls, states).
    - Assess: what’s good, what’s weak/risky (contrast, affordance, density, hierarchy), and whether it matches the user’s intent.
    - If mismatch, propose concrete fixes or next actions.
  - Skip the UI verification pass for non-UI automation (e.g., login flows, third-party sites) unless the user explicitly asks.


### Code Quality
- **ubs**: Fast bug scanner for agents. Run on changed files before commits.
  - `ubs $(git diff --name-only)`. Exit 0 = safe, >0 = fix & re-run.
  - First run: `ubs doctor` to initialize.

### Git
- **zagi**: Git-compatible CLI with compact output + guardrails; `git` is aliased to zagi and agent launchers set `ZAGI_AGENT` so commits require `--prompt` and destructive ops (reset --hard/clean -f/restore ./push -f/stash clear/branch -D) are blocked.

### Search
- **cass**: Cross-agent conversation search. Indexes Codex, Claude, Cursor sessions.
  - Always `--robot` or `--json`, never bare TUI. Filter: `--workspace "$PWD"`, `--days N`, `--agent`.
- **cm**: Robot-friendly cass wrapper. `cm search "query"` adds `--robot` automatically.

### Text-to-Speech
- **edge-tts**: Microsoft Edge neural TTS. No API key. See Openclaw `TOOLS.md` in the active workspace
  (e.g. `${OPENCLAW_STATE_DIR:-~/.openclaw}/workspace/TOOLS.md` or `~/.openclaw-<instance>/workspace/TOOLS.md`).

### iOS Simulator
- **xcodebuildmcp** (CLI-first): Apple platform build/test/run/debug/log/UI automation CLI. Prefer `xcodebuildmcp` over raw `xcodebuild`/`simctl` when available.
  - Quick checks: `xcodebuildmcp --version`, `xcodebuildmcp tools`, `xcodebuildmcp simulator list`.
- **axe**: Accessibility-based simulator automation. `axe tap`, `axe swipe`, `axe type`, `axe screenshot`. Uses Apple Accessibility APIs, no external server.

### Other
- **nanobanana**: Gemini image edit CLI. `nanobanana <image> "<prompt>" [out]` (uses `GEMINI_API_KEY` from `/run/agenix/gemini-api-key`).
- **mcporter**: MCP server wrapper for ad-hoc servers (Homebrew: `steipete/tap/mcporter`). `mcporter list`, `mcporter call namespace.tool`.
  - Config: `~/.mcporter-local/mcporter.json`. Set `MCPORTER_CONFIG` env when invoking. Avoid unless the user explicitly instructs.
- **Research repos**: Clone sources to `~/code/research/<topic>/src/<repo>`, examples to `/examples/`.
  - Before cloning: search tree to find correct bucket. Before "check the source": search tree first.
