{ config, pkgs, lib, ... }:

let
  user = config.home.username or (builtins.getEnv "USER");
  homeDir = config.home.homeDirectory or "/home/${user}";
  settingsPath = "${homeDir}/.pi/agent/settings.json";
  jq = "${pkgs.jq}/bin/jq";
  permissionGate = "${pkgs.pi-coding-agent}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/permission-gate.ts";
  handoff = "${pkgs.pi-coding-agent}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/handoff.ts";
in
{
  home.activation.piCodingAgentExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail
    settings="${settingsPath}"
    mkdir -p "$(dirname "$settings")"

    tmp="$(mktemp)"
    if [ -f "$settings" ]; then
      if ! ${jq} --arg ext1 "$permissionGate" --arg ext2 "$handoff" '
        .extensions = ([$ext1, $ext2] + (.extensions // [])) |
        .extensions |= unique
      ' "$settings" > "$tmp"; then
        echo "pi-coding-agent: invalid JSON in $settings, recreating with extensions" >&2
        echo '{}' > "$tmp"
        ${jq} --arg ext1 "$permissionGate" --arg ext2 "$handoff" '
          .extensions = ([$ext1, $ext2] + (.extensions // [])) |
          .extensions |= unique
        ' "$tmp" > "$tmp.cfg"
        mv "$tmp.cfg" "$tmp"
      fi
    else
      echo '{}' > "$tmp"
      ${jq} --arg ext1 "$permissionGate" --arg ext2 "$handoff" '
        .extensions = ([$ext1, $ext2] + (.extensions // [])) |
        .extensions |= unique
      ' "$tmp" > "$tmp.cfg"
      mv "$tmp.cfg" "$tmp"
    fi

    mv "$tmp" "$settings"
    chmod 600 "$settings"
  '';
}
