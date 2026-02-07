# DJTBOT (Gateway on VPS + Mac node)

This doc is the entrypoint for “add X to the bot” / “fix Y on the bot”.

## TL;DR: where to change things

### Public behavior (no secrets, no PII)

Repo: `~/code/nix/ai-stack`

- **VPS gateway role module:** `ai-stack/modules/bots/djtbot-gateway.nix`
  - model defaults
  - gateway bind defaults (`tailnet`)
  - plugins list (non-secret wiring)
  - safe defaults (telegram disabled by default)

- **Mac node + local test module:** `ai-stack/modules/bots/djtbot-mac-node.nix`
  - installs OpenClaw.app
  - disables local prod gateway
  - keeps local `test` gateway (optional)

Flake entrypoints (import one of these in your private repo):

- `inputs.ai-stack.homeManagerModules.djtbot-gateway`
- `inputs.ai-stack.homeManagerModules.djtbot-mac-node`

### Private policy + secrets + PII

Repo: `~/code/nix/nixos-config`

- Telegram allowlists, group IDs, tokenFile paths
- `OPENCLAW_GATEWAY_TOKEN` secret (agenix)
- Tailscale auth keys (agenix)
- Host firewall rules / port exposure

Rule: **ai-stack never contains chat IDs, allowFrom lists, tokens, or keys.**

## Operational model (mental)

- **VPS** runs the canonical OpenClaw **Gateway** (Telegram lands here).
- **Mac** runs the OpenClaw **app in node-mode** and connects to the Gateway over Tailscale.
- Gateway routes execution:
  - Linux-capable tools run on VPS
  - macOS-only workflows execute on the Mac node (screen/canvas/system)

## Meals migration (runtime data)

`meals/` lives in the OpenClaw workspace (runtime data). Pragmatic mode:

- Source (old local): `~/.openclaw-prod/workspace/meals/`
- Target (VPS): `/home/djtbot/.openclaw-prod/workspace/meals/` (typical)

We do **not** Nix-manage this directory yet.

## Common tasks

### Add a new plugin / tool (public)

Edit: `ai-stack/modules/bots/djtbot-gateway.nix`

- add the plugin to `basePlugins`
- keep secret file paths as `/run/agenix/...` references only

### Enable Telegram (private)

In `nixos-config`, set:

- `programs.openclaw.instances.prod.config.channels.telegram.enabled = true;`
- `...tokenFile = "/run/agenix/<...>";`
- `...allowFrom = [ ... ];` (PII)
- `...groups = { ... };` (PII)

### Change model (public)

Edit: `ai-stack/modules/bots/djtbot-gateway.nix` → `agents.list[0].model` + `agents.defaults.models`.

## Smoke checks (minimal)

- VPS gateway reachable over tailnet (no public bind)
- Mac node paired (`openclaw nodes pending/approve/status` from the VPS)
- A mac-only action succeeds via node (screen snapshot / system.run)
