---
name: update-ai-tools
description: Maintain and update fast-moving AI tools in the Nix workspace. Use when asked to refresh, verify, package, install, apply, or compare current versions of Codex, Claude, pi, MCP tools, XcodeBuildMCP, markit/markitdown, qmd, spogo, or other AI developer tools managed through nix-ai-tools, nixos-config, Homebrew tap locks, or ai-stack.
---

# Update AI Tools

Use this skill to keep the AI toolchain declarative and simple: package updates land in the package repo, consumption happens through locked inputs in the system repo, and live installs happen through the normal Nix/Darwin switch path.

Prefer deleting or reusing existing surfaces over adding commands. Codex is usually the caller; the point is not a polished human interface, it is one small workflow with no duplicate wrappers, aliases, or imperative package-manager side paths.

## Repos

- `nix-ai-tools`: package definitions and hourly auto-bump CI for fast AI CLIs.
- `nixos-config`: private consumer that pins `nix-ai-tools`, `nixpkgs-fast`, and Homebrew taps, then builds and switches the machine.
- `ai-stack`: public skills, docs, shell config, and agent defaults. Do not put tool packages here.

## Rules

- Do not run direct `brew upgrade` for these tools. Homebrew casks/formulae are consumed through flake-locked taps and applied by Nix.
- Do not treat local `brew list`, installed app receipts, or the current `flake.lock` as proof that a tool is latest. Those are local or locked state. For latest claims, check a server-side upstream source such as the live Homebrew tap commit, `brew livecheck`, the vendor release feed, GitHub releases/tags, npm/PyPI metadata, or the tool's official download metadata.
- Do not apply from local path overrides, archive extracts, temporary checkouts, or copied worktrees unless the user explicitly asks for that exact nonstandard apply.
- Do not use Home Manager-only activation as the update path when the user asked to install or apply the whole AI stack.
- Do not stash or commit unrelated work to get a clean deploy. Move disposable notes to an untracked scratch area or ask the user.
- Commit source repos before consuming them declaratively. For `nix-ai-tools` or `ai-stack`, publish the source commit, then update the matching input in `nixos-config`.
- Treat auto-updating GUI apps carefully. If Homebrew receipt metadata disagrees with the app bundle, prefer the live bundle version from `/Applications/*.app/Contents/Info`.

## Workflow

1. Inspect current state.
   ```bash
   cd ~/code/nix/nix-ai-tools && git status --short --branch
   cd ~/code/nix/nixos-config && git status --short --branch
   ```

2. Check whether the package repo is healthy and current before changing the consumer lock.
   ```bash
   cd ~/code/nix/nix-ai-tools
   gh run list --branch main --limit 5
   ./scripts/auto-bump.sh
   ```
   If `auto-bump.sh` changes files, inspect the diff, build the changed packages or rerun with `AUTO_BUMP_BUILD=1`, then commit and push `nix-ai-tools` first.

3. Check upstream current versions for Homebrew-managed fast tools before trusting local state.
   ```bash
   brew livecheck --cask codex claude claude-code || true
   python3 - <<'PY'
   import json, urllib.request
   for cask in ["codex", "claude", "claude-code"]:
       with urllib.request.urlopen(f"https://formulae.brew.sh/api/cask/{cask}.json", timeout=20) as response:
           data = json.load(response)
       print(cask, data.get("version"), data.get("tap_git_head"))
   PY
   ```
   If Homebrew is unavailable, immutable, or stale locally, query the remote tap or upstream release source directly. For example, inspect `homebrew/homebrew-cask` at the target remote commit and compare the cask `version` against the local flake-locked tap commit and installed app. `brew cat`, `brew list`, and app receipts are local state; they are not enough to prove latest.

4. Update the consumer from the published inputs.
   ```bash
   cd ~/code/nix/nixos-config
   ./stacks/ai/config/scripts/update-ai-tools.sh
   ```
   This updates the fast inputs, runs `nix run .#build`, and reports local fast-tool state. Review `flake.lock` before committing.

5. Compare local installed versions against declared and upstream state.
   ```bash
   codex --version || true
   claude --version || true
   pi --version || true
   brew list --cask --versions claude claude-code codex || true
   brew outdated --cask --greedy claude claude-code codex || true
   /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' /Applications/Claude.app/Contents/Info.plist 2>/dev/null || true
   /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' /Applications/Codex.app/Contents/Info.plist 2>/dev/null || true
   ```
   For each important tool, report `upstream latest`, `locked/declarative version`, and `installed/live version`. Call out uncertainty explicitly when a vendor hides the latest version behind an auto-updater or non-public feed.

6. Install by applying the committed declarative state.
   ```bash
   cd ~/code/nix/nixos-config
   nix run .#build-switch
   ```
   This may require interactive sudo with Apple Watch approval. Run it in a real TTY. A normal switch should need one Watch approval up front: keep sudo alive with non-interactive validation, make later wrapper sudo calls non-interactive, and do not leave Homebrew cleanup in prompt mode. If the Watch prompt does not appear or sudo falls through to `Password:`, do not assume PAM is broken; common causes are Sleep Focus / "Computer and other devices" focus state, a locked or long-idle Mac, the user typing as the prompt appears and dismissing it, or a stale prompt context. Retry once with a fresh foreground TTY prompt. If it still does not trigger, stop and return to the user rather than inventing a non-declarative apply path.

## Decisions

- If `nix-ai-tools` CI is red or the package repo has stale package definitions, fix that repo first.
- If a Homebrew cask is stale relative to the remote tap or vendor source, update `homebrew-cask`, `homebrew-core`, and `homebrew-bundle` through `nixos-config` locks, then build and switch.
- If a tool auto-updates itself outside Nix, record the live version in the report but still make the declarative tap/input update so the next machine rebuild converges.
- If unrelated dirty tracked files block a clean commit or apply, do not invent guardrails in scripts. Separate deploy-affecting changes from scratch/progress files and ask the user when ownership is unclear.

## Reporting

Report four things: package repo health, consumer lock changes, local installed versions, and whether the committed state was built and switched. Call out any package that could not be verified or installed.
