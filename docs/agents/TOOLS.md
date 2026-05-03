# Tools

All tools support `--help` for full usage. Prefer CLI over MCP where possible.

### Dev Environments
- **devenv.sh**: Per-project isolated environments. `devenv init` creates `devenv.nix` + `.envrc`.
  - Add `direnv allow` for auto-activation on cd. Commit `devenv.lock`.
  - Commands: `devenv shell`, `devenv up` (services), `devenv search <pkg>`. Never install globally.
  - On Josh's workstation, global `pip`, `pip3`, bare `uv`, `virtualenv`, and `python -m pip` / `python -m ensurepip` / `python -m venv` are blocked in normal shells, including versioned system aliases such as `python3.13 -m ...`.
  - Use `devenv shell` for real work. `uvx` stays available only for rare one-off commands; do not treat it as the default repo workflow.

### Documentation
- **Dash MCP**: Query local Dash docsets. `mcp__dash__search_documentation`, `mcp__dash__list_installed_docsets`.
  - Keep queries short for best hits (e.g., `LanguageModelSession` not full sentences).

### Printable Markdown (pandoc)
- HTML print: `pandoc --from gfm+hard_line_breaks --to html5 --standalone --embed-resources --lua-filter $HOME/code/nix/ai-stack/docs/agents/print-list-fix.lua --css $HOME/code/nix/ai-stack/docs/agents/print.css -o out.html in.md`

### Browser Automation
- **@Browser**: Built-in Codex Browser plugin for local browser automation, screenshots, and visual QA. Use it for localhost, file URLs, and iterative UI debugging.


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
- **@build-ios-apps** / **@build-macos-apps**: Built-in Codex app plugins for Apple platform build/test/run/debug/UI automation.
- **xcodebuildmcp** (CLI-first fallback): Apple platform build/test/run/debug/log/UI automation CLI. Prefer plugin skills when available, then use the CLI for direct shell workflows.
  - Quick checks: `xcodebuildmcp --version`, `xcodebuildmcp tools`, `xcodebuildmcp simulator list`.
- **axe**: Accessibility-based simulator automation. `axe tap`, `axe swipe`, `axe type`, `axe screenshot`. Uses Apple Accessibility APIs, no external server.

### Web Apps
- **@build-web-apps**: Built-in Codex web app plugin for frontend implementation, app-builder workflows, shadcn, Stripe, and Supabase guidance.

### Other
- **imagegen**: Built-in Codex skill/tool for image generation and editing. Prefer it over local image-edit CLIs.
- **mcporter**: MCP server wrapper for ad-hoc servers (Homebrew: `steipete/tap/mcporter`). `mcporter list`, `mcporter call namespace.tool`.
  - Config: `~/.mcporter-local/mcporter.json`. Set `MCPORTER_CONFIG` env when invoking. Avoid unless the user explicitly instructs.
- **Research repos**: Clone sources to `~/code/research/<topic>/src/<repo>`, examples to `/examples/`.
  - Before cloning: search tree to find correct bucket. Before "check the source": search tree first.
