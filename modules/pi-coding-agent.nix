{ config, pkgs, lib, ... }:

let
  user = config.home.username or (builtins.getEnv "USER");
  homeDir = config.home.homeDirectory or "/home/${user}";
  settingsPath = "${homeDir}/.pi/agent/settings.json";
  jq = "${pkgs.jq}/bin/jq";
  # Extensions from upstream pi (update with pi)
  permissionGate = "${pkgs.pi-coding-agent}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/permission-gate.ts";
  handoff = "${pkgs.pi-coding-agent}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/handoff.ts";
  subagentExampleDir = "${pkgs.pi-coding-agent}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/subagent";
  subagentExtensionPath = "${homeDir}/.pi/agent/extensions/subagent/index.ts";
  subagentAgents = [ "scout.md" "planner.md" "reviewer.md" "worker.md" ];
  subagentPrompts = [ "implement.md" "implement-and-review.md" "scout-and-plan.md" ];
  # Our extensions (Codex compatibility, custom tools)
  piExtensions = [ permissionGate handoff subagentExtensionPath ];
  extensionsJson = builtins.toJSON piExtensions;
  agentFiles = lib.genAttrs subagentAgents (agent: {
    source = "${subagentExampleDir}/agents/${agent}";
    force = true;
  });
  promptFiles = lib.genAttrs subagentPrompts (prompt: {
    source = "${subagentExampleDir}/prompts/${prompt}";
    force = true;
  });
in
{
  home.file =
    agentFiles
    // promptFiles
    // {
      ".pi/agent/extensions/subagent/index.ts" = {
        source = "${subagentExampleDir}/index.ts";
        force = true;
      };
      ".pi/agent/extensions/subagent/agents.ts" = {
        source = "${subagentExampleDir}/agents.ts";
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
      .extensions = ($exts + (.extensions // [])) |
      .extensions |= unique
    ' "$tmp" > "$tmp.cfg"
    mv "$tmp.cfg" "$tmp"

    mv "$tmp" "$settings"
    chmod 600 "$settings"
  '';
}
