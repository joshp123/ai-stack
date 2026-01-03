{ pkgs, ... }:

let
  codexConfigFormat = pkgs.formats.toml { };

  codexConfig = {
    model = "gpt-5.2-codex";
    model_reasoning_effort = "medium";
    approval_policy = "never";
    sandbox_mode = "danger-full-access";
    tool_output_token_limit = 25000;
    model_auto_compact_token_limit = 233000;

    features = {
      web_search_request = true;
      unified_exec = true;
      apply_patch_freeform = true;
      shell_snapshot = true;
    };

    notice = {
      hide_full_access_warning = true;
    };

    mcp_servers = {
      dash = {
        command = "${pkgs.dash-mcp-server}/bin/dash-mcp-server";
        args = [ ];
      };
      sosumi = {
        type = "http";
        url = "https://sosumi.ai/mcp";
      };
    };
  };
in
{
  home.file.".codex/config.toml".source =
    codexConfigFormat.generate "codex-config.toml" codexConfig;
  home.file.".codex/config.toml".force = true;
}
