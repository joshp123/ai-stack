{ config, lib, ... }:
{
  # Public, generic OpenClaw defaults.
  # Bot-specific roles (DJTBOT, etc.) live in `modules/bots/*`.

  options.programs.openclaw.pluginSourcesOverride = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    description = "Override plugin sources by name (e.g. local dev paths).";
  };

  config = lib.mkIf (lib.hasAttrByPath [ "programs" "openclaw" ] config) {
    programs.openclaw = {
      # Default: headless installs don’t ship the macOS app.
      installApp = lib.mkDefault false;

      # Keep oracle available by default (skill/tooling); safe, no secrets.
      # NOTE: we intentionally use the legacy option name `firstParty` here because
      # ai-stack may be consumed with older nix-openclaw pins.
      firstParty.oracle.enable = lib.mkDefault true;

      # Minimal shared config; instances are defined by role modules.
      config.gateway.mode = lib.mkDefault "local";
    };
  };
}
