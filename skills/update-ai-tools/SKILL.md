---
name: update-ai-tools
description: Maintain and update fast-moving AI tools in the Nix workspace. Use when asked to refresh, verify, package, install, or compare current versions of Codex, Claude Code, pi, MCP tools, XcodeBuildMCP, markit/markitdown, qmd, or other AI developer tools managed through nix-ai-tools, nixos-config, or ai-stack.
---

# Update AI Tools

AI tools change daily, so updating them is automatic and never touches the
system configuration. Your job is usually to check that the automation is
healthy, or fix the package that broke it.

## How updates flow

1. `nix-ai-tools` (packages): a GitHub Actions job bumps every package to
   upstream latest every hour and publishes only the bumps that build and load,
   cached on Cachix. Failed bumps are discarded; that package stays on its last
   good version.
2. `ai-stack` (the setup): skills, prompts, pi extensions, and the wiring
   (`lib.mkAiHome`, the `ai-profile` Home Manager module, the
   `update-ai-tools` nix-darwin module). It rides the same nightly update.
3. The private repo (`nixos-config`, the machine): the launchd user agent
   `org.nixos.update-ai-tools` runs nightly at 05:00 as the user. In its own
   clone it moves the `nix-ai-tools` and `ai-stack` lock entries, commits,
   builds the `ai-home` bundle and the system configuration from that commit
   (a lock bump must leave main building), pushes, installs exactly that
   bundle into the AI profile `~/.local/state/nix/profiles/ai` and copies
   CuaDriver.app to /Applications when its version changed. The system is
   never switched automatically; a pushed lock bump reaches it at the next
   `build-switch`.

GUI apps (Claude.app, ChatGPT.app) update themselves; Homebrew does not manage
their versions.

## Update now

```bash
launchctl kickstart gui/$(id -u)/org.nixos.update-ai-tools
tail -f ~/Library/Logs/update-ai-tools.log
```

Undo the last update: `nix profile rollback --profile ~/.local/state/nix/profiles/ai`.
This lasts until the next nightly run, which installs main again.

Hold a version: pin the input URL to a commit in `flake.nix`
(`github:joshp123/nix-ai-tools/<rev>`). Reverting the "chore: update AI tools"
lock commit does not hold; the next nightly run moves the lock again.

## When something is stale

- A tool is behind upstream: look at the hourly job first.
  ```bash
  gh run list --repo joshp123/nix-ai-tools --workflow auto-bump.yml --limit 5
  gh run view <id> --repo joshp123/nix-ai-tools --log | grep -E "Update |warn:"
  ```
  A `warn: <pkg> build failed` line names the broken package. Fix its packaging
  in `nix-ai-tools/pkgs/`, and fix `scripts/auto-bump.sh` if the bump itself is
  wrong, so future bumps land without help. Push; the next nightly run picks it
  up.
- The machine is behind `nix-ai-tools` main: read
  `~/Library/Logs/update-ai-tools.log`; the `FAILED at <step>` line names the
  step. `~/.local/state/ai-home/last-error` holds the last failure.
- An alert email arrived: it means one of the above has lasted three days.
  Fixing it is a task you start; the automation never pushes fixes itself.

## Rules

- Prove "latest" against upstream (npm, GitHub releases, vendor feeds), never
  against local or locked state.
- Pin a fast input to a revision in `flake.nix` only to hold a version on
  purpose, and remove the pin once the reason is gone: while it is there, that
  input gets no updates.
- No `brew upgrade`, `--override-input`, or uncommitted lock edits as an update
  path. Never switch the system to deliver an AI tool update.
