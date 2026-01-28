# Moltbot wiring checklist (private repo)

Use this as a quick wiring guide when importing ai‑stack into a private repo.

## Required (build should fail without these)

- `programs.moltbot.instances.prod.providers.telegram.botTokenFile`
- `programs.moltbot.instances.prod.providers.telegram.allowFrom`
- `programs.moltbot.instances.test.providers.telegram.botTokenFile`
- `programs.moltbot.instances.test.providers.telegram.allowFrom`
- `programs.moltbot.instances.prod.providers.anthropic.apiKeyFile`
- `programs.moltbot.instances.test.providers.anthropic.apiKeyFile`
- Plugin secret files referenced in `programs.moltbot.instances.*.plugins`:
  - `/run/agenix/padel-auth`
  - `/run/agenix/picnic-auth`

## Recommended

- Per-group overrides (PII):
  - `programs.moltbot.instances.prod.providers.telegram.groups`
  - `programs.moltbot.instances.test.providers.telegram.groups`
- Local plugin overrides for fast dev:
  - Add a `plugins` entry with `source = "path:/..."` (last wins on name)

## Optional

- Extra config beyond the typed options can be placed under:
  - `programs.moltbot.instances.<name>.configOverrides`
