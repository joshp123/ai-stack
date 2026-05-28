{ config, lib, ... }:
{
  # Public, generic OpenClaw defaults.
  # Transitional bot-specific profiles (DJTBOT, etc.) live in `modules/bots/*`.
  # Host topology and reusable OpenClaw lifecycle behavior do not belong here.

  options.programs.openclaw.pluginSourcesOverride = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
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
