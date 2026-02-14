# ai-stack

**Public AI development experience** — shareable with anyone.

Skills, agent docs, shell config, tool wiring for Claude, Codex, pi, Cursor, Openclaw, etc.

```
nixos-config (your system)
├── imports: ai-stack ← you are here
├── imports: nix-ai-tools (tool packages, Garnix-cached)
├── imports: nix-openclaw, nix-secrets, ...
└── stacks/ai/ (private AI config wiring)
```

## Golden path

See `~/code/nix/AGENTS.md`. Always verify from nixos-config before committing here:

```bash
cd ~/code/nix/nixos-config
nix run .#build   # must pass — catches ai-stack breakage
```

If broken → fix ai-stack first, then re-verify.

## Core rules

- **No PII** — this repo is public (see below)
- **No inline scripts/content in Nix** — separate files + `readFile`
- **Verify downstream** before committing

## Repo layout

```
ai-stack/
├── flake.nix        # public entrypoints (no secrets)
├── skills/          # synced to ~/.claude/skills + ~/.pi/skills (Codex via /etc/codex/skills in consumer repo)
├── docs/agents/     # global guidance deployed to Codex/Claude/pi
├── config/zsh/      # public shell config
├── modules/         # Home Manager wiring
│   ├── ai-stack.nix        # main module
│   └── openclaw-config.nix # Openclaw defaults
└── documents/       # Openclaw docs (AGENTS/SOUL/TOOLS)
```

**Where to put things:**

| Type | Location |
|------|----------|
| Shareable skill | `skills/` |
| Public shell aliases | `config/zsh/` |
| Global agent guidance | `docs/agents/` |
| Openclaw public config | `modules/openclaw-config.nix` |
| Home Manager wiring | `modules/` |

**What does NOT belong here:**

| Type | Where instead |
|------|---------------|
| AI tool packages | `nix-ai-tools/pkgs/` |
| Secrets, tokens | `nixos-config` (agenix) |
| Private config | `nixos-config` |
| Per-user overrides | `nixos-config` |
| Openclaw packaging | `nix-openclaw` |
| Openclaw product code | `~/code/openclaw` |

**Rules of thumb:**
- Tool packages → `nix-ai-tools`
- Config, skills, public docs → here
- Identifies a person, location, device, or contains secrets → `nixos-config`

## No PII (public repo)

No secrets, tokens, private URLs, personal paths, user identifiers.

Includes: real names, absolute paths with usernames, API keys, emails, IPs, device names.

If it identifies a person → doesn't live here.
