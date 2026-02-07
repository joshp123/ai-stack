# Openclaw wiring checklist (private repo)

Use this as a quick wiring guide when importing ai‑stack into a private repo.

Related entrypoint:
- `ai-stack/docs/agents/DJTBOT.md`

## Required (prod gateway)

### Gateway auth

- `OPENCLAW_GATEWAY_TOKEN` available in the **gateway service environment** (agenix recommended)
  - ai-stack public config references it as `"${OPENCLAW_GATEWAY_TOKEN}"`.

### Tailnet networking

- Tailscale up on the gateway host
- Firewall: allow gateway port (default 18789) **only** on `tailscale0`

### Telegram (if you enable it)

ai-stack disables Telegram by default. If you want Telegram on prod, set in private repo:

- `programs.openclaw.instances.prod.config.channels.telegram.enabled = true;`
- `programs.openclaw.instances.prod.config.channels.telegram.tokenFile = "/run/agenix/<token>";`
- `programs.openclaw.instances.prod.config.channels.telegram.allowFrom = [ ... ];` (PII)
- `programs.openclaw.instances.prod.config.channels.telegram.groups = { ... };` (PII)

### Provider credentials

Anthropic credentials (one of):
- `ANTHROPIC_API_KEY` in the gateway environment, or
- per-instance env file / injected env (depends on how you run the gateway)

### Plugin secret files (if those plugins are enabled)

- `/run/agenix/padel-auth`
- `/run/agenix/picnic-auth`

## Recommended

- Keep all allowlists / group IDs / chat IDs in the private repo.
- Local plugin overrides for fast dev:
  - add a `plugins` entry with `source = "path:/..."` (last wins on name)

## Optional

- Shared defaults under `programs.openclaw.config`, overridden per instance via
  `programs.openclaw.instances.<name>.config`.
