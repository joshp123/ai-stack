{ config, pkgs, lib, ... }:

let
  user = config.home.username or (builtins.getEnv "USER");
  homeDir = config.home.homeDirectory or "/home/${user}";
  settingsPath = "${homeDir}/.pi/agent/settings.json";
  jq = "${pkgs.jq}/bin/jq";
  # Extensions from upstream pi (update with pi)
  # (Keep these paths for cleanup/migration if we ever remove legacy extensions from settings.json)
  permissionGate = "${pkgs.pi-coding-agent}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/permission-gate.ts";
  upstreamHandoff = "${pkgs.pi-coding-agent}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/handoff.ts";

  # Managed extensions installed into ~/.pi/agent/extensions via home-manager
  handoffExtensionPath = "${homeDir}/.pi/agent/extensions/handoff.ts";

  subagentDir = ../extensions/subagent;
  subagentExtensionPath = "${homeDir}/.pi/agent/extensions/subagent/index.ts";
  subagentAgents = [ "scout.md" "worker.md" "verifier.md" ];
  subagentPrompts = [ "implement.md" "implement-and-review.md" ];

  # We install our extensions into ~/.pi/agent/extensions (auto-discovered by pi).
  # Keep settings.json extension mutations only for cleanup/migration of legacy example extensions.
  piExtensions = [ ];
  extensionsJson = builtins.toJSON piExtensions;
  agentFiles = lib.listToAttrs (map (agent: lib.nameValuePair ".pi/agent/agents/${agent}" {
    source = "${subagentDir}/agents/${agent}";
    force = true;
  }) subagentAgents);
  promptFiles = lib.listToAttrs (map (prompt: lib.nameValuePair ".pi/agent/prompts/${prompt}" {
    source = "${subagentDir}/prompts/${prompt}";
    force = true;
  }) subagentPrompts);
in
{
  home.file =
    agentFiles
    // promptFiles
    // {
      ".pi/agent/extensions/subagent/index.ts" = {
        source = "${subagentDir}/index.ts";
        force = true;
      };
      ".pi/agent/extensions/subagent/agents.ts" = {
        source = "${subagentDir}/agents.ts";
        force = true;
      };
      ".pi/agent/extensions/handoff.ts" = {
        source = ../extensions/handoff.ts;
        force = true;
      };

      # ".pi/agent/extensions/todowrite.ts" = {
      #   source = ../extensions/todowrite.ts;
      #   force = true;
      # };
    };

  home.activation.piCodingAgentExtensions = lib.hm.dag.entryAfter [ "writeBoundary" "piCodingAgentSettings" ] ''
    set -euo pipefail
    settings="${settingsPath}"
    mkdir -p "$(dirname "$settings")"

    tmp="$(mktemp)"
    if [ -f "$settings" ]; then
      if ${jq} -e . "$settings" >/dev/null 2>&1; then
        cp "$settings" "$tmp"
      else
        echo "pi-coding-agent: invalid JSON in $settings, recreating with extensions" >&2
        echo '{}' > "$tmp"
      fi
    else
      echo '{}' > "$tmp"
    fi

    ${jq} --argjson exts '${extensionsJson}' '
      .extensions = (
        ((.extensions // [])
          | map(select(
              (test("examples/extensions/permission-gate\\.ts$") | not)
              and (test("examples/extensions/handoff\\.ts$") | not)
            ))
        )
        + $exts
      ) |
      .extensions |= unique
    ' "$tmp" > "$tmp.cfg"
    mv "$tmp.cfg" "$tmp"

    mv "$tmp" "$settings"
    chmod 600 "$settings"
  '';
}
