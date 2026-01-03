# ADR-002: Remote/Hybrid Home Assistant Stack (DRAFT)

## Status
DRAFT — pending decisions on hosting, VPN, and device constraints.

## Context
Goal: run Home Assistant (HA) and observability 24/7 on a remote host while keeping a local Docker setup for development. Media-heavy *arr workloads should stay local on the NAS; some devices may require Bluetooth/local transports. Buying a local server is also under consideration as an alternative to a VPS.

## Proposed architecture (draft)
- **Source of truth**: Keep flake + Docker helpers; local dev uses the same images as remote.
- **Runtime split**: VPS (or future local server) runs HA + Prometheus + Grafana; local LAN runs *arr stack tied to the NAS.
- **Network fabric**: Mesh VPN (WireGuard/Tailscale) connecting VPS, laptop, and home LAN; restrict public exposure (proxy with mTLS/OIDC if needed).
- **Device access**: For Bluetooth/lan-only devices, keep a “home gateway” (HA Bluetooth proxy/Zigbee hub) on LAN reachable over VPN; if this is infeasible, HA may need to remain on-prem.
- **Storage**: VPS uses bound volumes for HA config, Prom TSDB, Grafana data; NAS holds *arr data. Backups flow to NAS and/or object storage.
- **Deploy workflow**: Local test → merge → build images → push/copy to VPS → restart containers with pinned digests. Use a small gitops script/flake app for “up”.

## Key open questions
1) **Host choice/size**: Which provider (AWS/DO/Hetzner/etc.) or local server? CPU/RAM/disk needs; static IP requirement.
2) **HA placement vs Bluetooth**: Is cloud HA viable with VPN-accessible proxies, or should HA stay on-prem and only ship metrics/logs?
3) **VPN**: WireGuard vs Tailscale/Headscale; need subnet routing to NAS and device gateways?
4) **Ingress/identity**: Public HTTPS vs VPN-only; do we front HA/Grafana with OIDC/mTLS?
5) **Media pathing**: Can *arr remain fully on-prem (preferred)? If remote control is needed, how do we expose NAS (NFS/SMB) and what bandwidth is acceptable?
6) **Backups**: Target (NAS vs object storage), cadence, retention.
7) **Orchestration**: Stay with Nix + dockerTools, or add a compose bundle/systemd units for VPS?
8) **Registry**: Push to ECR/GHCR vs load via skopeo; any egress/cost constraints?
9) **Observability scope**: Just HA metrics, or also host/system metrics from home via VPN?
10) **Availability/patching**: Acceptable downtime and update strategy on VPS/local server.

## Next steps
- Decide on host (VPS vs local server) and VPN choice.
- Confirm HA placement given Bluetooth/device constraints.
- Pick ingress policy (public + auth vs VPN-only).
- Prototype the deploy script/flake app and a minimal compose/systemd layout once decisions are set.
