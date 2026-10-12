---
written_by: ai
---

# ai-stack

The public half of one AI coding setup: skills, prompts, pi extensions, shell
config, and the Nix wiring around the nix-ai-tools packages. Two lanes: the
nix-ai-tools packages update nightly into a user profile without root;
everything written here (skills, prompts, extensions, modules) changes only on
a system switch. README.md explains the whole flow; read it first.

## Working here

- Verify from the private repo before committing: in `nixos-config`,
  `nix run .#build -- --override-input ai-stack path:$HOME/code/nix/ai-stack`
  and `nix build .#ai-tools --override-input ai-stack path:$HOME/code/nix/ai-stack`.
  The override is for verification only; applying means pushing this repo,
  committing the private repo's `ai-stack` lock bump, and switching. The
  nightly job never moves `ai-stack`.
- Prompt edits (`docs/agents/*`) are judged on the deployed file: after the
  switch, `~/.claude/CLAUDE.md` must match
  `GLOBAL_PREAMBLE.md` + `GLOBAL_CLAUDE_APPENDIX.md`.
- The tools bundle (`ai-tools/`) holds nix-ai-tools packages and the files
  they ship, nothing written by hand. Written things go in `content/` or a
  module.
- The system reaches into the profile only by fixed paths. Add one only
  together with its line in `modules/darwin/update-ai-tools/ai-tools-smoke.sh`.
- App-owned files are edited only by merging a few keys into strict JSON the
  app also merges (pi's `settings.json`/`auth.json`, Claude Code's
  `~/.claude.json` and `~/.claude/settings.json`), through
  `modules/home/ai-profile/merge-json.sh`.
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
| A cross-harness skill | `skills/<name>/SKILL.md`; Claude Code gets it automatically, pi only through a collection in `content/skills.nix`, Codex only through the list there |
| A pi extension | `extensions/`, then `content/default.nix` |
| A global prompt change | `docs/agents/` |
| Which tools are in the bundle | `ai-tools/default.nix` (the package must exist in nix-ai-tools) |
| A package-owned file the harnesses read (a skill or extension shipped with a tool) | a fixed profile path in `content/`, plus its line in `ai-tools-smoke.sh` |
| The home and `/etc/codex` wiring | `modules/home/ai-profile.nix`, `modules/darwin/codex-defaults.nix` |
| The nightly job | `modules/darwin/update-ai-tools.nix` and `update-ai-tools/*.sh` |
| Shell config | `config/`, `modules/home/{zsh,ghostty}.nix` |
| An AI tool package | nix-ai-tools, not here |
| Secrets, identity, private skills, host choices | the private repo, not here |

`extensions/subagent/API.md` is a locked contract; read it before touching
`extensions/subagent/`.
