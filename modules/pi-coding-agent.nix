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

  patchedPiCodingAgent = pkgs.pi-coding-agent.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../patches/pi-coding-agent/responses-v2-compaction.patch ];
    meta = (old.meta or { }) // {
      priority = 4;
    };
  });

  responsesV2CompactionDir = ../extensions/responses-v2-compaction;
  subagentDir = ../extensions/subagent;

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
in
{
  home.packages = [ patchedPiCodingAgent ];

  home.file = {
    ".pi/agent/extensions/responses-v2-compaction" = {
      source = responsesV2CompactionDir;
      force = true;
    };
    ".pi/agent/extensions/subagent" = {
      source = subagentDir;
      force = true;
    };
    ".pi/agent/extensions/claude-system-prompt-compat.ts" = {
      source = ../extensions/claude-system-prompt-compat.ts;
      force = true;
    };
  };

  home.activation.piCodingAgentExtensions = lib.hm.dag.entryAfter [
    "writeBoundary"
    "piCodingAgentSettings"
  ] piCodingAgentSettingsScript;
}
