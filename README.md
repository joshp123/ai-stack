# ai-stack

One person's complete AI coding setup, as Nix: Claude Code, Codex and pi with
their skills, prompts, extensions and shell config. The tools themselves update
every night without root; everything written by hand changes only when you
switch your system. This repo is the public part. A private repo plugs in the
secrets, the identity and the private skills.

## The three layers

| Layer | Repo | Holds |
| --- | --- | --- |
| Packages | [nix-ai-tools](https://github.com/joshp123/nix-ai-tools) | The AI CLIs as Nix packages. An hourly CI job bumps each to upstream latest and publishes only the versions that build and load, on Cachix. |
| The setup | **ai-stack** (this repo) | Skills, agent prompts, pi extensions, shell config, and the wiring: the tools bundle definition, the Home Manager module, Codex's system defaults and the nightly updater. |
| The machine | a private repo (for example `nixos-config`) | Secrets, identity, private skills, which host runs what. It calls into this repo with its own values. |

The line between public and private is "secrets and identity", not "content and
wiring". Everything that would be the same for the next person lives here.

## How the pieces fit together

There are two lanes, and the line between them is "packaged by nix-ai-tools"
versus "written by a person or an agent".

| Lane | What | Changes when |
| --- | --- | --- |
| Tools | the nix-ai-tools packages: the CLIs, pi's tool packages, and files a package ships that must match its binary | every night, as you, without root |
| Everything written | skills, prompts, pi extensions, `CLAUDE.md`, `rules.md`, `models.md`, Codex's defaults, the updater itself, shell config | only when you switch your system |

**The tools bundle.** `lib.mkAiTools` (`ai-tools/`) builds one store path from
the nix-ai-tools packages, with nix-ai-tools' own nixpkgs. Nothing written by
hand is in it, so a skill or prompt commit, or a bump of your system's nixpkgs,
leaves it byte-for-byte the same.

| Path in the bundle | What |
| --- | --- |
| `bin/` | claude, codex, pi, herdr, agent-browser, dash-mcp-server, markit, markitdown, qmd, mobilebuildmcp (xcodebuildmcp's binary), and `cua-driver` (a link to the installed app, see below) |
| `share/pi/packages/*` | pi's tool packages (web search, agent-browser) |
| `share/cua-driver/skills` | the `cua-driver` skill, shipped with the binary it describes |
| `share/herdr/integrations/pi` | herdr's pi extension |
| `share/pi-autoresearch/skills` | pi-autoresearch's skills |
| `Applications/CuaDriver.app` | the computer-use driver, copied to `/Applications` by the updater |

**The profile.** The bundle is installed into a Nix profile owned by the user
(`~/.local/state/nix/profiles/ai`), never into the system. Changing a user
profile needs no sudo.

**The written files.** `lib.mkContent` (`content/`) builds the skill trees, the
pi extensions and the prompts as store paths. `homeManagerModules.ai-profile`
links them from your Home Manager generation: `~/.pi/agent/{extensions,skills}`,
`~/.claude/{skills,CLAUDE.md}` and `~/.config/ai/{rules,models}.md`.
`darwinModules.codex-defaults` puts Codex's `config.toml` and skills in
`/etc/codex`. Both are part of the system, so these files change only on a
switch. The few package files inside those trees (the cua-driver skill,
pi-autoresearch's skills, herdr's extension) are links to fixed paths in the
profile, so they follow the tools without a switch.

The module also puts the profile's `bin/` on PATH and merges a few keys into the
apps' own JSON files, where the app writes strict JSON and merges too: pi's
`settings.json` (its tool packages, at fixed profile paths, and enabled models)
and `auth.json` (an Anthropic token from a file you name), and Claude Code's
`~/.claude.json` (the `cua-computer-use` MCP server).

**The nightly update.** `darwinModules.update-ai-tools` is a launchd agent that
runs as you at 05:00 (later if the Mac was asleep), in its own clone of your
private repo:

1. `nix flake update nix-ai-tools` (that lock entry only), and commit locally.
2. Build the tools bundle from that commit and smoke it: the three CLIs run, pi
   lists its models, every fixed path the system links to exists
   (`ai-tools-smoke`).
3. **The extension guard:** load the pi extensions your system links, as
   committed on main, into the new pi (`ai-tools-extension-check`). Those extensions
   change only on a switch, so a pi that cannot load them must not be
   installed.
4. **The system guard:** build your whole system configuration from the same
   commit. The job changes your lockfile, so it must never push a lockfile
   that leaves main unable to build your machine.
5. If all pass, push. If someone pushed meanwhile, redo once on top of their
   main.
6. Install exactly the verified commit's bundle into the profile, smoke it
   again, and roll back if that fails. An unchanged bundle is the same store
   path, so it makes no new profile generation.
7. Copy `CuaDriver.app` to `/Applications` when its version differs from the
   profile's: copy it beside the old one, stop the daemon, swap the two by
   renaming, and move the old one to the Trash.
8. **The model check:** one real "Reply with one word: ok" call each to pi,
   Codex and Claude Code with their default models (`ai-tools-model-check`).
   A retired or gated default fails the run, and the three-day alert follows,
   instead of failing the next time someone uses it.
9. Delete profile generations older than a week.

**Default models.** Codex and Claude Code follow the vendor: Codex has no model
set, so the server's top-ranked model is used; Claude Code uses the `opus`
alias. pi has no "latest" alias, so its default is one declared pin
(`programs.ai-profile.defaultModel`), re-applied on every switch and checked
every night by the model check.

If a build or check fails, nothing is pushed or installed. If installing the
app fails, the previous app stays in place and the profile goes back to the
generation it had before the run, which matches that app. Either way the job
tries again the next night. The system configuration is never switched by the
job; ai-stack and everything else in your lockfile move only by your own
commits, and reach the machine at your next switch.

**Email alerts.** Silent while healthy. When the nightly job has not succeeded
for three days, or nix-ai-tools' hourly job has had no green run for three
days, `ai-tools-mail` sends one email a day saying what is broken, since when,
and the last error. It uses Gmail SMTP through `curl` with an app password
read from a file you name (an agenix secret, in the private repo). There is no
self-repair: fixing is a task a person starts.

**Shell config.** `homeManagerModules.zsh` (starship, plugins,
`config/zsh/init-public.zsh`) and `homeManagerModules.ghostty` are imported by
the system's Home Manager like any other module, so a change to them reaches
the machine at the next switch.

## Plugging in a private repo

```nix
# flake.nix of the private repo
inputs.nix-ai-tools.url = "github:joshp123/nix-ai-tools";
inputs.ai-stack = {
  url = "github:joshp123/ai-stack";
  inputs.nix-ai-tools.follows = "nix-ai-tools";   # one lock entry for the packages
};

packages.aarch64-darwin = {
  # the tools bundle, the output the updater installs
  ai-tools = inputs.ai-stack.lib.mkAiTools { system = "aarch64-darwin"; };
  # the pi extensions your system links, which the updater loads into each new pi
  pi-extensions = self.darwinConfigurations.aarch64-darwin.config
    .home-manager.users.you.programs.ai-profile.authoredPiExtensions;
};
```

```nix
# Home Manager
imports = [ inputs.ai-stack.homeManagerModules.ai-profile inputs.ai-stack.homeManagerModules.zsh ];
programs.ai-profile = {
  enable = true;
  anthropicApiKeyFile = osConfig.age.secrets."anthropic-api-key".path;  # optional
  extraClaudeSkills = [ ./ai/skills/apple ];                             # private skills, for Claude Code
  piCollections = [ {                                                    # the same skills as a pi collection
    name = "apple/xcode-27";
    collection = ./ai/pi-collections/apple-xcode-27/COLLECTION.md;
    skills = ./ai/skills/apple;
  } ];
  piExtensions = [ ];                                                    # { name = "x.ts"; path = ./x.ts; }
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

First install on a machine, so the links into the profile resolve:

```sh
nix build --profile ~/.local/state/nix/profiles/ai 'git+ssh://git@github.com/you/nixos-config#ai-tools'
```

Day to day:

```sh
launchctl kickstart gui/$(id -u)/org.nixos.update-ai-tools   # update now
tail ~/Library/Logs/update-ai-tools.log
nix profile rollback --profile ~/.local/state/nix/profiles/ai  # undo the last tools update
```

A skill, prompt or extension change is a commit (to this repo, then a lock bump
in yours, or to your private repo) followed by your switch. Undo it like any
other system change.

To hold a tool at a version, pin its input URL to a commit in your flake
(`github:joshp123/nix-ai-tools/<rev>`); reverting a lock commit does not hold,
because the next night's `nix flake update` moves it again.

## Computer use

pi drives native apps through [cua-driver](https://github.com/trycua/cua): the
`cua-driver` skill (collection `tools/cua-driver`, shipped with the package and
linked from the profile) teaches it the CLI, and `CuaDriver.app` runs the
daemon. The app hard-codes `/Applications/CuaDriver.app`,
so the updater copies it there and the bundle's `bin/cua-driver` points at that
copy; the store copy is never executed. Telemetry is off (`~/.cua/config.toml`).
Claude Code gets the same driver as the `cua-computer-use` MCP server. Codex has
its own computer-use engine in ChatGPT.app and uses it natively.

## Layout

```
ai-tools/          lib.mkAiTools: default.nix (the packages), layout.sh (cua-driver's app and skills)
content/           lib.mkContent: default.nix (extensions, prompts), skills.nix (the three skill trees)
  pi-collections/  one COLLECTION.md per pi skill collection
  openai-skills/   OpenAI's build-macos-apps skills, adapted for pi
modules/home/      ai-profile.nix (PATH, the written files, JSON merges), zsh.nix, ghostty.nix
modules/darwin/    update-ai-tools.nix (+ the three scripts), codex-defaults.nix
skills/            cross-harness skills
docs/agents/       global prompts: GLOBAL_PREAMBLE.md and the per-harness appendices, rules.md, models.md
extensions/        pi extensions: subagent, responses-v2-compaction, progressive-resources, claude-system-prompt-compat
config/            zsh, starship, ghostty
```

CI (`.github/workflows/build.yml`) builds `packages.aarch64-darwin.ai-tools` and
`checks.aarch64-darwin.content` (the written trees with no private additions)
on every push. The tools come from Cachix; only the layout builds.

## Rules

- No secrets, tokens, private hostnames or paths with usernames. If it
  identifies a person or a machine, it belongs in the private repo.
- No inline scripts or content in Nix: shell, JSON and Markdown live in their
  own files next to the module.
- Only nix-ai-tools packages and the files they ship go in the tools bundle.
  Anything written by hand goes in `content/` or a module, so it changes only
  on a switch.
- A fixed path into the profile changes in two places at once: where it is
  linked (`content/` or `modules/`) and its line in `ai-tools-smoke.sh`.
- Verify a change from the private repo before committing here, pointing at
  this checkout: `nix run .#build -- --override-input ai-stack path:/path/to/ai-stack`
  (the system) and `nix build .#ai-tools --override-input ai-stack path:/path/to/ai-stack`
  (the bundle).
