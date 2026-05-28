# modules/bots/

Transitional OpenClaw/DJTBOT profiles.

These modules are still imported by `nixos-config`, but they are not the target
architecture. The private topology is being reconciled separately in the
consumer repo and live host state.

## Rules

- Keep these profiles public and no-secret.
- Do not add new host topology or provider infra here.
- Do not grow new lifecycle APIs here; reusable OpenClaw install/service
  behavior belongs in `nix-openclaw`.
- Do not add new plugin package ownership here. Plugin packages belong in
  `nix-openclaw-tools` or another package repo, then this layer can enable the
  exported surface.

After the replacement/decommission pass, either delete these profiles or rename
them in one coordinated consumer update.
