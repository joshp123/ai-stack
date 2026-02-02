# Openclaw wiring checklist (private repo)

Use this as a quick wiring guide when importing ai‑stack into a private repo.

## Required (build should fail without these)

- `programs.openclaw.instances.prod.config.channels.telegram.tokenFile`
- `programs.openclaw.instances.prod.config.channels.telegram.allowFrom`
- `programs.openclaw.instances.test.config.channels.telegram.tokenFile`
- `programs.openclaw.instances.test.config.channels.telegram.allowFrom`
- Anthropic credentials (one of):
  - `ANTHROPIC_API_KEY` in the gateway environment, or
  - `~/.openclaw-<instance>/.env` containing `ANTHROPIC_API_KEY=...`
- Plugin secret files referenced in `programs.openclaw.instances.*.plugins`:
  - `/run/agenix/padel-auth`
  - `/run/agenix/picnic-auth`

## Recommended

- Per-group overrides (PII):
  - `programs.openclaw.instances.prod.config.channels.telegram.groups`
  - `programs.openclaw.instances.test.config.channels.telegram.groups`
- Local plugin overrides for fast dev:
  - Add a `plugins` entry with `source = "path:/..."` (last wins on name)

## Optional

- Shared defaults can live under `programs.openclaw.config` and be overridden per instance via
  `programs.openclaw.instances.<name>.config`.
