# ai-stack

One person's complete AI coding setup, as Nix: Claude Code, Codex and pi with
their skills, prompts, extensions and shell config, updated every night without
anyone touching the machine. This repo is the public part. A private repo plugs
in the secrets, the identity and the private skills.

## The three layers

| Layer | Repo | Holds |
| --- | --- | --- |
| Packages | [nix-ai-tools](https://github.com/joshp123/nix-ai-tools) | The AI CLIs as Nix packages. An hourly CI job bumps each to upstream latest and publishes only the versions that build and load, on Cachix. |
| The setup | **ai-stack** (this repo) | Skills, agent prompts, pi extensions, shell config, and the wiring: the bundle definition, the Home Manager pointers, Codex's system defaults and the nightly updater. |
| The machine | a private repo (for example `nixos-config`) | Secrets, identity, private skills, which host runs what. It calls into this repo with its own values. |

The line between public and private is "secrets and identity", not "content and
wiring". Everything that would be the same for the next person lives here.

## How the pieces fit together

**The bundle.** `lib.mkAiHome` builds one store path, the AI bundle, from the
nix-ai-tools packages: every tool under `bin/`, and under `share/` the config
the harnesses read:

| Path in the bundle | What |
| --- | --- |
| `bin/` | claude, codex, pi, herdr, agent-browser, dash-mcp-server, markit, markitdown, qmd, mobilebuildmcp (xcodebuildmcp's binary), and `cua-driver` (a link to the installed app, see below) |
| `share/pi/extensions`, `share/pi/skills`, `share/pi/packages/*` | pi's extensions, its skill collections, and its tool packages (web search, agent-browser) |
| `share/claude/skills`, `share/claude/CLAUDE.md` | Claude Code's skills and global instructions |
| `share/codex/skills` | Codex's skills |
| `share/ai/rules.md`, `share/ai/models.md` | the engineering rules and the model guide every harness is told to read |
| `share/ai/rev` | the commit of the private repo it was built from |
| `Applications/CuaDriver.app` | the computer-use driver, copied to `/Applications` by the updater |

**The profile.** The bundle is installed into a Nix profile owned by the user
(`~/.local/state/nix/profiles/ai`), never into the system. Changing a user
profile needs no sudo, so the tools can update daily while the system changes
rarely and deliberately.

**The pointers.** `homeManagerModules.ai-profile` puts the profile's `bin/` on
PATH and links `~/.pi/agent/{extensions,skills}`, `~/.claude/{skills,CLAUDE.md}`
and `~/.config/ai/{rules,models}.md` at fixed paths under the profile. The links
never change when the tools do. It also merges a few keys into the apps' own
JSON files, where the app writes strict JSON and merges too: pi's
`settings.json` (packages, enabled models) and `auth.json` (an Anthropic token
from a file you name), and Claude Code's `~/.claude.json` (the
`cua-computer-use` MCP server). `darwinModules.codex-defaults` does the same for
Codex through `/etc/codex`: `config.toml` and a `skills` link into the profile.

**The nightly update.** `darwinModules.update-ai-tools` is a launchd agent that
runs as you at 05:00 (later if the Mac was asleep), in its own clone of your
private repo:

1. `nix flake update nix-ai-tools ai-stack`, and commit the lock locally.
2. Build the bundle from that commit and smoke it: the three CLIs run, pi lists
   its models, every path the pointers expect exists (`ai-home-smoke`).
3. **The guard:** build your whole system configuration from the same commit.
   The job may change your lockfile, so it must never push a lockfile that
   leaves main unable to build your machine.
4. If both pass, push. If someone pushed meanwhile, redo once on top of their
   main.
5. Install exactly the verified commit's bundle into the profile, smoke it
   again, and roll back if that fails.
6. Copy `CuaDriver.app` to `/Applications` when its version differs from the
   profile's: copy it beside the old one, stop the daemon, swap the two by
   renaming, and move the old one to the Trash.
7. Delete profile generations older than a week.

If a build or check fails, nothing is pushed or installed. If installing the
app fails, the previous app stays in place and the profile goes back to the
generation it had before the run, which matches that app. Either way the job
tries again the next night. The system configuration is never switched by the
job; a pushed lock bump reaches the system at your next switch.

**Email alerts.** Silent while healthy. When the nightly job has not succeeded
for three days, or nix-ai-tools' hourly job has had no green run for three
days, `ai-home-mail` sends one email a day saying what is broken, since when,
and the last error. It uses Gmail SMTP through `curl` with an app password
read from a file you name (an agenix secret, in the private repo). There is no
self-repair: fixing is a task a person starts.

**Shell config.** `homeManagerModules.zsh` (starship, plugins,
`config/zsh/init-public.zsh`) and `homeManagerModules.ghostty` are imported by
the system's Home Manager like any other module; they are not part of the
bundle, so a change to them reaches the machine at the next switch.

## Plugging in a private repo

```nix
# flake.nix of the private repo
inputs.nix-ai-tools.url = "github:joshp123/nix-ai-tools";
inputs.ai-stack = {
  url = "github:joshp123/ai-stack";
  inputs.nix-ai-tools.follows = "nix-ai-tools";   # one lock entry for the packages
};

# the bundle, as the output the updater builds
packages.aarch64-darwin.ai-home = inputs.ai-stack.lib.mkAiHome {
  pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
  rev = self.rev or "unknown";
  extraSkills = [ ./ai/skills/apple ];                     # private skills, for Claude Code
  piCollections = [ {                                      # the same skills as a pi collection
    name = "apple/xcode-27";
    collection = ./ai/pi-collections/apple-xcode-27/COLLECTION.md;
    skills = ./ai/skills/apple;
  } ];
  piExtensions = [ ];                                      # { name = "x.ts"; path = ./x.ts; }
};
```

```nix
# Home Manager
imports = [ inputs.ai-stack.homeManagerModules.ai-profile inputs.ai-stack.homeManagerModules.zsh ];
programs.ai-profile = {
  enable = true;
  anthropicApiKeyFile = osConfig.age.secrets."anthropic-api-key".path;  # optional
};

# nix-darwin
imports = [ inputs.ai-stack.darwinModules.update-ai-tools inputs.ai-stack.darwinModules.codex-defaults ];
services.update-ai-tools = {
  enable = true;
  repo = "git@github.com:you/nixos-config.git";
  upstreamRuns = "https://api.github.com/repos/joshp123/nix-ai-tools/actions/workflows/auto-bump.yml/runs?status=success&per_page=1";
  mail = { to = "you@example.com"; from = "you@gmail.com"; passwordFile = config.age.secrets."gmail-app-password".path; };
};
programs.codex-defaults.enable = true;
```

First install on a machine, before the first switch so the pointers resolve:

```sh
nix build --profile ~/.local/state/nix/profiles/ai 'git+ssh://git@github.com/you/nixos-config#ai-home'
```

Day to day:

```sh
launchctl kickstart gui/$(id -u)/org.nixos.update-ai-tools   # update now
tail ~/Library/Logs/update-ai-tools.log
nix profile rollback --profile ~/.local/state/nix/profiles/ai  # undo the last update
```

To hold a tool at a version, pin its input URL to a commit in your flake
(`github:joshp123/nix-ai-tools/<rev>`); reverting a lock commit does not hold,
because the next night's `nix flake update` moves it again.

## Computer use

pi drives native apps through [cua-driver](https://github.com/trycua/cua): the
`cua-driver` skill (collection `tools/cua-driver`) teaches it the CLI, and
`CuaDriver.app` runs the daemon. The app hard-codes `/Applications/CuaDriver.app`,
so the updater copies it there and the bundle's `bin/cua-driver` points at that
copy; the store copy is never executed. Telemetry is off (`~/.cua/config.toml`).
Claude Code gets the same driver as the `cua-computer-use` MCP server. Codex has
its own computer-use engine in ChatGPT.app and uses it natively.

## Layout

```
ai-home/           lib.mkAiHome: default.nix (the tools), skills.nix (the three skill trees), layout.sh (share/)
  pi-collections/  one COLLECTION.md per pi skill collection
  openai-skills/   OpenAI's build-macos-apps skills, adapted for pi
modules/home/      ai-profile.nix (pointers), zsh.nix, ghostty.nix
modules/darwin/    update-ai-tools.nix (+ the three scripts), codex-defaults.nix
skills/            cross-harness skills
docs/agents/       global prompts: GLOBAL_PREAMBLE.md and the per-harness appendices, rules.md, models.md
extensions/        pi extensions: subagent, responses-v2-compaction, progressive-resources, claude-system-prompt-compat
config/            zsh, starship, ghostty
```

CI (`.github/workflows/build.yml`) builds `packages.aarch64-darwin.ai-home`, the
bundle with no private additions, on every push. The tools come from Cachix;
only the layout builds.

## Rules

- No secrets, tokens, private hostnames or paths with usernames. If it
  identifies a person or a machine, it belongs in the private repo.
- No inline scripts or content in Nix: shell, JSON and Markdown live in their
  own files next to the module.
- The bundle contract (`share/*` paths) changes on both sides at once:
  `ai-home/layout.sh`, the pointer in `modules/`, and `ai-home-smoke.sh`.
- Verify a change from the private repo before committing here, pointing at
  this checkout: `nix run .#build -- --override-input ai-stack path:/path/to/ai-stack`
  (the system) and `nix build .#ai-home --override-input ai-stack path:/path/to/ai-stack`
  (the bundle).
