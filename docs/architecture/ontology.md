# ai-stack Ontology

This repo should be understandable from `tree` before reading implementation.

## Contract

`ai-stack` is a public Home Manager/doc layer for AI tools. It is intentionally
not a complete deployable system.

| Path | Owns | Does not own |
| --- | --- | --- |
| `modules/` | public Home Manager modules and defaults | host topology, secrets, final service enablement |
| `docs/agents/` | global agent guidance deployed by consumers | private runbooks and host facts |
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
| Provider-side cloud resources | `~/code/opentofu-infra` |

## OpenClaw

The OpenClaw bot profiles (`modules/bots/`, `modules/openclaw-*.nix`,
`documents/`) were removed in October 2026; git history has them.
