# RFC: Lawbot‑Hub Cleanup for Unified Ops + UI Semantics

- Date: 2026-01-01
- Status: Draft
- Audience: Platform + backend + frontend engineers, agents, operator (CTO)

## 1) Narrative: what we are building and why

Lawbot‑Hub must be operationally boring and semantically consistent. Today we have:
1) mixed service lifecycles (manual processes vs devenv),
2) multiple UI shells with duplicated nav and inconsistent semantics,
3) submodule remnants that complicate ownership and codegen,
4) incomplete backend operational hygiene (health, status, logs, DB layout).

This RFC defines a cleanup pass that makes the stack **easy to boot, easy to reason about, and hard to drift**. It focuses on:
- operational excellence (single entrypoint, deterministic processes, status visibility),
- unified UI semantics (consistent labels, nav hierarchy, evidence affordances),
- backend clarity (data directories, health checks, codegen guardrails),
- submodule retirement strategy (no split‑brain ownership).

The goal is **not** new product functionality — it is reliability and coherence so we can safely ship evidence‑based legal outputs.

## 1.1) Non‑negotiables

- Protobuf‑first interfaces (no JSON on UI↔backend paths).
- ZFC‑compliant: no heuristic UI or backend routing.
- Minimal blast radius; phase changes in slices with proof of working software.
- No submodule edits unless explicitly requested; deprecations must be reversible.
- Go‑first for backend services.

## 2) Goals / Non‑goals

Goals:
- Single, canonical **operational entrypoint** for the full stack.
- Single, coherent **UI navigation model** with shared semantics across tools.
- Clear **backend process responsibilities** and data ownership.
- Explicit **submodule deprecation path** and ownership transfer.
- Deterministic **codegen and drift checks**.
- Operator‑visible **status page** that shows service health + data roots.

Non‑goals:
- New product features, re‑ranking logic, or ML/LLM changes.
- Visual redesign beyond shared navigation + semantic alignment.
- External auth/hosting (handled in a separate exposure RFC).

## 3) System overview

**Current state**
- Reverse proxy unifies `/vault`, `/orchestrator`, `/logicgraph`.
- Shared UI tokens/components exist; nav is shared but not semantically hierarchical.
- Submodules remain for `lawbot/` and `casepipe/` (logicgraph submodule removed).
- Manual process runs still required when `devenv` is flaky.

**Target state**
- One command starts/stops the full stack with health status.
- UI navigation mirrors mental model: Hub → Tool → Sub‑tool.
- Backend services expose consistent health/status endpoints and log format.
- Submodules are either removed or locked as read‑only snapshots.

## 4) Components and responsibilities

- **Hub Orchestrator (ops)**: system lifecycle, environment config, single URL.
- **Vault**: evidence store, ingestion pipelines, proto API.
- **Orchestrator**: workflow engine, evidence binding.
- **LogicGraph**: analysis + reports.
- **Shared UI**: nav, evidence components, layout primitives.
- **Codegen + CI**: proto drift checks, generated artifacts.

Ownership:
- Ops + shared UI + codegen: platform.
- Domain logic: each component owner.

## 5) Inputs / workflow profiles

Minimum inputs:
- Canonical DB locations in `~/.lawbot/...`
- Caddy reverse proxy config in repo
- `devenv` or equivalent process manager
- Root `proto/` as canonical source
- Environment config file (optional): `.env` with ports and data roots

Validation rules:
- Single URL serves all UIs.
- Health endpoints return OK for all services.
- UI nav resolves correctly for each tool and sub‑tool.
- Drift checks enforce proto single source.
- Status page shows version + data path per service.

## 6) Artifacts / outputs

- One operational profile (start/stop/status).
- Shared UI navigation semantics.
- Health/status endpoints for every backend.
- Clean proto/codegen policy.
- Submodule retirement plan.
- Hub status view (CLI or web) that summarizes service health.

## 7) State machine (if applicable)

Not applicable (operational cleanup + UI semantics).

## 8) API surface (protobuf)

No new protobuf messages in this RFC. Only operational/health endpoints and navigation semantics (UI).

## 9) Interaction model

- Operator runs single command to start/stop stack and view status.
- UI exposes tool navigation and current context (Hub → Tool → Sub‑tool).
- Evidence views remain consistent across tools.

### 9.1 UI semantics (explicit)

**Semantic layers**
1) **Hub level**: which tool am I in?
2) **Tool level**: what sub‑tool context am I in? (Vault: Threads/Docs/Events)
3) **Object level**: which evidence item is selected? (thread/doc/event)

**Rules**
- Hub level is always visible (top nav).
- Tool level appears only when it adds context.
- Object level is never shown in nav; it belongs in the detail pane header.
- Active state is derived strictly from URL path.
- Labels are canonical: “Vault”, “Orchestrator”, “LogicGraph”, “Threads”, “Docs”, “Events”.
- The Hub level never shows data counts; counts belong inside each tool’s list header.
- Sub‑tool level never shows statuses; statuses belong in the tool header (e.g., “Syncing…”).
- Never show more than two nav rows; use contextual links inside content for deeper hops.

### 9.2 UI affordances (must be consistent)

Evidence views must share:
- **Primary action** label (“Open in Vault”) and placement.
- **Provenance indicator** placement (right rail or card footer).
- **Timestamp formatting** (ISO date string in UTC or local with TZ suffix).
- **Empty state** copy (“No documents match the current filters.”).
- **Search field placement**: always in list panel, above filters.
- **Sort control placement**: list panel, below search, left‑aligned.
- **Detail header**: always shows title + timestamp + source on one row.

### 9.3 UI hierarchy (structure)

```
HubNav (top)
└── ToolNav (contextual)
    ├── Workspace Header (tool name + summary)
    └── Workspace Body
        ├── List Pane (left)
        └── Detail Pane (right)
```

### 9.4 Tool‑specific nav states (explicit)

**Vault**
- HubNav shows Vault active.
- ToolNav shows Threads / Docs / Events.
- URL mapping:
  - `/vault/threads` → Threads (default)
  - `/vault/docs` → Docs
  - `/vault/events` → Events
- When embedded selection mode is active, **HubNav and ToolNav are hidden** and a compact “Selection mode” banner is shown in the list header.

**Orchestrator**
- HubNav shows Orchestrator active.
- No ToolNav row.
- If evidence panel is open, show “Open in Vault” links that deep‑link to `/vault/...` with relevant IDs.

**LogicGraph**
- HubNav shows LogicGraph active.
- No ToolNav row.
- Evidence doc links (if present) must deep‑link to `/vault/docs?doc_uid=...`.

### 9.5 Edge cases + responsive rules

- **Small screens**: HubNav collapses into a single row with a “Tool” dropdown; ToolNav collapses into segmented chips.
- **Service down**: HubNav still renders; ToolNav shows “Unavailable” state with link to status view.
- **Unknown route**: highlight none; show “Unknown tool” banner and link to Hub status.
- **Embedded mode**: no HubNav/ToolNav; tool should still show consistent detail headers and evidence chips.

### 9.6 Copy + labels (canonical)

- Tool labels: “Vault”, “Orchestrator”, “LogicGraph”.
- Vault sub‑tool labels: “Threads”, “Docs”, “Events”.
- Empty states:
  - Threads: “No threads match the current filters.”
  - Docs: “No documents match the current filters.”
  - Events: “No events match the current filters.”
- Status labels: “Syncing…”, “Up to date”, “Needs attention”.

## 10) System interaction diagram

```
User -> Hub URL -> Reverse Proxy
Reverse Proxy -> Vault UI/API
Reverse Proxy -> Orchestrator UI/API
Reverse Proxy -> LogicGraph UI
```

### 10.1 Navigation routing map (explicit)

- `/vault/threads` → Vault Threads desk
- `/vault/docs` → Vault Docs desk
- `/vault/events` → Vault Events desk
- `/orchestrator/*` → Orchestrator UI
- `/logicgraph/*` → LogicGraph UI
- `/api/v3/*` → Vault API (protobuf‑only; `application/x-protobuf`)
- `/api/*` → Orchestrator API (protobuf‑only; `application/x-protobuf`)
- `/proto/*` → Proto file hosting (Vault)

## 11) API call flow (detailed)

1) User opens Hub URL.
2) Nav selects tool → tool UI loads.
3) Tool UI loads proto definitions from Vault `/proto`.
4) Tool UI fetches evidence via protobuf API endpoints.
5) Status view queries `/healthz` and `/readyz` for each service.

### 11.1 Hub status call flow

1) Hub status view loads.
2) Fetch `/healthz` from each service.
3) Fetch `/readyz` from each service.
4) Render summary + warnings if any service not ready.


## 12) Determinism and validation

- No implicit URL guessing; base paths must be explicit.
- Nav highlights active tool + sub‑tool deterministically from URL.
- Health endpoints are explicit (`/healthz`, `/readyz`) and return deterministic payloads.

### 12.1 Deterministic UI semantics

- All evidence chips and badges are driven by explicit fields, not derived inference.
- No “best guess” labels (e.g., “Probably medical”) without provenance.
- All UI sort defaults are explicitly stated in copy (e.g., “Newest first”).

### 12.2 Operational determinism

- Ports and data roots must be fixed via config (no random ports).
- `hubctl status` must read actual service state, not infer from logs.

## 13) Outputs and materialization

- Canonical operational documentation and status outputs.
- Shared nav semantics for all tools.
- Standardized evidence UI semantics (labels, timestamps, provenance placement).
- Hub status output in CLI and/or UI.

## 14) Testing philosophy and trust

- Start/stop smoke test for the full stack.
- UI smoke across `/vault`, `/orchestrator`, `/logicgraph`.
- Health endpoints return 200 OK with structured JSON (or textproto).
- Status view shows correct state after a service is stopped (e.g., vaultd down).

### 14.1 Required UI validation

- Nav highlights correct tool and sub‑tool based on URL.
- Vault tool sub‑nav is visible only in Vault contexts.
- Evidence list/detail layout is consistent across Vault and Orchestrator.

### 14.2 Required ops validation

- `hubctl up` exits 0 and leaves all services running.
- `hubctl status` reports all services with correct versions and data roots.
- `hubctl down` terminates all services cleanly.

## 15) Incremental delivery plan

1) **Ops baseline**: single start/stop/status command and health endpoints.
2) **Nav semantics**: HubNav that renders tool + sub‑tool navigation.
3) **Submodule policy**: freeze and document submodule state.
4) **Codegen hardening**: drift checks + CI enforcement.
5) **Backend hygiene**: logging, data paths, config normalization.
6) **Status view**: one screen or CLI output that lists service health + data roots.
7) **UI semantics polish**: align tool copy, empty states, timestamps.

## 16) Implementation order

1) Add `/healthz` + `/readyz` to each backend (vaultd, orchestrator, logicgraph).
2) Implement hub‑level status view (UI or CLI).
3) Adopt hierarchical nav semantics (Hub → Tool → Sub‑tool).
4) Tighten proto drift check allowlist (only root `proto/` + upstream snapshots).
5) Document and freeze submodules; plan deprecation timelines.
6) Add structured logging conventions and log location guidance.
7) Add a `hubctl` wrapper (or documented make target) for start/stop/status if `devenv` is unreliable.
8) Unify UI semantics across Vault/Orchestrator/LogicGraph per 9.1/9.2.

## 17) Backend improvements (recommended)

Operational hygiene:
- Standardize service flags: `--addr`, `--http-addr`, `--root`, `--data-dir`.
- Provide consistent `healthz` and `readyz` endpoints.
- Emit structured logs (JSON) with service + version.
- Add `--config` with explicit data roots and ports (no implicit defaults in production).

Data discipline:
- Single canonical data root: `~/.lawbot/`
- Vault: `~/.lawbot/corpora/lawbot-vault/`
- Orchestrator: `~/.lawbot/orchestrator/`
- LogicGraph: `~/.lawbot/logicgraph/`
- Logs: `~/.lawbot/logs/{service}.log`

Process control:
- A single “hub up/down/status” command (devenv or wrapper).
- Surface port conflicts with clear diagnostics.
- Fallback path if `devenv` is unavailable: `hubctl` shell wrapper that launches vaultd/orchestrator/caddy manually.

### 17.1 Backend hygiene checklist (must pass)

- Health endpoints return deterministic payloads.
- Logs include: timestamp, service, version, request_id.
- Data root created if missing (explicit permission checks).
- No writes outside data root except logs.

## 18) Submodule cleanup (recommended)

Current submodules:
- `casepipe/` (legacy)
- `lawbot/` (legacy)

Plan:
- Freeze submodules as read‑only snapshots.
- Mirror only required assets into monorepo.
- Remove submodule wiring once parity achieved.

### 18.1 Submodule freeze rules

- Submodules are read‑only; no changes merged unless explicitly approved.
- New development happens in monorepo equivalents only.
- Any submodule updates must be tagged and mirrored to `lawbot-vault/upstream/**` snapshots.

### 18.2 Parity checklist before removal

- All required protos copied into root `proto/`.
- All required UI assets migrated into shared libs.
- Equivalent Go services exist for legacy Python services.
- CI no longer depends on submodule paths.

### 18.3 Removal timeline

- Milestone A: freeze + snapshot (immediate).
- Milestone B: parity verified (target within cleanup sprint).
- Milestone C: remove submodules + update README/AGENTS.

## 19) Brutal self‑review (required)

Junior engineer:
- Resolved: `hubctl` wrapper is defined as the fallback command for start/stop/status, with ownership under platform.

Mid‑level engineer:
- Resolved: health endpoints must return deterministic payloads (`status`, `service`, `version`, `data_root`), and 200/503 codes only.

Senior/principal engineer:
- Resolved: explicit fallback via `hubctl` and required health/status validation steps.

PM:
- Resolved: success criteria include single URL, two‑level nav, and status view for system health.

EM:
- Resolved: submodule freeze is immediate; removal scheduled after parity check (target: first cleanup milestone).

External stakeholder:
- Resolved: shared nav + shared evidence components enforce identical rendering across tools; no per‑tool transforms.

End user:
- Resolved: nav highlights active tool and sub‑tool; hub status view confirms system state.

## 20) Operational appendix (explicit specs)

### 20.1 Health endpoint contract

All services expose:
- `GET /healthz` → 200 OK if process is alive
- `GET /readyz` → 200 OK if dependencies are ready, 503 if not

Payload (JSON or textproto with same fields):
```
service: "vaultd"
status: "ok" | "not_ready"
version: "git_sha"
data_root: "$HOME/.lawbot/corpora/lawbot-vault"
```

### 20.2 Hub status view

Status view must display:
- Service name
- Ready state
- Version
- Data root
- Last check time

### 20.3 Navigation success criteria

- Top‑level nav: Vault / Orchestrator / LogicGraph
- Sub‑nav appears only when it adds context (Vault: Threads/Docs/Events)
- Active state must match URL path (no inference)
