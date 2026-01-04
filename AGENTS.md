# ai-stack Agents

## No PII (first rule)

This repo is public. Do NOT add secrets, tokens, private URLs, personal paths, or user identifiers.
If something is sensitive, it belongs in a private repo and should be linked in via Nix.

PII includes (not exhaustive):
- Real names, usernames, or handles tied to a person
- Home/work locations, cities, or timezones
- Personal domains, subdomains, and private hostnames
- Absolute paths containing a user name (e.g., `/Users/alice/...`)
- Emails, phone numbers, IPs, MACs, or device names
- API keys, tokens, cookies, and auth files

## Repo structure (source of truth)

- `documents/` — Clawdbot docs (AGENTS/SOUL/TOOLS) referenced by nix-clawdbot.
- `docs/agents/` — Global agent guidance deployed to Codex/Claude.
- `skills/` — Shared skills synced into `~/.codex/skills` and `~/.claude/skills`.
- `modules/` — Home Manager modules wiring docs + skills + agent guidance.
- `flake.nix` — Public module entrypoints. No secrets, no installs.

Clawdbot packaging (including UI assets) belongs in `nix-clawdbot`. Do not add
Clawdbot build overlays here.

## What this repo contains (and does NOT contain)

- ✅ Safe, public guidance + skill scaffolding
- ✅ Wiring to deploy docs/skills via Home Manager
- ❌ Secrets, tokens, or per-user config
- ❌ Claude permission rules or sub-agent definitions

If you need private settings, keep them in your private repo and import this flake.

Shell config split:
- Public zsh defaults live here (`modules/zsh.nix`, `config/zsh/`).
- Private, host/user-specific overrides belong in the private repo.

Clawdbot slicing:
- Instance wiring and defaults live here (`modules/clawdbot-config.nix`).
- Private repo provides secrets, allowlists, and local skill paths via `ai.clawdbot.profile.*`.

## Apply changes (no sudo)

This repo is intended to apply via **Home Manager only**.

- Recommended (from your private repo):
  - `home-manager switch --flake "$HOME/code/nixos-config#$(whoami)"`
- Avoid full nix-darwin rebuilds unless you changed system-level config.
