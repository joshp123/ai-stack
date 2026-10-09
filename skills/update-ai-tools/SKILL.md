---
name: update-ai-tools
description: Maintain and update fast-moving AI tools in the Nix workspace. Use when asked to refresh, verify, package, install, apply, or compare current versions of Codex, Claude Code, pi, MCP tools, XcodeBuildMCP, markit/markitdown, qmd, spogo, or other AI developer tools managed through nix-ai-tools, nixos-config, or ai-stack.
---

# Update AI Tools

AI tools change daily, so updating them is automatic. Your job is usually to
check that the automation is healthy, or fix the package that broke it.

## How updates flow

1. `nix-ai-tools` (packages): a GitHub Actions job bumps every package to
   upstream latest every hour and publishes only the bumps that build, cached on
   Cachix. Failed bumps are discarded; that package stays on its last good
   version.
2. `nixos-config` (the machine): `update-ai-tools` runs nightly from launchd and
   on demand. In its own clone it updates the `nix-ai-tools` and `ai-stack`
   inputs, builds, pushes `flake.lock` to main, and switches. The nightly run
   switches only if `/etc/sudoers.d/update-ai-tools` exists; otherwise it
   notifies the user to run `update-ai-tools`. Applied state always matches a
   pushed commit.
3. `ai-stack` (skills and config) rides the same nightly update.

GUI apps (Claude.app, ChatGPT.app) update themselves; Homebrew does not manage
their versions.

## Update now

```bash
update-ai-tools
```

It shows the version changes, then asks for sudo (Apple Watch) to switch.

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
  `~/Library/Logs/update-ai-tools.log`.

## Rules

- Prove "latest" against upstream (npm, GitHub releases, vendor feeds), never
  against local or locked state.
- Never pin a fast input to a revision in `flake.nix`; that silently stops all
  updates.
- No `brew upgrade`, Home Manager-only activation, `--override-input`, or
  uncommitted lock edits as an update path.
