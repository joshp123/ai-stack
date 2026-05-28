# ai-stack

Public, no‑PII AI stack modules. This repo provides opinionated defaults and
wiring for `nix-openclaw`, but contains **no secrets or user-specific data**.

This repository is intentionally **not standalone**. It must be imported by a
private repo (e.g., `nixos-config`) that supplies secrets, allowlists, and local
paths. If those inputs are missing, builds should fail with clear errors.

## What this repo is

This repo is designed to be copyable by other users with a single agent prompt.
The public defaults should describe a complete OpenClaw setup once private inputs are provided.

- Public module layer imported from a private repo
- Non‑PII defaults for OpenClaw and AI tooling
- Source of truth for public docs + skills

## What this repo is not

- A complete, runnable bot config
- A home for secrets, tokens, or allowlists
- A place to wire private tool paths
- The source of truth for which host runs which service
- The package owner for OpenClaw or OpenClaw-adjacent tools

## Slicing & dicing (repo boundaries)

Use `AGENTS.md` as the index for how these repos split responsibilities:

- `ai-stack`: public defaults + wiring (no PII)
- `nixos-config`: private secrets + allowlists + local paths + host topology
- `nix-ai-tools`: generic AI CLI packages
- `nix-openclaw`: packaging, module behavior, and reusable lifecycle for OpenClaw itself
- `nix-openclaw-tools`: OpenClaw-adjacent plugin/tool packages consumed through `nix-openclaw`
- `opentofu-infra`: provider-side cloud resources

Architecture notes live in `docs/architecture/ontology.md`.

## Core setup (private repo)

Import this repo from your private flake (Home Manager module):

```nix
imports = [ inputs.ai-stack.homeManagerModules.ai-stack ];
```

Private repo responsibilities:
- Provide secrets and PII inputs to `programs.openclaw.*`
- Set Telegram allowlists and group modes
- Optionally override plugin sources with local paths

## OpenClaw wiring

This repo sets public defaults for `programs.openclaw` (mirroring the full
example config from `nix-openclaw`). Secrets are required for live plugins, and
the build should fail if they’re missing.

A short wiring guide lives at:
- `docs/agents/openclaw-wiring-checklist.md`

## Agent guidance (public, no‑PII)

This repo ships public guidance and skills only:

- `docs/agents/GLOBAL_PREAMBLE.md` + `docs/agents/GLOBAL_CODEX_APPENDIX.md` → `~/.codex/AGENTS.md`
- `docs/agents/GLOBAL_PREAMBLE.md` + `docs/agents/GLOBAL_CLAUDE_APPENDIX.md` → `~/.claude/CLAUDE.md`
- `skills/` → `~/.claude/skills` and `~/.pi/agent/skills`
- Codex defaults/skills should be wired by the consumer repo under `/etc/codex/{config.toml,skills}` so `~/.codex` stays writable

Not included here:
- Claude permissions or `settings.json`
- Sub‑agent definitions

## Skills included

Custom cross-agent skills live in `skills/`.

Codex also ships built-in system skills under `~/.codex/skills/.system`, so avoid duplicating built-ins in `ai-stack/skills/` unless a custom variant adds real local policy, assets, or tooling.

## No‑sudo rule

Everything here is user‑level. No system‑level services or sudo required.

## Suggested repo layout

This stack assumes a simple layout under `~/code/nix`:

```text
~/code/nix/
  ai-stack/
  nix-ai-tools/
  nixos-config/
  nix-secrets/
  nix-openclaw/ (optional, dev only)
  nix-openclaw-tools/ (optional, dev only)
```

Adjust paths in the private repo if your layout differs.
