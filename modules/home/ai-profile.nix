# Fixed pointers from the home into the AI profile. The profile is installed and
# updated by update-ai-tools (modules/darwin/update-ai-tools.nix); nothing here
# changes when the tools do, so a tool update never needs a Home Manager switch.
#
# App-owned files are edited only when the app writes strict JSON and merges:
# pi's settings.json and auth.json, Claude Code's ~/.claude.json. Each edit
# merges a few keys and leaves the rest to the app (ai-profile/merge-json.sh).
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.ai-profile;
  home = config.home.homeDirectory;
  link = path: config.lib.file.mkOutOfStoreSymlink "${cfg.profile}/${path}";
  jq = "${pkgs.jq}/bin/jq";
  merge = file: policy:
    "${pkgs.bash}/bin/bash ${lib.escapeShellArgs [ "${./ai-profile/merge-json.sh}" file jq "${policy}" ]}";

  piSettings = (pkgs.formats.json { }).generate "pi-settings-policy.json" {
    packages = map (name: "${cfg.profile}/share/pi/packages/${name}") [
      "pi-web-search"
      "pi-agent-browser-native"
    ];
    enabledModels = cfg.enabledModels;
    extensions = [ ];
  };
in
{
  options.programs.ai-profile = {
    enable = lib.mkEnableOption "pointers into the AI profile";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.local/state/nix/profiles/ai";
      description = "The Nix profile that update-ai-tools installs the AI bundle into.";
    };

    enabledModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "openai-codex/gpt-5.6-*"
        "anthropic/claude-fable-*"
        "anthropic/claude-opus-*"
        "ollama/*"
      ];
      description = "Model globs pi offers; pi warns when a glob matches nothing.";
    };

    anthropicApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        File holding a long-lived Claude token (`claude setup-token`). When set,
        it becomes pi's Anthropic api_key entry in auth.json.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionPath = [ "${cfg.profile}/bin" ];

    home.file = {
      ".pi/agent/extensions".source = link "share/pi/extensions";
      ".pi/agent/skills".source = link "share/pi/skills";
      ".claude/skills".source = link "share/claude/skills";
      ".claude/CLAUDE.md".source = link "share/claude/CLAUDE.md";
      ".config/ai/rules.md".source = link "share/ai/rules.md";
      ".config/ai/models.md".source = link "share/ai/models.md";
      # cua-driver reads this; telemetry off.
      ".cua/config.toml".source = ./ai-profile/cua-config.toml;
    };

    home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ]
      (merge "${home}/.pi/agent/settings.json" piSettings);

    # Claude Code's user-scope MCP servers live in ~/.claude.json and nowhere
    # declarative; this adds the cua-computer-use entry the same way.
    home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ]
      (merge "${home}/.claude.json" ./ai-profile/claude-mcp-servers.json);

    home.activation.piAnthropicAuth = lib.mkIf (cfg.anthropicApiKeyFile != null)
      (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.bash}/bin/bash ${./ai-profile/install-pi-anthropic-auth.sh} \
          "${home}/.pi/agent/auth.json" "${jq}" "${cfg.anthropicApiKeyFile}"
      '');
  };
}
