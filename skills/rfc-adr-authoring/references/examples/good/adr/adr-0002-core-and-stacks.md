# ADR 0002: Core + Stacks Architecture

## Title
- **Status:** Accepted
- **Date:** 2025-12-23
- **Decision Makers:** Josh (owner), Codex (agent)
- **Context:** The repo is growing quickly, especially around AI tooling that updates daily. Global overlays and shared modules made it hard to isolate fast-moving pieces without impacting build time or cache stability. We also want to open-source the AI tooling stack later, and prepare a homelab stack without disturbing the macOS deploy.

## Decision
Adopt a **Core + Stacks** architecture:

- **Core** stays in `modules/shared/**` and contains stable, cross-platform configuration (shell, editor, base CLI tooling, fonts).
- **Stacks** live under `stacks/<name>/` and own fast-moving or domain-specific bundles (AI tooling now; homelab later).
- **AI stack** is self-contained under `stacks/ai/` with its own HM fragments, overlays, generated pins, and update scripts.
- **Overlays are split**:
  - Core overlays: `overlays/core/` (cache-safe, slow-changing)
  - AI overlays: `stacks/ai/overlays/` (fast-moving tooling, pnpm/bun/uv builds)

## Why this structure
- **Build-time containment:** AI overlays no longer affect core builds unless the AI stack is imported.
- **Extraction-ready:** `stacks/ai` can be moved into its own repo/flake later with minimal rewrites.
- **Update cadence:** Daily updates are isolated to `stacks/ai/generated` and `stacks/ai/scripts`.
- **Homelab prep:** `stacks/homelab` can be added without destabilizing macOS.

## Consequences
- Hosts now explicitly import stacks: `../../stacks/ai/modules`.
- AI update scripts and generated pins move from top-level `scripts/` and `generated/` into `stacks/ai/`.
- Documentation and agent guidance must reference the new paths.

## Non-goals
- No binary cache for now (local builds only).
- No behavioral changes to the current macOS deploy.
- No dev-shell-first workflow; tools remain globally available via Nix.

## Follow-ups
- Add a homelab stack skeleton under `stacks/homelab/` when ready.
- Consider a public AI stack repo once paths/secrets are clean.

## References
- `docs/architecture/overview.md`
- `stacks/ai/`
- `overlays/core/`
