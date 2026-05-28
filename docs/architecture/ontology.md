# ai-stack Ontology

This repo should be understandable from `tree` before reading implementation.

## Contract

`ai-stack` is a public Home Manager/doc layer for AI tools. It is intentionally
not a complete deployable system.

| Path | Owns | Does not own |
| --- | --- | --- |
| `modules/` | public Home Manager modules and defaults | host topology, secrets, final service enablement |
| `modules/bots/` | transitional OpenClaw role profiles still consumed by private repos | named current hosts, new host architecture, or long-term gateway ownership |
| `docs/agents/` | global agent guidance deployed by consumers | private runbooks and host facts |
| `documents/` | OpenClaw workspace documents that are safe to publish | live runtime state or credentials |
| `skills/` | shareable custom skills | built-in Codex skills or private workflows |
| `extensions/` | pi coding-agent extension source | packaged AI CLI tools |
| `config/` | public shell/app config | private dotfiles or machine-specific overrides |
| `scripts/` | small helper scripts invoked by Nix/Home Manager | hidden business logic or ad-hoc operator commands |
| `overlays/` | narrow overlays for this public module layer | fast-moving tool packages |

## External Owners

| Thing | Owner |
| --- | --- |
| Live host topology, deploy commands, agenix paths | `nixos-config` |
| Generic AI CLI packages | `nix-ai-tools` |
| OpenClaw package, module behavior, reusable lifecycle | `nix-openclaw` |
| OpenClaw-adjacent plugin/tool packages | `nix-openclaw-tools`, consumed through `nix-openclaw` |
| OpenClaw product code | `~/code/openclaw` |
| Provider-side cloud resources | `~/code/opentofu-infra` |

## Current Transition

The `modules/bots/djtbot-*` profiles are active compatibility surfaces, not the
target architecture. They exist because private consumers still import them
while OpenClaw gateway ownership is being reconciled outside this repo.

Do not add new topology decisions to those profiles. If behavior is reusable,
move it into `nix-openclaw`; if it is a private host choice, put it in
`nixos-config`.

## Historical Names

OpenClaw lineage: `warelay` -> `clawdis` -> `clawdbot` -> `moltbot` ->
`openclaw`.

Do not introduce new `moltbot` names. Existing references should either be
historical documentation or stateful deployed-resource names with an explicit
migration plan.
