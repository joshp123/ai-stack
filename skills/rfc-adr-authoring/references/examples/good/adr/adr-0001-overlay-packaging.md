# ADR 0001: Nix-Built Overlays for CLI/MCP Tooling

## Title
- **Status:** Proposed
- **Date:** 2025-12-21
- **Decision Makers:** Josh (owner), Codex (agent)
- **Context:** The repo previously used runtime wrappers (`npx`, `uvx`) that fetched and installed tools at execution time. This caused slow builds, network variability, and non-reproducible installs. We also saw dependency ballooning during `darwin-rebuild switch` because tool wrappers pulled in full dependency graphs outside the Nix store. We need deterministic, cached builds that still track upstream releases, while preferring modern package managers (bun/uv) only when upstream already uses them.

## Decision
We will Nix-build overlay tools from their upstream sources and locks, avoiding runtime `npx`/`uvx` installs.

- **Rule of thumb**
  - If upstream ships **bun.lock** → use **bun2nix**.
  - If upstream ships **pnpm-lock.yaml** → use **pnpm fetch** + `pnpm` build.
  - If upstream ships **package-lock.json** → use **buildNpmPackage**.
  - For Python tools, use nixpkgs Python packages or `buildPythonApplication` against upstream `pyproject.toml`.
  - Prefer **prebuilt release artifacts** only when they are the upstream-supported distribution (e.g., Peekaboo CLI).

- **Scope**
  - Replace wrappers for: ccusage, pi-coding-agent, oracle-cli, mcporter, dash-mcp-server, edge-tts, xcodebuildmcp, peekaboo-mcp.
  - Keep locks and hashes pinned; add update workflows rather than runtime installers.

- **Non-goals**
  - We do **not** invent new lockfiles (no bun/uv lock generation for npm/pip projects).
  - We do **not** rely on runtime downloads during tool execution.

## Consequences
- **Positive**
  - Deterministic builds with Nix caching.
  - Faster `darwin-rebuild` once hashes are set.
  - Clear provenance for tool binaries.
  - Aligns with “no clickops” and fully declarative config.

- **Risks / Follow-ups**
  - Hash updates are required when upstream changes; we need update scripts or a documented “refresh” workflow.
  - Some tools still require heavy build chains (e.g., Rust for prefetch-npm-deps); caching mitigates this after first build.
  - Peekaboo MCP requires the CLI binary path to be set explicitly.

- **Impact on workflows**
  - Developers must run update scripts (or `nix flake update` + hash refresh) instead of relying on `npx/uvx`.
  - Overlay definitions become the single source of truth for tool versions.

## References
- `stacks/ai/overlays/*.nix` (new Nix-built tool definitions)
- `docs/architecture/adr-template.md`
