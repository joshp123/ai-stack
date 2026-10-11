---
written_by: ai
---

# modules/

The Nix modules a private repo imports, as flake outputs.

| Output | File | Does |
| --- | --- | --- |
| `homeManagerModules.ai-profile` | `home/ai-profile.nix` | PATH into the AI tools profile; the written skills, pi extensions and prompts (`content/`) as Home Manager links; merges into pi's and Claude Code's JSON files; `~/.cua/config.toml` |
| `homeManagerModules.zsh`, `.ghostty` | `home/zsh.nix`, `home/ghostty.nix` | shell and terminal config from `config/` |
| `darwinModules.update-ai-tools` | `darwin/update-ai-tools.nix` | the nightly launchd agent (nix-ai-tools packages only) and its four scripts under `darwin/update-ai-tools/` |
| `darwinModules.codex-defaults` | `darwin/codex-defaults.nix` | `/etc/codex/config.toml` and `/etc/codex/skills` (from `content/`) |

Every site-specific value (repo URL, mail addresses, secret paths, the
upstream run-history URL) is an option with no default; no default names a
person. The profile's owner defaults to `system.primaryUser`. Scripts are
separate files read with `builtins.readFile`; site values reach them through
the launchd agent's environment.
