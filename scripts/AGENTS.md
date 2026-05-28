# scripts/

Small helper scripts called by Nix/Home Manager.

Each script here should explain why it exists because these files otherwise look
like random glue from `tree`.

| Script | Why it exists |
| --- | --- |
| `build-openclaw-documents.sh` | Derivation helper that copies public OpenClaw workspace docs and composes upstream `AGENTS.md` with `documents/AGENTS.josh.md`. |
| `build-openclaw-documents-derivation.sh` | Nix derivation builder wrapper for `build-openclaw-documents.sh`; keeps the `runCommand` body out of Nix. |
| `cass-indexer.sh` | launchd/systemd target that builds the cass index if missing, then runs watch mode without interactive update prompts. |
| `build-glimpse-host.sh` | Home Manager activation helper for `pi-diff-review`; it builds the bundled `glimpseui` host binary into the user cache when the packaged source changes. |
| `pi-coding-agent-settings.sh` | Home Manager activation hook that keeps `~/.pi/agent/settings.json` valid while removing obsolete upstream example extension paths. |
| `pi-diff-review-glimpse-activation.sh` | Home Manager activation wrapper that invokes `build-glimpse-host.sh` with Nix-provided paths. |

Keep scripts boring: explicit args, no network, no secrets in output, and no
hidden operator workflow. If a script becomes reusable product behavior, move it
to the owning package repo.
