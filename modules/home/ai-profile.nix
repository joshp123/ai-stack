# The AI setup in the home, from the system generation: PATH into the AI tools
# profile, and the authored files (content/) as Home Manager links, so skills,
# prompts and pi extensions change only on a switch. The profile itself is
# installed and updated by update-ai-tools (modules/darwin/update-ai-tools.nix);
# the few package-owned files inside content/ are links to fixed profile paths,
# so a tools update never needs a switch either.
#
# App-owned files are edited only when the app writes strict JSON and merges:
# pi's settings.json and auth.json, Claude Code's ~/.claude.json. Each edit
# merges a few keys and leaves the rest to the app (ai-profile/merge-json.sh).
{ mkContent }:
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.ai-profile;
  home = config.home.homeDirectory;
  content = mkContent {
    inherit pkgs;
    inherit (cfg) profile extraClaudeSkills piCollections piExtensions;
  };
  jq = "${pkgs.jq}/bin/jq";
  merge = file: policy:
    "${pkgs.bash}/bin/bash ${lib.escapeShellArgs [ "${./ai-profile/merge-json.sh}" file jq "${policy}" ]}";

  piSettings = (pkgs.formats.json { }).generate "pi-settings-policy.json" {
    packages = map (name: "${cfg.profile}/share/pi/packages/${name}") [
      "pi-web-search"
      "pi-agent-browser-native"
    ];
    enabledModels = cfg.enabledModels;
    defaultProvider = cfg.defaultProvider;
    defaultModel = cfg.defaultModel;
    extensions = [ ];
  };
in
{
  options.programs.ai-profile = {
    enable = lib.mkEnableOption "the AI setup in the home: PATH into the AI tools profile and the authored files";

    profile = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.local/state/nix/profiles/ai";
      description = "The Nix profile that update-ai-tools installs the AI tools bundle into.";
    };

    extraClaudeSkills = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Directories of extra Claude Code skills, one skill per subdirectory.";
    };

    piCollections = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      example = lib.literalExpression ''[ { name = "apple/xcode-27"; collection = ./COLLECTION.md; skills = ./skills; } ]'';
      description = "Extra pi skill collections: a COLLECTION.md and a directory of skills each.";
    };

    piExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      example = lib.literalExpression ''[ { name = "foo.ts"; path = ./foo.ts; } ]'';
      description = "Extra pi extensions.";
    };

    authoredPiExtensions = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = content.authoredPiExtensions;
      description = ''
        The written pi extensions this generation links (no package-owned ones).
        update-ai-tools loads them against a new pi before installing it.
      '';
    };

    enabledModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "openai-codex/gpt-6.1-*"
        "anthropic/claude-fable-*"
        "anthropic/claude-opus-*"
        "ollama/*"
      ];
      description = "Model globs pi offers; pi warns when a glob matches nothing.";
    };

    defaultProvider = lib.mkOption {
      type = lib.types.str;
      default = "openai-codex";
      description = "pi's default provider, re-applied on every switch.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "gpt-6.1-sol";
      description = ''
        pi's default model, re-applied on every switch. pi has no "latest" alias,
        so this is a pin; the nightly model check calls it and alerts when the
        model is retired or gated.
      '';
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
      ".pi/agent/extensions".source = content.piExtensions;
      ".pi/agent/skills".source = content.piSkills;
      ".claude/skills".source = content.claudeSkills;
      ".claude/CLAUDE.md".source = content.claudeMd;
      ".config/ai/rules.md".source = content.rulesMd;
      ".config/ai/models.md".source = content.modelsMd;
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
