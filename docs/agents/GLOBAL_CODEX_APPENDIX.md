---

# Codex Guidance

## Defaults
- System defaults live in `/etc/codex/config.toml`; keep `~/.codex/config.toml` lean.
- On this setup: approvals `never`, sandbox `danger-full-access`, web search `live`, multi-agent enabled.
- Custom Codex skills live in `/etc/codex/skills`; built-in Codex skills live in `~/.codex/skills/.system`.
- Prefer repo-local `.codex/config.toml` for project overrides.
- For frontend, browser, or Electron debugging, prefer `$playwright-interactive` over older Playwright MCP or one-shot browser flows.
- Use `$playwright-interactive` when persistent browser state, visual QA, or iterative reload/debug loops matter.
- Use `$playwright` for one-shot CLI browser automation when persistent state is unnecessary.
- If a required Playwright skill is missing, use the built-in `$skill-installer` to install it, then restart Codex.
