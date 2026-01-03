# ai-stack

Public, no‑PII AI stack modules. This repo provides opinionated defaults and
wiring for `nix-clawdis`, but contains no secrets or user-specific data.

## What this is

- A **public** module layer you can import from private config.
- A stable home for non‑PII AI defaults (documents, policies, module wiring).

## What this is not

- Your actual bot config (tokens, allowlists, PII). That belongs in a private repo.

## Usage (private repo)

```nix
imports = [ ~/code/ai-stack/modules/ai-stack.nix ];
```

This sets:
- `programs.clawdis.documents = ../documents` (override if needed)

## Agent guidance (public, no‑PII)

This repo ships public guidance and skills only:

- `docs/agents/CODEX.md` → `~/.codex/AGENTS.md`
- `docs/agents/CLAUDE.md` → `~/.claude/CLAUDE.md`
- `skills/` → `~/.codex/skills` and `~/.claude/skills`

Deliberately **not included** here:
- Claude sub‑agents
- Claude permissions or `settings.json`

Keep those in your private repo. If you’re running in YOLO mode, the safest public
default is to **omit** managed permissions entirely.

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
