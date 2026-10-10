# Codex's admin config layer, /etc/codex. ~/.codex stays Codex-owned and
# writable; the defaults and the skills root live here and point at the AI
# profile, so they never change when the tools update. Codex follows the
# symlink chain /etc/codex/skills -> store link -> profile and canonicalises it
# once per session.
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

  skillsLink = pkgs.runCommandLocal "codex-skills-link" { } "ln -s ${cfg.profile}/share/codex/skills $out";
in
{
  options.programs.codex-defaults = {
    enable = lib.mkEnableOption "Codex defaults and skills under /etc/codex";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${config.system.primaryUser}/.local/state/nix/profiles/ai";
      description = "The AI profile that holds dash-mcp-server and share/codex/skills.";
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
      "codex/skills".source = skillsLink;
    };
  };
}
