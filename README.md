# ai-stack

Public, no‑PII AI stack modules. This repo provides opinionated defaults and
wiring for `nix-clawdbot`, but contains **no secrets or user-specific data**.

This repository is intentionally **not standalone**. It must be imported by a
private repo (e.g., `nixos-config`) that supplies secrets, allowlists, and local
paths. If those inputs are missing, builds should fail with clear errors.

## What this repo is

This repo is designed to be copyable by other users with a single agent prompt.
The public defaults should describe a complete Clawdbot setup once private inputs are provided.

- Public module layer imported from a private repo
- Non‑PII defaults for Clawdbot and AI tooling
- Source of truth for public docs + skills

## What this repo is not

- A complete, runnable bot config
- A home for secrets, tokens, or allowlists
- A place to wire private tool paths

## Slicing & dicing (repo boundaries)

Use `AGENTS.md` as the index for how these repos split responsibilities:

- `ai-stack`: public defaults + wiring (no PII)
- `nixos-config`: private secrets + allowlists + local paths
- `nix-clawdbot`: packaging and batteries‑included defaults for Clawdbot itself

## Core setup (private repo)

Import this repo from your private flake (Home Manager module):

```nix
imports = [ inputs.ai-stack.homeManagerModules.ai-stack ];
```

Private repo responsibilities:
- Provide secrets and PII inputs to `programs.clawdbot.*`
- Set Telegram allowlists and group modes
- Optionally override plugin sources with local paths

## Clawdbot wiring

This repo sets public defaults for `programs.clawdbot` (mirroring the full
example config from `nix-clawdbot`). Secrets are required for live plugins, and
the build should fail if they’re missing.

A short wiring guide lives at:
- `docs/agents/clawdbot-wiring-checklist.md`

## Agent guidance (public, no‑PII)

This repo ships public guidance and skills only:

- `docs/agents/GLOBAL_PREAMBLE.md` + `docs/agents/GLOBAL_CODEX_APPENDIX.md` → `~/.codex/AGENTS.md`
- `docs/agents/GLOBAL_PREAMBLE.md` + `docs/agents/GLOBAL_CLAUDE_APPENDIX.md` → `~/.claude/CLAUDE.md`
- `skills/` → `~/.codex/skills` and `~/.claude/skills`

Not included here:
- Claude permissions or `settings.json`
- Sub‑agent definitions

## Skills included

Synced into both Codex and Claude:
- `ask-questions-if-underspecified`
- `frontend-design`
- `markdown-converter`
- `nanobanana`
- `oracle`
- `product-manager`
- `rfc-adr-authoring` (examples sanitized)
- `skill-creator`
- `summarize-youtube`

## No‑sudo rule

Everything here is user‑level. No system‑level services or sudo required.

## Suggested repo layout

This stack assumes a simple layout under `~/code/nix`:

```text
~/code/nix/
  ai-stack/
  nixos-config/
  nix-secrets/
  nix-clawdbot/ (optional, dev only)
```

Adjust paths in the private repo if your layout differs.
