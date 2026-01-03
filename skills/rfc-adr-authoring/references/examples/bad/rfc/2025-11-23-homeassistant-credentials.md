# RFC: Home Assistant Declarative Configuration via ConfigEntry Creation

**Date:** 2025-11-23 (Revised after critical analysis)
**Status:** DRAFT - Ready for POC Implementation
**Scope:** WS-A Foundation - Credential Management Only

---

## Problem Statement

**Current State:**
- Home Assistant integrations require manual OAuth/API key flows via UI
- Credentials stored in `.storage/core.config_entries` (untracked, plain JSON)
- Rebuilding HA container loses integration configuration
- No declarative, version-controlled credential management

**Desired State:**
```nix
# Simple declarative credential config
homeAssistant.integrations.tado = {
  credentials.refreshToken = config.age.secrets.ha-tado-refresh.path;
};
```

**User Goal:**
- Zero clickops for HA integration setup
- All credentials in agenix (version controlled, encrypted)
- Rebuild HA and integrations "just work"

---

## Proposed Solution

### Three-Layer Architecture

**Layer 1: Nix Configuration (User Interface)**
```nix
# modules/homelab/home-assistant/default.nix
services.home-assistant = {
  config = {
    nixos_integrations = {
      tado = {
        title = "Tado Heating";
        data = {
          # Optional non-credential fields
          # fallbackMode = "TADO_DEFAULT";
        };
      };

      daikin = {
        title = "Daikin AC";
        data = {
          host = "192.168.1.100";
          @Claude why do we need host entries here? (both for daikin and the other components)
        };
      };

      unii = {
        title = "UNii Radiator Valves";
        data = {
          host = "192.168.1.101";
        };
      };
    };
  };
};
```

**Layer 2: Systemd Integration (Secret Delivery)**
```nix
# Separate from Layer 1 config
systemd.services.home-assistant.serviceConfig.LoadCredential = [
  "tado.refreshToken:${config.age.secrets.ha-tado-refresh.path}"
  "daikin.username:${config.age.secrets.ha-daikin-user.path}"
  "daikin.password:${config.age.secrets.ha-daikin-pass.path}"
  "unii.apiKey:${config.age.secrets.ha-unii-key.path}"
];
```

**Layer 3: HA Custom Component (ConfigEntry Creation)**
```python
# .custom_components/nixos_integrations/__init__.py

@Claude can we declaratively vendor this? Ideal situation is initially just having this in our nixos repo under the homelab tree; later we can put it as a separate git repo that we vendor in.

from homeassistant.config_entries import ConfigEntry, SOURCE_USER
from homeassistant.const import CONF_HOST, CONF_USERNAME, CONF_PASSWORD
import os
from pathlib import Path
import logging

DOMAIN = "nixos_integrations"
_LOGGER = logging.getLogger(__name__)

async def async_setup(hass: HomeAssistant, config: dict) -> bool:
    """Set up NixOS integration credential provider."""

    # STEP 1: Load credentials from systemd LoadCredential
    creds_dir = os.getenv("CREDENTIALS_DIRECTORY")
    if not creds_dir:
        _LOGGER.warning("No systemd credentials directory found")
        return True

    credentials = {}
    for cred_file in Path(creds_dir).glob("*.*"):
        # Format: <domain>.<field> (e.g., "tado.refreshToken")
        parts = cred_file.name.split(".", 1)
        if len(parts) != 2:
            continue

        domain, field = parts
        if domain not in credentials:
            credentials[domain] = {}

        credentials[domain][field] = cred_file.read_text().strip()

    _LOGGER.info(f"Loaded NixOS credentials for: {list(credentials.keys())}")

    # STEP 2: Read NixOS integration configuration
    nixos_integrations = config.get(DOMAIN, {})

    # STEP 3: Create ConfigEntry objects programmatically
    for domain, integration_config in nixos_integrations.items():
        # Build entry data (merge config + credentials)
        entry_data = dict(integration_config.get("data", {}))

        # Inject credentials
        if domain in credentials:
            for field, value in credentials[domain].items():
                entry_data[field] = value
            _LOGGER.info(f"Injected credentials for {domain}: {list(credentials[domain].keys())}")

        # Create ConfigEntry
        entry = ConfigEntry(
            data=entry_data,
            domain=domain,
            title=integration_config.get("title", domain.capitalize()),
            source=SOURCE_USER,
            version=1,
            minor_version=0,
        )

        # Add to HA (triggers async_setup_entry)
        try:
            await hass.config_entries.async_add(entry)
            _LOGGER.info(f"Created config entry for {domain}")
        except Exception as exc:
            _LOGGER.error(f"Failed to create config entry for {domain}: {exc}")

    return True
```

@Claude we also need unit tests and type hints (mypy should enforce this)

**Why This Works:**
- **Direct Creation**: Uses HA's native `ConfigEntry()` constructor and `async_add()` API
- **No Event Hooks**: No dependency on event timing or mutation safety concerns
- **Standard Pattern**: Same pattern used by HA's UI config flows and discovery integrations
- **Zero Clickops**: ConfigEntry objects created from Nix config at HA startup
- **Automatic Setup**: `async_add()` both registers entry AND triggers `async_setup_entry()` automatically
- **Persistence**: Credentials persist to `.storage/core.config_entries` (acceptable - file has 600 permissions)

**Key Difference from Oracle Suggestion:** @Claude we don't need these details to perist in our plan. just add a section about rejected approaches or something
- Oracle recommended `runtime_data` which requires forking all 7 integrations
- This approach works with stock integrations (Tado, Daikin, Roborock, etc.)
- Meets "1-2 lines per integration" user requirement
- KISS/YAGNI - minimal code, no hooks, no events

**Nix Configuration Interface:**
```nix
# modules/homelab/home-assistant/default.nix
{ config, lib, pkgs, ... }:

{
  config = {
    services.home-assistant = {
      customComponents = [
        # Custom component that reads nixos_integrations config
        nixos-integrations-component
      ];

      config = {
        nixos_integrations = {
          tado = {
            title = "Tado Heating";
            data = {
              # Non-credential fields if needed
              # fallbackMode = "TADO_DEFAULT";
            };
          };

          daikin = {
            title = "Daikin AC";
            data = {
              host = "192.168.1.100";
            };
          };

          unii = {
            title = "UNii Radiator Valves";
            data = {
              host = "192.168.1.101";
            };
          };
        };
      };
    };

    # Systemd credential delivery (Layer 2)
    @Claude I would prefer that the credentials 
    systemd.services.home-assistant.serviceConfig.LoadCredential = [
      "tado.refreshToken:${config.age.secrets.ha-tado-refresh.path}"
      "daikin.username:${config.age.secrets.ha-daikin-user.path}"
      "daikin.password:${config.age.secrets.ha-daikin-pass.path}"
      "unii.apiKey:${config.age.secrets.ha-unii-key.path}"
    ];
  };
}
```

---

## OAuth Browser Flow Handling

### The OAuth Challenge

OAuth integrations (Tado, Daikin, Roborock) require browser-based authentication:

```
HA redirects → OAuth provider → User authenticates in browser
→ Provider redirects back → HA exchanges code for tokens
→ HA stores refresh token in .storage
```

**Question:** How do we get the initial refresh token declaratively?

### Proposed Solution: One-Time Bootstrap

**Phase 1: Initial Token Acquisition (Semi-Automated)**
1. User performs OAuth flow in HA UI (standard browser authentication)
2. HA stores `refresh_token` in `.storage/core.config_entries`
3. **Claude (LLM) automates extraction and encryption:**
   ```bash
   # Extract refresh token from HA storage
   TOKEN=$(jq -r '.data.entries[] | select(.domain == "tado") | .data.refresh_token' \
     /var/lib/home-assistant/.storage/core.config_entries)

   # Create agenix secret file
   echo "$TOKEN" | agenix -e secrets/ha-tado-refresh.age

   # Verify secret was created
   ls -l secrets/ha-tado-refresh.age
   ```
4. **Claude deletes integration via HA API** (clean slate for declarative management):
   ```bash
   # Get HA config entry ID
   ENTRY_ID=$(jq -r '.data.entries[] | select(.domain == "tado") | .entry_id' \
     /var/lib/home-assistant/.storage/core.config_entries)

   # Delete integration via API
   curl -X DELETE \
     -H "Authorization: Bearer $HA_TOKEN" \
     -H "Content-Type: application/json" \
     "http://localhost:8123/api/config/config_entries/entry/$ENTRY_ID"
   ```

**User's Role:** Only perform step 1 (browser OAuth flow). Claude automates steps 3-4.

**Phase 2: Declarative Management (Fully Automated by Claude)**
1. **Claude adds integration to Nix config:**
   - Edits `modules/homelab/home-assistant/integrations/tado.nix`
   - Adds agenix secret reference
   - Configures credential injection
   ```nix
   age.secrets.ha-tado-refresh.file = ./secrets/ha-tado-refresh.age;

   homeAssistant.integrations.tado.credentials.refreshToken =
     config.age.secrets.ha-tado-refresh.path;
   ```
2. **Claude commits changes:** `git add secrets/ modules/homelab/` → commit with 🤖 prefix
3. **Claude prompts user to rebuild:** User runs homelab rebuild command (TBD: `.#homelab-build` or similar, NOT `.#build-switch` which is macOS-specific)
4. **System automatically handles the rest:**
   - Systemd delivers refresh token to HA via `LoadCredential`
   - Custom component injects token into ConfigEntry
   - HA uses refresh token to obtain new access tokens (no browser needed)
5. **Subsequent rebuilds/restarts:** Token automatically injected, no user intervention

**User's Role:** Only step 3 (approve rebuild command). All Nix config changes automated by Claude.

**Why This Works:**
- OAuth refresh tokens are designed for this purpose
- Once you have a refresh token, you can get new access tokens indefinitely
- No browser interaction needed after initial OAuth flow
- Refresh tokens typically expire after months/years (if at all)

**Alternative for Advanced Users:**
Create a standalone OAuth token extractor tool (future enhancement):
```bash
nix run .#ha-oauth-extract tado
# Opens browser, does OAuth flow, outputs refresh token
# User pipes directly to agenix
```

---

## POC Validation Plan

### Phase 1: Minimal Custom Component (Week 1)

**Goal:** Prove ConfigEntry creation works

**Steps:**
1. Create minimal `.custom_components/nixos_integrations/`:
   ```
   nixos_integrations/
   ├── __init__.py          # ConfigEntry creation logic
   └── manifest.json        # Component metadata
   ```

2. **Test with Daikin integration** (known working, username/password flow, no OAuth complications):
   - Hardcode test config in `configuration.yaml`:
     ```yaml
     nixos_integrations:
       daikin:
         title: "Daikin AC Units"
         data:
           host: "192.168.1.100"
     ```
   - Hardcode credentials in systemd `LoadCredential`:
     ```
     daikin.username
     daikin.password
     ```
   - Verify ConfigEntry created at HA startup
   - Validate Daikin integration authenticates and discovers devices

3. Validate behavior:
   - Does `ConfigEntry()` constructor accept our parameters?
   - Does `async_add()` trigger `async_setup_entry()` automatically?
   - Does HA restart preserve ConfigEntry in `.storage`?
   - Can we read `entry.data` in Daikin's `async_setup_entry()`?

**Why Daikin (not UNii or Tado):**
- Known to be working in production
- Simple username/password flow (no OAuth refresh token complexity)
- Forked component already exists (proven integration)
- Easier to debug than Tado's OAuth flow

**Success Criteria:**
- [ ] Custom component loads without errors
- [ ] ConfigEntry created programmatically
- [ ] Daikin integration authenticates successfully
- [ ] HA discovers AC units automatically
- [ ] HA restart maintains working state
- [ ] `.storage/core.config_entries` contains created entry

### Phase 2: Systemd Integration (Week 1)

**Goal:** Prove systemd credential delivery works

**Steps:**
1. Create NixOS module for `homeAssistant.integrations`:
   ```nix
   # modules/homelab/home-assistant/integrations.nix
   options.homeAssistant.integrations = mkOption {
     type = types.attrsOf (types.submodule {
       options.credentials = mkOption { ... };
     });
   };
   ```

2. Generate systemd `LoadCredential` from config
3. Test with agenix-encrypted secrets
4. Verify `$CREDENTIALS_DIRECTORY` accessible in HA container

**Success Criteria:**
- [ ] Nix config compiles
- [ ] Systemd delivers credentials to HA
- [ ] Custom component reads from `$CREDENTIALS_DIRECTORY`
- [ ] End-to-end: Nix secret → systemd → HA → integration

### Phase 3: OAuth Integration (Week 2)

**Goal:** Prove OAuth refresh token workflow

**Steps:**
1. Manual OAuth flow in HA UI (Tado integration)
2. Extract refresh token from `.storage/core.config_entries`:
   ```bash
   jq '.data.entries[] | select(.domain == "tado") | .data.refresh_token' \
     /var/lib/home-assistant/.storage/core.config_entries
   ```
3. Encrypt with agenix:
   ```bash
   agenix -e secrets/ha-tado-refresh.age
   # Paste the refresh token, save
   ```
4. Delete Tado integration from HA UI (clean slate)
5. Add Nix config with agenix secret:
   ```nix
   nixos_integrations.tado = {
     title = "Tado Heating";
     data = {}; # No non-credential data needed
   };

   systemd.services.home-assistant.serviceConfig.LoadCredential = [
     "tado.refreshToken:${config.age.secrets.ha-tado-refresh.path}"
   ];
   ```
6. Rebuild, verify ConfigEntry created with refresh token
7. Test HA restart (does ConfigEntry persist?)

**Success Criteria:**
- [ ] Extracted refresh token successfully
- [ ] Agenix encryption/decryption works
- [ ] ConfigEntry created with refresh token
- [ ] Tado integration discovers zones/devices correctly
- [ ] HA restart maintains ConfigEntry in `.storage`
- [ ] No manual UI configuration required

### Phase 4: Multi-Integration Test (Week 2)

**Goal:** Prove approach scales to multiple integrations

**Steps:**
1. Add Daikin (username/password, local API):
   ```nix
   nixos_integrations.daikin = {
     title = "Daikin AC";
     data = { host = "192.168.1.100"; };
   };
   # LoadCredential: daikin.username, daikin.password
   ```

2. Add Roborock (device token, cloud API):
   ```nix
   nixos_integrations.roborock = {
     title = "Roborock Vacuum";
     data = {};
   };
   # LoadCredential: roborock.token
   ```

3. Verify no credential conflicts (tado/daikin/roborock/unii)
4. Test all four ConfigEntries created at startup
5. Validate each integration sets up correctly

**Success Criteria:**
- [ ] All four integrations configured declaratively
- [ ] No credential cross-contamination
- [ ] Each ConfigEntry has correct domain/title/data
- [ ] All integrations survive HA restart
- [ ] Rebuild is idempotent

---

## Uncertainties to Validate

### High Priority (Blocks POC)

1. **ConfigEntry Creation:**
   - **Question:** Does `ConfigEntry()` constructor accept our parameters correctly?
   - **Validation:** Test with UNii integration, verify entry created
   - **Known:** From HA source (lines 1684-1695), constructor accepts data/domain/title/source/version

2. **Automatic Setup Trigger:**
   - **Question:** Does `async_add(entry)` trigger `async_setup_entry()` automatically?
   - **Validation:** Check HA source code (line 2101), test with UNii
   - **Known:** Yes, `async_add()` calls `await self.async_setup(entry.entry_id)`

3. **ConfigEntry Persistence:**
   - **Question:** Do programmatically created ConfigEntry objects persist to `.storage`?
   - **Validation:** Create entry, restart HA, check if entry still present
   - **Acceptable:** Yes, credentials persist to `.storage/core.config_entries` (file has 600 permissions)

### Medium Priority (Refinements)

4. **Credential Field Naming:**
   - **Question:** How do we map `refreshToken` (Nix) to `CONF_REFRESH_TOKEN` (HA)?
   - **Validation:** Check HA integration sources for field name conventions
   - **Options:** Convention-based mapping vs. explicit per-integration config

5. **OAuth Token Expiry:**
   - **Question:** What happens when refresh token expires?
   - **Validation:** Check Tado/Roborock documentation for token lifetimes
   - **Mitigation:** Document token rotation procedure

6. **Container Environment:**
   - **Question:** Does `$CREDENTIALS_DIRECTORY` work in Docker containers?
   - **Validation:** Test with current Docker-based HA setup
   - **Fallback:** Volume mount credentials directory

### Low Priority (Future Enhancements)

7. **Initial Configuration UI:**
   - **Question:** Can we trigger OAuth flow programmatically for first-time setup?
   - **Research:** HA config flow API, headless browser automation
   - **Defer:** Manual bootstrap sufficient for POC

8. **Multi-User Scenarios:**
   - **Question:** How do we handle multiple Tado accounts (e.g., different homes)?
   - **Solution:** Namespace in Nix config (e.g., `tado-home`, `tado-office`)
   - **Defer:** Single account sufficient for POC

---

## Success Criteria

### MVP (Minimum Viable Product)
- [ ] User writes 1-2 lines of Nix config per integration
- [ ] Credentials stored in agenix (encrypted, version controlled)
- [ ] HA rebuild reproduces integration state
- [ ] OAuth refresh tokens work without browser re-auth
- [ ] Custom component <100 lines of Python

### Nice-to-Have (Future)
- [ ] Automated OAuth token extraction tool
- [ ] Token rotation automation
- [ ] Multi-account support per integration
- [ ] Validation of credential field names at Nix eval time

---

## Out of Scope

**Not Included in This RFC:**
- Integration-specific configuration beyond credentials (covered in WS-B)
- Service discovery/reverse proxy (covered in WS-C)
- HA installation/Docker setup (exists in PR #37)
- Backup/restore procedures (future RFC)
- Multi-instance HA setups (future RFC)

**Explicitly Deferred:**
- Migration from existing HA setups (our setup is new)
- Handling expired refresh tokens (document manual rotation)
- Integration health monitoring (future enhancement)
- Automated OAuth flows (manual bootstrap sufficient)

---

## Implementation Timeline

### Week 1: Foundation
- **Days 1-2:** Create minimal custom component, test with hardcoded credentials
- **Days 3-4:** Build NixOS module for `homeAssistant.integrations`
- **Day 5:** End-to-end test with agenix secret (UNii integration)

### Week 2: OAuth Validation
- **Days 1-2:** Manual Tado OAuth flow, token extraction, Nix config
- **Days 3-4:** Test Daikin (username/password) and Roborock (OAuth)
- **Day 5:** Oracle consultation, refine based on feedback

### Week 3: Refinement
- **Days 1-2:** Address oracle findings, fix any issues
- **Days 3-4:** Document bootstrap procedure, create helper scripts
- **Day 5:** Final validation, update main RFCs

---

## Risk Assessment

### High Risk
1. **ConfigEntry creation API might change in future HA versions**
   - Mitigation: Use stable public API (`ConfigEntry()` constructor, `async_add()`)
   - Monitoring: Check HA release notes for ConfigEntry API changes
   - Fallback: Pin HA version if breaking changes occur

2. **OAuth refresh tokens might not work as expected**
   - Mitigation: Validate with Tado in POC Phase 3
   - Fallback: Document manual re-auth procedure

### Medium Risk
3. **HA version upgrades might break custom component**
   - Mitigation: Pin HA version, test upgrades carefully
   - Monitoring: Check HA breaking changes in release notes

4. **Systemd credentials might not work in Docker**
   - Mitigation: Test in POC Phase 2
   - Fallback: Volume mount credentials directory

### Low Risk
5. **Credential field name mismatches**
   - Mitigation: Validate per-integration in POC
   - Workaround: Explicit mapping in Nix config

---

## References

### Home Assistant Documentation
- **HA Config Entries API:** `~/code/research/homelab/src/core/homeassistant/config_entries.py` (lines 1684-1695: ConfigEntry constructor; line 2101: async_add)
- **HA Tado Integration:** `~/code/research/homelab/src/core/homeassistant/components/tado/` (OAuth refresh token pattern)
- **HA Daikin Integration:** `~/code/research/homelab/src/core/homeassistant/components/daikin/` (username/password pattern)
- **HA Custom Components Guide:** https://developers.home-assistant.io/docs/creating_component_index/
- **HA Config Flow:** https://developers.home-assistant.io/docs/config_entries_config_flow_handler/

### NixOS & systemd
- **systemd LoadCredential:** https://www.freedesktop.org/software/systemd/man/systemd.exec.html#LoadCredential=
- **agenix Documentation:** https://github.com/ryantm/agenix
- **NixOS Manual - systemd Services:** https://nixos.org/manual/nixos/stable/#sect-systemd
- **Oracle on NixOS Secrets:** Pattern C (systemd LoadCredential with converters) - conversation from previous session

### Project Documentation
- **Vision RFC:** `rfc-2025-11-22-homelab-vision.md` (overall goals and architecture)
- **Implementation Plan:** `rfc-2025-11-22-homelab-implementation-plan.md` (workstream coordination)
- **WS-B Integrations:** `rfc-2025-11-23-homeassistant-integrations.md` (per-integration details)
- **WS-C Access Layer:** `rfc-2025-11-23-caddy-reverse-proxy.md` (reverse proxy setup)
- **WS-E Media Stack:** `rfc-2025-11-23-media-automation.md` (media automation)
- **Architectural Proposal:** `docs/architecture/ha-credential-architecture-proposal.md` (early design exploration)
- **Synthesis Findings:** `docs/architecture/synthesis-findings.md` (research summary)

### Related Code
- **PR #37:** Current homelab harness (Docker-based HA setup)
- **PR #40:** ADR-20251119-home-assistant-nix.md (alternative approach analysis)
- **Forked Daikin Component:** Git submodule (custom HA component for Daikin AC)

---

## Appendix A: ConfigEntry Lifecycle (from HA Source)

```python
# homeassistant/config_entries.py

class ConfigEntry:
    """Hold a configuration entry."""

    def __init__(
        self,
        *,
        data: Mapping[str, Any],  # <-- Credentials stored here
        domain: str,
        entry_id: str,
        # ... other fields
    ) -> None:
        self.data = MappingProxyType(data)  # Immutable view
        # ...

    # Lifecycle methods
    async def async_setup(self, hass: HomeAssistant) -> bool:
        """Set up an entry."""
        # 1. Fires setup events
        hass.bus.async_fire(f"{EVENT_COMPONENT_LOADED}_{self.domain}")

        # 2. Calls integration's async_setup_entry
        component = integration.get_component()
        result = await component.async_setup_entry(hass, self)

        return result

# Integration access pattern (tado/__init__.py)
async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    """Set up Tado from a config entry."""

    # Access credentials from entry.data
    refresh_token = entry.data[CONF_REFRESH_TOKEN]  # <-- Our injection target

    # Use credentials
    tado = Tado(saved_refresh_token=refresh_token)
    # ...
```

---

## Appendix B: ConfigEntry Creation Pseudocode

```python
# High-level flow of our custom component

async def async_setup(hass, config):
    # 1. Load credentials from systemd LoadCredential
    credentials = load_from_credentials_directory()
    # Example: {"tado": {"refreshToken": "abc123"}}

    # 2. Read NixOS integration configuration
    nixos_integrations = config.get(DOMAIN, {})
    # Example: {"tado": {"title": "Tado Heating", "data": {}}}

    # 3. Create ConfigEntry objects programmatically
    for domain, integration_config in nixos_integrations.items():
        # Build entry data (merge config + credentials)
        entry_data = {
            **integration_config.get("data", {}),
            **credentials.get(domain, {})
        }

        # Create ConfigEntry
        entry = ConfigEntry(
            data=entry_data,
            domain=domain,
            title=integration_config["title"],
            source=SOURCE_USER,
            version=1,
        )

        # Add to HA (triggers async_setup_entry)
        await hass.config_entries.async_add(entry)

    return True
```

**Why This is Simpler:**
- No event hooks required
- No mutation concerns (`ConfigEntry` immutable after creation in this flow)
- Uses standard HA APIs (same as UI config flows)
- Credentials automatically persist to `.storage` via `async_add()`
