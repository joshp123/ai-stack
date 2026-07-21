# modules/

Public Home Manager module layer.

## Boundary

- `ai-stack.nix`: main public module, global agent docs and skills. It must not import OpenClaw.
- `openclaw-config.nix`: generic OpenClaw defaults only.
- `openclaw-documents.nix`: OpenClaw workspace documents, imported only by OpenClaw profiles.
- `bots/`: transitional DJTBOT/OpenClaw role profiles consumed by private config.
- `darwin/`: public macOS Homebrew defaults only.

No secrets, hostnames, allowlists, private paths, or deploy topology belong
here. Put private host choices in `nixos-config`; put reusable OpenClaw package,
service, lifecycle, and plugin-tool behavior in `nix-openclaw` or
`nix-openclaw-tools`.

Do not add inline shell scripts to Nix modules. Put shell in `scripts/` or the
nearest role directory and import it with `builtins.readFile`.
