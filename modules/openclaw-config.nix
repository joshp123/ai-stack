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

      # Minimal shared config; instances are defined by role modules.
      config.gateway.mode = lib.mkDefault "local";
    };
  };
}
