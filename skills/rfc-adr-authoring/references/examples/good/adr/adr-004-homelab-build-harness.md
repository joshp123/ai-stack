# ADR 004: Homelab Build/Deploy Harness

- **Status:** Proposed
- **Date:** 2025-11-19
- **Decision Makers:** Josh (homelab owner), Codex (agent)
- **Context:** We need a repeatable way to build every homelab service (Home Assistant, Prometheus, Grafana, etc.) from the flake, decide what actually needs rebuilding based on recent changes, and deploy to multiple environments over time (local Docker on macOS today, potentially Linux hosts, Synology NAS, or “fat” bundled images later). The workflow must be LLM-first: agents should interact through deterministic commands rather than ad-hoc shell scripts, and the system must eventually treat “service + state” as a migratable unit so we can move workloads (and their data) between hosts.

## Decision

Create a registry-driven harness and LLM-friendly apps instead of bespoke shell scripts:

1. **Target registry (new module):** Central attrset describing each homelab service. For every target we record:
   - Build derivations keyed by `system` (e.g., `packages.${system}.homelab-ha-oci`).
   - Change-detection hints (files/directories that imply a rebuild).
   - Deployment metadata (container names, images, future systemd/NAS data).
   - State bundle info (paths to persist, reauth expectations, backup/restore guidance).

2. **Nix apps for planning/building:** Add flake apps (e.g., `homelab-plan`, `homelab-build`, `homelab-ha-build`) that consult the registry to:
   - Detect the host architecture and choose the appropriate Linux build target automatically (with overrides like `NIX_HA_TARGET` for CI).
   - Produce machine-readable plans listing which services need rebuild/deploy based on change hints or explicit input.
   - Run the relevant `nix build` invocations and surface the resulting tarballs/artifacts without ad-hoc scripts.

3. **State-aware design:** Encode how each service handles long-lived data so migrations stay predictable.
   - Prefer declarative configuration + agenix secrets; only copy runtime data when it cannot be recomputed (e.g., Prometheus TSDB, Grafana DB).
   - Document whether tokens should be reissued on startup or preserved (HA integrations, etc.).
   - Keep downtime budget (~<1 minute) in mind for rsync/tar workflows.

This design keeps today’s scope modest (just document + scaffold the harness) while making it easy to extend into deployers that can copy state bundles, push to new hosts, or write backups to NAS/S3 later.

## Consequences

- **Benefits**
  - Single source of truth for builds/deploys/state, so future automation doesn’t duplicate knowledge.
  - LLM agents get deterministic commands (`nix run .#homelab-plan`, `nix run .#homelab-ha-build`) that already know which architecture to target.
  - Prep work for multi-host migrations without prematurely building every deployment path.

- **Costs / Deferred Work**
  - Need to implement the registry and apps before we retire existing ad-hoc commands.
  - Have to maintain change-hint lists per service (risk of stale mappings, but better than manual triage).
  - Actual deploy automation (Docker load/run helpers, systemd push, NAS snapshots, S3 backups) is deferred; today we’re only documenting the plan.

## Deferred Decisions

- **Deployment executors:** How we automate Docker load/run, systemd activation, or Synology distribution will be designed once the registry exists. The ADR keeps hooks for multiple deploy modes but does not implement them.
- **State snapshot storage:** Uploading state bundles to NAS/S3 (frequency, format, retention) will be specified later. For now we only define what needs to be captured.
- **State-handling helper:** A `homelab-state` CLI that can bundle/sync the declared directories (rsync, tar, remote copy) is deferred; operators should move state manually until that lands.
- **CI/build matrix:** Running both arches (or more) in CI, and integrating selective rebuild logic with git metadata, is future work.
- **LLM planner UX details:** Exact JSON schema/CLI options for `homelab-plan` will be finalized when we implement the tool.

## References

- Issue: nixos-config-homelab-js7
- Related docs: `docs/homelab/README.md`, existing ADRs on Prometheus labels and HA auth bootstrap.
