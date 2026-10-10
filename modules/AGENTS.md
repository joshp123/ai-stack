---
written_by: ai
---

# modules/

The Nix modules a private repo imports, as flake outputs.

| Output | File | Does |
| --- | --- | --- |
| `homeManagerModules.ai-profile` | `home/ai-profile.nix` | PATH and fixed links into the AI profile; merges into pi's and Claude Code's JSON files; `~/.cua/config.toml` |
| `homeManagerModules.zsh`, `.ghostty` | `home/zsh.nix`, `home/ghostty.nix` | shell and terminal config from `config/` |
| `darwinModules.update-ai-tools` | `darwin/update-ai-tools.nix` | the nightly launchd agent and its three scripts under `darwin/update-ai-tools/` |
| `darwinModules.codex-defaults` | `darwin/codex-defaults.nix` | `/etc/codex/config.toml` and `/etc/codex/skills` |

Every site-specific value (repo URL, mail addresses, secret paths, the
profile's owner) is an option with no default that names a person. Scripts are
separate files read with `builtins.readFile`; site values reach them through
the launchd agent's environment.
