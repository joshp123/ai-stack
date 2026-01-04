# ai-stack

Public, no‑PII AI stack modules. This repo provides opinionated defaults and
wiring for `nix-clawdbot`, but contains no secrets or user-specific data.

## Core AI stack

This is my AI development stack. There are many stacks like it, but this one is mine.

I use Codex w/GPT-5.2-codex for coding. I use Clawdbot with Opus 4.5 as my AI assistant. I use it on a Big Monitor (TM) (57" 7680 x 2160). I have max plans on both tools. I try and write all my tools in golang (BE), proto (API), typescript+react (FE), as this stack works very well with codex.

I have some skills that do things. I like the RFC one. This is very useful. `nanobanana` is helpful too, for when you want to generate project images. The product manager one is sort of okay. The rest are mostly boring and plumbing.

This repository is all nix-based, so if you want to steal what I'm doing, you can point your AI agent at it, and copy my approach. That might be a good idea, it might be not: my defaults and preferred toolchain work for me, they might not work for you.

The most fun part, and the part that I'm most excitted about is [`nix-clawdbot`](https://github.com/clawdbot/nix-clawdbot), which wraps [`clawdbot`](https://github.com/steipete/clawdbot) in nix and has a plugin system. This is the basis of my AI assistant stack, and should be wired in here. [`clawdbot`](https://github.com/steipete/clawdbot) can also self-modify its own configuration, and has a development and test `clawdbot` instance.

The most fun part of my [`nix-clawdbot`](https://github.com/clawdbot/nix-clawdbot) stack is [`gohome`](https://github.com/joshp123/gohome), my [`clawdbot`](https://github.com/steipete/clawdbot) based Home Assistant clone.

## Projects

- [`ai-stack`](https://github.com/joshp123/ai-stack)
- [`nix-clawdbot`](https://github.com/clawdbot/nix-clawdbot)
- [`gohome`](https://github.com/joshp123/gohome)
- [`clawdbot` (upstream)](https://github.com/steipete/clawdbot)

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
- `programs.clawdbot.documents = ../documents` (override if needed)

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
