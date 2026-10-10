---
written_by: ai
---

# ai-stack

The public half of one AI coding setup: skills, prompts, pi extensions, shell
config, and the Nix wiring that turns the nix-ai-tools packages into a bundle,
installs it into a user profile and updates it nightly. README.md explains the
whole flow; read it first.

## Working here

- Verify from the private repo before committing: in `nixos-config`,
  `nix run .#build -- --override-input ai-stack path:$HOME/code/nix/ai-stack`
  and `nix build .#ai-home --override-input ai-stack path:$HOME/code/nix/ai-stack`.
  The override is for verification only; applying means pushing this repo and
  letting the private repo's lockfile move (the nightly job does that).
- Prompt edits (`docs/agents/*`) are judged on the deployed file: after the
  bundle is installed, `~/.claude/CLAUDE.md` must match
  `GLOBAL_PREAMBLE.md` + `GLOBAL_CLAUDE_APPENDIX.md`.
- The bundle contract is the list of `share/*` paths in `ai-home/layout.sh`.
  Add a path there only together with its pointer
  (`modules/home/ai-profile.nix` or `modules/darwin/codex-defaults.nix`) and
  its line in `modules/darwin/update-ai-tools/ai-home-smoke.sh`.
- App-owned files are edited only by merging a few keys into strict JSON the
  app also merges (pi's `settings.json`/`auth.json`, Claude Code's
  `~/.claude.json`), through `modules/home/ai-profile/merge-json.sh`.
- Never run `cua-driver` from the Nix store (`result/bin`, the profile's
  `Applications/`): macOS taints the bundle and Nix can no longer canonicalise
  it. The installed copy is `/Applications/CuaDriver.app`.
- No inline scripts or content in Nix. Separate files, `builtins.readFile`.
- No PII: no secrets, tokens, private URLs, usernames in paths, device names.
  The prompts in `docs/agents/` are the owner's content and
  may name him; nothing else may.

## Where things go

| Thing | Where |
| --- | --- |
| A cross-harness skill | `skills/<name>/SKILL.md`; Claude Code gets it automatically, pi only through a collection in `ai-home/skills.nix`, Codex only through the list there |
| A pi extension | `extensions/`, then `ai-home/default.nix` |
| A global prompt change | `docs/agents/` |
| Which tools are in the bundle | `ai-home/default.nix` (the package must exist in nix-ai-tools) |
| Pointers into the profile | `modules/home/ai-profile.nix`, `modules/darwin/codex-defaults.nix` |
| The nightly job | `modules/darwin/update-ai-tools.nix` and `update-ai-tools/*.sh` |
| Shell config | `config/`, `modules/home/{zsh,ghostty}.nix` |
| An AI tool package | nix-ai-tools, not here |
| Secrets, identity, private skills, host choices | the private repo, not here |

`extensions/subagent/API.md` is a locked contract; read it before touching
`extensions/subagent/`.
