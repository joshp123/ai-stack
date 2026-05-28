# DJTBOT / OpenClaw Transitional Profiles

This doc covers the public DJTBOT/OpenClaw profiles that are still imported by
the private repo. It is not the source of truth for live host topology.

## TL;DR: where to change things

### Public behavior (no secrets, no PII)

Repo: `~/code/nix/ai-stack`

- **Gateway role profile:** `ai-stack/modules/bots/djtbot-gateway.nix`
  - model defaults
  - gateway bind defaults (`tailnet`)
  - plugins list (non-secret wiring)
  - safe defaults (telegram disabled by default)

- **macOS node + local test profile:** `ai-stack/modules/bots/djtbot-mac-node.nix`
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
- Which host is the current gateway

Rule: **ai-stack never contains chat IDs, allowFrom lists, tokens, or keys.**

## Transitional deployed model

Private consumers may still have a legacy gateway role and a macOS node role
during cutover. Check `nixos-config` and live host state before assuming which
host is active.

Do not treat this as target architecture. New reusable lifecycle behavior
belongs in `nix-openclaw`; active gateway ownership belongs in `nixos-config`
until proven and decommissioned cleanly.

## Meals migration (runtime data)

`meals/` lives in the OpenClaw workspace (runtime data). Pragmatic mode:

- Source (old local): `~/.openclaw-prod/workspace/meals/`
- Target: the active gateway host path in the private repo.

We do **not** Nix-manage this directory yet.

## Common tasks

### Add a new plugin / tool

Do not start here by default.

- Packaged/reusable OpenClaw plugin tools belong in `nix-openclaw-tools` or
  `nix-openclaw`.
- Private enablement, env files, and secret paths belong in `nixos-config`.
- Add to `ai-stack/modules/bots/djtbot-gateway.nix` only for public no-secret
  profile defaults that remain useful after the host topology changes.

### Enable Telegram (private)

In `nixos-config`, set:

- `programs.openclaw.instances.prod.config.channels.telegram.enabled = true;`
- `...tokenFile = "/run/agenix/<...>";`
- `...allowFrom = [ ... ];` (PII)
- `...groups = { ... };` (PII)

### Change model (public)

Edit: `ai-stack/modules/bots/djtbot-gateway.nix` → `agents.list[0].model` + `agents.defaults.models`.

## Smoke checks (minimal)

- Gateway reachable over tailnet (no public bind)
- macOS node paired (`openclaw nodes pending/approve/status` from the gateway)
- A macOS-only action succeeds via node (screen snapshot / system.run)
