{
  config,
  pkgs,
  lib,
  ...
}:

let
  user = config.home.username or (builtins.getEnv "USER");
  homeDir = config.home.homeDirectory or "/home/${user}";
  settingsPath = "${homeDir}/.pi/agent/settings.json";
  jq = "${pkgs.jq}/bin/jq";

  subagentDir = ../extensions/subagent;
  subagentAgents = [
    "scout.md"
    "worker.md"
    "verifier.md"
  ];
  subagentPrompts = [
    "implement.md"
    "implement-and-review.md"
  ];
  piDiffReviewEnabled = builtins.hasAttr "pi-diff-review" pkgs && pkgs.stdenv.isDarwin;
  piDiffReviewRoot = "${pkgs.pi-diff-review}/lib/node_modules/pi-diff-review";
  piAutoresearchExtension = lib.optionalAttrs (builtins.hasAttr "pi-autoresearch" pkgs) {
    ".pi/agent/extensions/pi-autoresearch" = {
      source = "${pkgs.pi-autoresearch}/share/pi-autoresearch/extensions/pi-autoresearch";
      force = true;
    };
  };
  piDiffReviewExtension = lib.optionalAttrs piDiffReviewEnabled {
    ".pi/agent/extensions/pi-diff-review" = {
      source = piDiffReviewRoot;
      force = true;
    };
  };

  # We install our extensions into ~/.pi/agent/extensions (auto-discovered by pi).
  # Keep settings.json extension mutations only for cleanup/migration of legacy example extensions.
  piExtensions = [ ];
  extensionsJson = builtins.toJSON piExtensions;
  substituteScript =
    replacements: path:
    lib.replaceStrings (map (replacement: replacement.from) replacements) (map (
      replacement: replacement.to
    ) replacements) (builtins.readFile path);
  piCodingAgentSettingsScript = substituteScript [
    {
      from = "@settingsPath@";
      to = settingsPath;
    }
    {
      from = "@extensionsJson@";
      to = extensionsJson;
    }
    {
      from = "@jq@";
      to = jq;
    }
  ] ../scripts/pi-coding-agent-settings.sh;
  piDiffReviewGlimpseScript = substituteScript [
    {
      from = "@bash@";
      to = "${pkgs.bash}/bin/bash";
    }
    {
      from = "@buildGlimpseHost@";
      to = "${../scripts/build-glimpse-host.sh}";
    }
    {
      from = "@piDiffReviewRoot@";
      to = piDiffReviewRoot;
    }
    {
      from = "@node@";
      to = "${pkgs.nodejs}/bin/node";
    }
  ] ../scripts/pi-diff-review-glimpse-activation.sh;
  agentFiles = lib.listToAttrs (
    map (
      agent:
      lib.nameValuePair ".pi/agent/agents/${agent}" {
        source = "${subagentDir}/agents/${agent}";
        force = true;
      }
    ) subagentAgents
  );
  promptFiles = lib.listToAttrs (
    map (
      prompt:
      lib.nameValuePair ".pi/agent/prompts/${prompt}" {
        source = "${subagentDir}/prompts/${prompt}";
        force = true;
      }
    ) subagentPrompts
  );
in
lib.mkMerge [
  {
    home.file =
      agentFiles
      // promptFiles
      // {
        ".pi/agent/extensions/subagent" = {
          source = subagentDir;
          force = true;
        };
        ".pi/agent/extensions/handoff.ts" = {
          source = ../extensions/handoff.ts;
          force = true;
        };
        ".pi/agent/extensions/claude-system-prompt-compat.ts" = {
          source = ../extensions/claude-system-prompt-compat.ts;
          force = true;
        };

        # ".pi/agent/extensions/todowrite.ts" = {
        #   source = ../extensions/todowrite.ts;
        #   force = true;
        # };
      }
      // piAutoresearchExtension
      // piDiffReviewExtension;

    home.activation.piCodingAgentExtensions = lib.hm.dag.entryAfter [
      "writeBoundary"
      "piCodingAgentSettings"
    ] piCodingAgentSettingsScript;
  }
  (lib.mkIf piDiffReviewEnabled {
    home.sessionVariables = {
      GLIMPSE_BINARY_PATH = "${homeDir}/.cache/pi-diff-review/glimpse";
    };

    home.activation.piDiffReviewGlimpse = lib.hm.dag.entryAfter [
      "writeBoundary"
    ] piDiffReviewGlimpseScript;
  })
]
