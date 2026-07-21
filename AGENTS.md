---
written_by: ai
---

# ai-stack

**Public AI development experience** — shareable with anyone.

Skills, agent docs, shell config, tool wiring for Claude, Codex, pi, Cursor, OpenClaw, etc.

```
nixos-config (your system)
├── imports: ai-stack ← you are here
├── imports: nix-ai-tools (tool packages, Garnix-cached)
├── imports: nix-openclaw, nix-secrets, ...
└── stacks/ai/ (private AI config wiring)
```

This repo owns public, no-secret defaults. It does not own live host topology.
If a doc here says a VPS, Mac, or mini server is canonical, that doc is stale;
the private consumer repo chooses which host runs which profile.

## Golden path

See `~/code/nix/AGENTS.md`. Always verify from nixos-config before committing here:

```bash
cd ~/code/nix/nixos-config
AI_STACK="$HOME/code/nix/ai-stack"
nix run .#build -- --override-input ai-stack "path:$AI_STACK"   # catches the local ai-stack checkout, not the pinned input
```

For `docs/agents/*` edits, source changes are not enough. After the build, apply and verify the deployed Codex file before judging prompt quality:

```bash
cd ~/code/nix/nixos-config
AI_STACK="$HOME/code/nix/ai-stack"
activation=$(nix build --no-link --print-out-paths --impure --override-input ai-stack "path:$AI_STACK" .#homeConfigurations.josh-aarch64-darwin-base.activationPackage)
"$activation/activate"
diff -u <(cat "$AI_STACK/docs/agents/GLOBAL_PREAMBLE.md" "$AI_STACK/docs/agents/GLOBAL_CODEX_APPENDIX.md") ~/.codex/AGENTS.md
```

The override is deliberate but narrow:

- Use it only to validate local ai-stack edits before `nixos-config` pins the new commit.
- It does not edit `flake.lock`; it substitutes one known checkout so build/apply tests the files being reviewed.
- Do not use it for arbitrary branches or unrelated inputs.
- Do not use `nix run .#hm-apply-base --override-input ...` for this check; that wrapper re-enters the flake and can silently use the pinned input instead.

Default apply rule: a request to apply, switch, deploy, or make ai-stack changes
live means publish this repo and consume it declaratively from `nixos-config`.
Do not run `build-switch`, `hm-apply-*`, direct activation, or deploy commands
with `--override-input ai-stack path:$AI_STACK` unless Josh explicitly says to
apply that local override. The normal deploy path is: commit ai-stack, push it,
update the `ai-stack` input in `nixos-config`, commit `flake.lock`, build, and
switch without overrides.

New Codex sessions only see the changed prompt after this deployed file matches the source. Also verify one fresh Codex session actually injects the new wording before judging behavior.

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
│   ├── ai-stack.nix        # OpenClaw-free main module
│   ├── openclaw-config.nix # OpenClaw defaults
│   ├── openclaw-documents.nix # OpenClaw workspace documents
│   └── bots/               # transitional DJTBOT role profiles
├── documents/       # OpenClaw workspace docs (AGENTS/SOUL/TOOLS)
├── extensions/      # pi coding-agent extensions
└── scripts/         # helper scripts called from Nix/Home Manager
```

**Where to put things:**

| Type | Location |
|------|----------|
| Shareable skill | `skills/` |
| Public shell aliases | `config/zsh/` |
| Global agent guidance | `docs/agents/` |
| OpenClaw public config | `modules/openclaw-config.nix` |
| Home Manager wiring | `modules/` |
| OpenClaw workspace docs | `documents/` |
| pi coding-agent extensions | `extensions/` |

**What does NOT belong here:**

| Type | Where instead |
|------|---------------|
| AI tool packages | `nix-ai-tools/pkgs/` |
| Secrets, tokens | `nixos-config` (agenix) |
| Private config | `nixos-config` |
| Per-user overrides | `nixos-config` |
| Live host topology/deploy choices | `nixos-config` |
| Provider-side cloud resources | `~/code/opentofu-infra` |
| OpenClaw packaging/module behavior | `nix-openclaw` |
| OpenClaw-adjacent tool/plugin packages | `nix-openclaw-tools` via `nix-openclaw` |
| OpenClaw product code | `~/code/openclaw` |

**Rules of thumb:**
- Tool packages → `nix-ai-tools`
- Config, skills, public docs → here
- Identifies a person, location, device, or contains secrets → `nixos-config`
- Reusable OpenClaw install/lifecycle behavior → `nix-openclaw`
- Cloud project/IAM/API-key resources → `opentofu-infra`

## No PII (public repo)

No secrets, tokens, private URLs, personal paths, user identifiers.

Includes: real names, absolute paths with usernames, API keys, emails, IPs, device names.

If it identifies a person → doesn't live here.
