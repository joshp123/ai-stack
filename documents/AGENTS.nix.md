# AGENTS (Nix baseline)

This file is managed by Nix and is **not** loaded automatically by Clawdbot.
It exists to document the Nix baseline without overwriting your workspace `AGENTS.md`.

If you want the agent to follow these rules, copy or merge them into:
- `@HOME@/.clawdbot/workspace/AGENTS.md`
- `@HOME@/.clawdbot/workspace/AGENTS.local.md`

## Runtime scratchpad convention (no code changes)

Use `AGENTS.local.md` for runtime updates. The agent should:
- Always read `AGENTS.local.md` if it exists before acting.
- Write new rules, preferences, and memory to `AGENTS.local.md`.
- Never delete or overwrite `AGENTS.local.md`.

## Installed tools & skills

See `@HOME@/.clawdbot/workspace/TOOLS_INSTALLED.md`.

## Skills

Managed skills (live symlinks):
- `padel` → `@HOME@/code/padel-cli/skills/padel`
- `gohome` → `@HOME@/code/gohome/skills/gohome`

Workspace skills (user-owned, highest precedence):
- `@HOME@/.clawdbot/workspace/skills`

## Key repos (source of truth)

- `@HOME@/code/nix/nixos-config` — system + Clawdbot config (Nix)
- `@HOME@/code/nix/nix-secrets` — agenix secrets (private)
- `@HOME@/code/clawdbot` — Clawdbot source (optional, dev only)
