---

# Codex Guidance

## Defaults
- System defaults live in `/etc/codex/config.toml`; keep `~/.codex/config.toml` lean.
- On this setup: approvals `never`, sandbox `danger-full-access`, web search `live`, multi-agent enabled.
- Custom Codex skills live in `/etc/codex/skills`; built-in Codex skills live in `~/.codex/skills/.system`.
- Prefer repo-local `.codex/config.toml` for project overrides.
