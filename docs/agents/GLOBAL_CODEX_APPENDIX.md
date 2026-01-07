---

# Codex Guidance

## Codex Rules

**Trusted repo defaults (don’t hedge):** In trusted `~/code/...` paths, Codex starts with `model=gpt-5.2-codex`, `model_reasoning_effort=high`, `approval_policy=never`, `sandbox_mode=danger-full-access` (network on), search tool enabled, and `tool_output_token_limit=25000`. Assume you can edit and reach the network without approvals unless the user says otherwise; if uncertain, glance at `~/.codex/config.toml` or `/status` instead of speculating.

1. **Default access**  
   - In trusted `~/code/...` paths, Codex starts with approvals disabled and no sandbox (`approval_policy=never`, `sandbox_mode=danger-full-access` with network enabled). No approval prompts; still ask before `sudo` or rebuild commands.

2. **Commits & PRs**  
   - Commit message format: `🤖 codex: short description (issue-id)` keeps history greppable.  
   - Open PRs with the GitHub CLI (`gh pr create`); prefer CLI over UI so the workflow stays reproducible and scriptable.

3. **PR narratives**  
  - Before drafting the PR, walk every commit (`git log --reverse origin/main..HEAD`) and restate how each change advances the issue/ticket. Capture migrations, reversals, and any risky surprises a reviewer must know.  
   - Start the PR body with a 3–4 bullet “Summary” explaining what shipped, why the user wanted it, the problems it solves, and the operator impact.  
   - Follow with “Details” subsections grouped by subsystem (modules, tooling, docs, CI). For each, describe the motivation, the implementation, and notable tradeoffs (patches, vendoring, state moves, secrets handling).  
   - Close with explicit testing + follow-up bullets (commands run, environments, deferred validation). Flag outstanding operator actions instead of leaving reviewers to infer them.

4. **Codex config hygiene**  
   - `~/.codex/config.toml` is managed by Nix (see `modules/darwin/files.nix`). Change Nix, not the file, when adjusting models, trust lists, or MCP wiring.
   - If Codex reports missing MCP servers after a rebuild, run `darwin-rebuild switch --flake .#aarch64-darwin` (sudo) and restart Codex.

5. **Trusted projects**  
   - Trusted roots are managed in Nix under `modules/darwin/files.nix` (`projects = [...]`). Add paths there and rebuild; Codex will regenerate `~/.codex/config.toml`.

## MCP usage philosophy

- The default Codex profile stays lean: only the Dash MCP server (local docs) and SOSUMI (hosted Apple docs) are registered up front. Avoid adding heavyweight build/deploy MCPs globally—run them on demand via `mcporter` so the session loads only what it needs.


## URL handling

If the user provides a URL, use it directly. Don’t web-search for something already specified. Use the most sensible retrieval tool for the URL type:
- GitHub file/link: `gh` (preferred) or `git` if multiple files are needed
- Direct/raw file: `curl -L` or `wget`

State the command and URL you used so the user can verify the source.

### XcodeBuildMCP (opt-in via CLI)

When you need the Apple build automation toolchain, use `mcporter` instead of editing `~/.codex/config.toml`:

```bash
# Run XcodeBuildMCP via mcporter (loads full workflow set)
mcporter call build.run target:path/to.xcodeproj
```

- Example (local project):  
  `mcporter call build.run target:~/code/notes/projects/buienradar/Buienradar.xcodeproj scheme:Buienradar`

- Leave `XCODEBUILDMCP_DYNAMIC_TOOLS=true` only if you need tool sampling (defaults stay `false` for stability).
- Because Codex doesn’t auto-register this MCP, remember to summarize CLI results back into the conversation (copy/paste tool output as needed).

SOSUMI (Apple doc mirror) remains enabled in every Codex session—no extra steps required.
