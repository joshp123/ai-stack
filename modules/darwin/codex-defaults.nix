# Codex's admin config layer, /etc/codex. ~/.codex stays Codex-owned and
# writable; the defaults and the skills live here, in the system generation, so
# they change only on a switch. The one tool path, dash-mcp-server, is a fixed
# path in the AI tools profile, so it never changes when the tools update.
{ mkContent }:
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.codex-defaults;

  defaults = {
    model = "gpt-5.5";
    model_reasoning_effort = "xhigh";
    tool_output_token_limit = 25000;
    model_auto_compact_token_limit = 233000;
    web_search = "live";
    features = {
      multi_agent = true;
      unified_exec = true;
      shell_snapshot = true;
    };
    profiles.fast.features.fast_mode = true;
    notice = {
      hide_full_access_warning = true;
      hide_rate_limit_model_nudge = true;
    };
    mcp_servers = {
      dash = {
        command = "${cfg.profile}/bin/dash-mcp-server";
        args = [ ];
      };
      sosumi = {
        type = "http";
        url = "https://sosumi.ai/mcp";
      };
    };
  };

  configToml = (pkgs.formats.toml { }).generate "codex-config.toml"
    (lib.recursiveUpdate defaults cfg.settings);

  content = mkContent { inherit pkgs; inherit (cfg) profile; };
in
{
  options.programs.codex-defaults = {
    enable = lib.mkEnableOption "Codex defaults and skills under /etc/codex";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${config.system.primaryUser}/.local/state/nix/profiles/ai";
      description = "The AI tools profile that holds dash-mcp-server.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Overrides merged over the shipped config.toml defaults.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc = {
      "codex/config.toml".source = configToml;
      "codex/skills".source = content.codexSkills;
    };
  };
}
