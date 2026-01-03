# RFC: Homelab Vision - Declarative Home Infrastructure

**Date:** 2025-11-22 (Revised: 2025-11-23)
**Status:** APPROVED
**Author:** Josh Palmer

---

## Executive Summary

Transform homelab infrastructure from manual configuration to fully declarative NixOS-managed system. Enable zero-clickops deployment, version-controlled configuration, and reproducible rebuilds across all home automation, monitoring, and media services.

**Core Principle**: Everything is code, nothing requires UI interaction.

---

## Problem Statement

**Current State:**
- Home Assistant integrations require manual UI configuration
- Services configured through web interfaces (clickops)
- Credentials scattered across untracked files
- No version control for service state
- Rebuilding containers loses configuration
- No single source of truth

**Pain Points:**
1. **Manual Configuration**: Each service requires clickops through web UI
2. **State Loss**: Container rebuilds lose integration state
3. **No Audit Trail**: Configuration changes untracked
4. **Secret Sprawl**: Credentials in multiple locations, unencrypted
5. **Non-Reproducible**: Cannot rebuild homelab from git repo alone

---

## Goals

### Primary Goals

1. **Declarative Configuration**
   - All service config in Nix (version controlled)
   - Credentials in agenix (encrypted secrets)
   - Single rebuild command deploys entire stack

2. **Zero Clickops**
   - No manual web UI configuration required
   - OAuth/API key flows documented, one-time only
   - Rebuilds reproduce full state

3. **Single Source of Truth**
   - Service definitions in one place
   - Secrets managed centrally (agenix)
   - Configuration conflicts impossible

### Secondary Goals

4. **Easy Access**
   - Reverse proxy with TLS (*.home.example.com)
   - Service directory for convenience
   - Consistent access patterns

5. **Maintainability**
   - Follow KISS principle (simplest that works)
   - Follow YAGNI principle (no premature features)
   - Clear separation of concerns

---

## Non-Goals

**Explicitly Out of Scope:**

1. **Authentication/Authorization** (YAGNI)
   - Network is LAN-only (trusted)
   - Add auth later if needed
   - Not adding complexity prematurely

2. **High Availability** (YAGNI)
   - Single homelab server sufficient
   - Not building distributed system
   - Accept downtime during rebuilds

3. **Service Health Monitoring** (YAGNI)
   - Services either work or don't
   - Add monitoring if actually needed
   - Not building observability platform yet

4. **Migration from Existing Setups**
   - Fresh homelab deployment
   - Document one-time credential extraction only
   - Not building migration tooling

5. **External Access**
   - LAN-only access sufficient
   - Remote access deferred to future RFC

---

## Architecture Overview

### Four Workstreams

**WS-A: HA Foundations (Credential Management)**
- Declarative Home Assistant integration credentials
- systemd LoadCredential + custom HA component
- OAuth token extraction and management
- See: `rfc-2025-11-23-homeassistant-credentials.md`

**WS-B: HA Integrations (Cloud Services)**
- **Credentials only** - zones/devices discovered from cloud APIs
- Tado (HVAC, OAuth refresh token)
- Daikin (HVAC, username/password, forked component)
- Roborock (vacuum, cloud API token)
- UNii (radiator valves, local API key)
- P1 meter (energy, DSMR protocol discovery)
- Meaco (dehumidifier, LocalTuya credentials)
- Growatt (solar, API key + Grott)

**WS-C: Access Layer (Reverse Proxy + Directory)**
- Caddy reverse proxy (*.home.example.com)
- Wildcard TLS via Route53 DNS-01
- Static service directory (terminal-sys.css design)
- Service registry (single source of truth)
- **No authentication yet** (YAGNI, LAN-only)

**WS-E: Media Stack (Automation)**
- Sonarr, Radarr, Prowlarr, qBittorrent
- **Minimal configuration** (defaults + credentials only)
- Preserve existing torrent seeding
- API keys in agenix (never hardcoded)

---

## Design Principles

### 1. KISS (Keep It Simple, Stupid)

**What This Means:**
- Use defaults where possible
- Don't configure what's already default
- Prefer standard tools over custom solutions
- Avoid abstraction layers

**Examples:**
- NixOS modules: Just `enable = true` (ports/users/dirs automatic)
- Service directory: Static HTML, not Flask server
- Credentials: systemd LoadCredential, not custom placeholder library

### 2. YAGNI (You Aren't Gonna Need It)

**What This Means:**
- Don't build features "just in case"
- Don't add complexity for hypothetical future
- Build only what's needed now

**Examples:**
- No authentication (LAN-only is sufficient)
- No health checks (services work or they don't)
- No migration tooling (fresh deployment)
- No service discovery beyond static registry

### 3. Single Source of Truth

**What This Means:**
- Define each thing once
- Import/reference from single definition
- Configuration conflicts impossible by design

**Examples:**
- Service registry: Used by Caddy AND directory generator
- Secrets: agenix only, never duplicated
- Integration credentials: Nix config only

### 4. Declarative > Imperative

**What This Means:**
- Describe desired state, not steps
- Let Nix/systemd handle orchestration
- Rebuilds are idempotent

**Examples:**
- Nix config declares services enabled
- systemd delivers credentials automatically
- HA discovers devices from credentials

---

## High-Level Flow

### Initial Deployment

```
1. User clones nixos-config repo
2. User adds credentials to agenix:
   - Home Assistant OAuth tokens (one-time extraction)
   - Media stack API keys (BTN, PTP)
   - Service credentials (Daikin, etc.)
3. User runs homelab rebuild command (TBD: keep flake entrypoints minimal)
4. System deploys:
   - Caddy with TLS certs
   - Home Assistant with integrations configured
   - Media stack services
   - Service directory
5. User accesses: https://home.example.com
```

### Rebuild Flow

```
1. User modifies Nix config (add integration, change setting)
2. User commits changes to git
3. User runs homelab rebuild
4. System:
   - Rebuilds changed services
   - Updates Caddy config
   - Regenerates service directory
   - Restarts affected containers
5. Changes live, config tracked in git
```

### Credential Update Flow

```
1. User updates secret: agenix -e ha-tado-refresh.age
2. User rebuilds homelab
3. System:
   - Decrypts new secret to /run/agenix/
   - Systemd delivers to HA
   - HA uses new credentials
   - No manual OAuth flow needed (refresh token valid)
```

---

## User Stories

### Story 1: Device Integration Without UI

**As a user**, I want to enable my Tado thermostats by editing a Nix file, so that I never need to click through the Home Assistant UI.

**Scenario**:
```nix
# modules/homelab/home-assistant/integrations.nix
homeAssistant.integrations.tado = {
  credentials.refreshToken = config.age.secrets.ha-tado-refresh.path;
  # Optional non-default setting
  fallbackMode = "TADO_DEFAULT";
};
```

**Result**: After rebuild, Tado integration:
- Authenticates with refresh token
- Discovers zones from cloud API (Living Room, Master Bedroom, Office)
- Discovers devices automatically (thermostats, sensors)
- Creates entities in Home Assistant (no manual configuration)

**Note**: Zones NOT configured in Nix - HA discovers them dynamically from Tado cloud API.

### Story 2: Professional Service Directory

**As a user**, I want a professional-looking directory page, so that I can easily access homelab services.

**Scenario**: Navigate to `https://home.example.com`

**Result**: See a clean, professional directory page with:
- Home Assistant at `ha.home.example.com`
- Grafana at `grafana.home.example.com`
- Sonarr at `sonarr.home.example.com`
- All with proper TLS certificates
- Terminal/neon aesthetic (matching website design)
- Static HTML (no JavaScript required)

### Story 3: Media Management That Works

**As a user**, I want automated media management, so that my library is organized and torrents don't crash.

**Scenario**: Request a TV show in Sonarr

**Result**:
- Prowlarr finds the torrent on BTN
- qBittorrent downloads to configured location
- Sonarr organizes to media library
- Existing torrents continue seeding
- No crashes, no manual intervention

---

## Success Criteria

### Must Have (MVP)

1. **Zero Clickops HA Setup**
   - [ ] All integrations configured in Nix
   - [ ] OAuth tokens extracted once, reused forever
   - [ ] Rebuild reproduces HA state

2. **Declarative Service Config**
   - [ ] All services enabled via Nix
   - [ ] No web UI configuration required
   - [ ] Credentials in agenix only

3. **Single Access Point**
   - [ ] Caddy reverse proxy working
   - [ ] TLS certificates automatic
   - [ ] Service directory functional

### Should Have (Polish)

4. **Documentation**
   - [ ] OAuth token extraction guide
   - [ ] Per-integration setup docs
   - [ ] Rollback procedure

5. **Testing**
   - [ ] Rebuild is idempotent
   - [ ] Credentials injected correctly
   - [ ] Services survive restart

### Nice to Have (Future)

6. **Automation**
   - [ ] Token rotation automation
   - [ ] Health check dashboards
   - [ ] Backup/restore procedures

---

## Implementation Strategy

### Phase 1: Foundation (Weeks 1-2)
**Goal**: Validate WS-A credential injection

- Build minimal custom HA component
- Test with UNii integration (simplest, no OAuth)
- Validate systemd LoadCredential delivery
- Document OAuth token extraction

**Deliverables**:
- Working credential injection for UNii
- OAuth extraction guide
- POC validation complete

### Phase 2: Integrations (Weeks 2-3)
**Goal**: Migrate all HA integrations to declarative

- Migrate Daikin (local, forked component)
- Migrate Tado (OAuth, complex)
- Add Roborock, P1 meter, Meaco, Growatt

**Deliverables**:
- All 7 integrations declarative
- Zones/devices discovered automatically
- No manual UI configuration required

### Phase 3: Access Layer (Week 3)
**Goal**: Professional access with TLS

- Deploy Caddy reverse proxy
- Generate static service directory
- Configure wildcard TLS via Route53

**Deliverables**:
- All services behind *.home.example.com
- Service directory with terminal-sys.css design
- Automatic TLS certificate renewal

### Phase 4: Media Stack (Week 4)
**Goal**: Automated media management

- Enable Sonarr, Radarr, Prowlarr, qBittorrent
- Configure download clients (minimal config)
- Add indexer API keys (with warnings)
- Validate seeding preservation

**Deliverables**:
- Working *arr stack
- Existing torrents still seeding
- API keys in agenix

### Phase 5: Validation (Week 4)
**Goal**: Prove rebuild works

- Test full rebuild from scratch
- Verify all services functional
- Document rollback procedures
- Final cleanup

**Deliverables**:
- Rebuild under 10 minutes
- All integrations working
- Rollback documented

---

## Risks and Mitigations

### High Risk

**Risk 1: HA Credential Injection Fails**
- **Impact:** WS-A blocks everything
- **Mitigation:** POC validates approach before full implementation
- **Fallback:** Manual HA config, document for future declarative migration

**Risk 2: OAuth Tokens Expire**
- **Impact:** Integrations stop working
- **Mitigation:** Document token rotation procedure, set calendar reminders
- **Monitoring:** Log HA auth failures

### Medium Risk

**Risk 3: HA Version Upgrades Break Custom Component**
- **Impact:** Rebuild fails after HA upgrade
- **Mitigation:** Pin HA version, test upgrades in staging
- **Monitoring:** Check HA release notes for breaking changes

**Risk 4: Media Stack Migration Breaks Seeding**
- **Impact:** Lose ratio on private trackers
- **Mitigation:** Test migration procedure, backup qBittorrent state
- **Validation:** Verify torrents still seeding post-migration

### Low Risk

**Risk 5: Caddy TLS Renewal Fails**
- **Impact:** HTTPS access broken
- **Mitigation:** Test DNS-01 challenge, monitor cert expiry
- **Fallback:** Manual cert renewal via certbot

---

## Dependencies

### External Dependencies

1. **Route53 DNS** - Wildcard TLS DNS-01 challenge
2. **OAuth Providers** - Tado, Roborock cloud APIs
3. **Private Trackers** - BTN, PTP API access

### Internal Dependencies

1. **WS-B depends on WS-A** - Credentials must work before integrations
2. **WS-C independent** - Can build in parallel
3. **WS-E independent** - Can build in parallel

### Toolchain Dependencies

1. **Nix/NixOS** - System configuration
2. **agenix** - Secret management
3. **Docker** - Home Assistant containerization (from PR #37)
4. **systemd** - Service management, credential delivery

---

## Open Questions

1. **HA Custom Component Lifecycle**
   - Oracle consultation in progress (see `rfc-2025-11-23-homeassistant-credentials.md`)
   - Need to validate event timing and mutation safety

2. **Long-Term Token Validity**
   - How long do Tado/Roborock refresh tokens last?
   - What happens on expiry?
   - Document renewal procedure

3. **Daikin Fork Maintenance**
   - Current fork: Forked Daikin component in submodule
   - Upstream merge strategy?
   - Long-term maintenance plan?

4. **Homelab Rebuild Command**
   - What should the rebuild command be?
   - Keep flake entrypoints minimal (not `.#build-switch` which is for macOS)
   - Suggestion: `.#homelab-build` or separate script?

---

## Complete Device Coverage

All devices to be integrated:

| Device | Integration Method | Credential Type | Discovery |
|--------|-------------------|-----------------|-----------|
| Tado Thermostats | OAuth + Custom Component | Refresh token | Cloud API |
| Daikin AC Units | Forked Component | Username/password | Cloud API |
| UNii Radiator Valves | Custom Component + API | API key | Local |
| P1 Energy Meter | DSMR Protocol | None | Local discovery |
| Roborock Vacuum | Cloud API | OAuth token | Cloud API |
| Meaco Dehumidifier | LocalTuya | Shared key | Local |
| Growatt Inverter | API + Grott | API key | API endpoint |

**Note**: Hikvision cameras deferred to future Frigate RFC.

---

## Infrastructure Standards

### Domain Structure
```
*.home.example.com
├── home.example.com             # Service directory
├── ha.home.example.com          # Home Assistant
├── grafana.home.example.com     # Grafana
├── prometheus.home.example.com  # Prometheus (if exposed)
├── sonarr.home.example.com      # Sonarr
├── radarr.home.example.com      # Radarr
├── prowlarr.home.example.com    # Prowlarr
└── qbittorrent.home.example.com # qBittorrent
```

### Security Requirements
- **TLS Everywhere**: All services behind HTTPS (Route53 wildcard cert)
- **LAN Only**: No external exposure (Caddy binds to internal IPs only)
- **No Authentication Yet**: YAGNI - add later if needed
- **Secrets Management**: All credentials in agenix

---

## References

- **Synthesis Findings:** `docs/architecture/synthesis-findings.md`
- **WS-A RFC:** `rfc-2025-11-23-homeassistant-credentials.md`
- **PR #37:** Current homelab harness implementation
- **PR #40:** ADR-20251119-home-assistant-nix.md (alternative approach analysis)
- **HA Source:** `~/code/research/homelab/src/core/homeassistant/`
- **NixOS Source:** `~/code/research/nixpkgs/nixos/modules/services/`
- **Website Design:** `~/code/website/assets/css/terminal-sys.css`

---

## Approval

**Approved By:** Josh Palmer
**Date:** 2025-11-22 (Revised: 2025-11-23)
**Next Steps:** Implement WS-A POC (see `rfc-2025-11-23-homeassistant-credentials.md`)
