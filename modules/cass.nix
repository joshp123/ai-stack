{ config, pkgs, lib, ... }:

let
  homeDir =
    if config ? home && config.home ? homeDirectory then
      config.home.homeDirectory
    else if config ? home && config.home ? username then
      if pkgs.stdenv.isDarwin then
        "/Users/${config.home.username}"
      else
        "/home/${config.home.username}"
    else if pkgs.stdenv.isDarwin then
      "/Users/${builtins.getEnv "USER"}"
    else
      "/home/${builtins.getEnv "USER"}";

  cassIndexerPkg = pkgs.writeShellScriptBin "cass-indexer" ''
    set -euo pipefail

    cass_bin="${pkgs.cass}/bin/cass"
    jq_bin="${pkgs.jq}/bin/jq"

    export CODING_AGENT_SEARCH_NO_UPDATE_PROMPT=1

    status_json="$($cass_bin status --json 2>/dev/null || true)"
    needs_full_index="$(
      echo "$status_json" | "$jq_bin" -r '
        ( (.database.exists // false) and (.index.exists // false) ) | not
      ' 2>/dev/null || echo true
    )"

    if [[ "$needs_full_index" == "true" ]]; then
      "$cass_bin" index --full
    fi

    exec "$cass_bin" index --watch
  '';

  # Stable name for macOS Login Items (avoid nix-store hash basenames).
  cassIndexerBin = "${homeDir}/.nix-profile/bin/cass-indexer";

in
{
  home.sessionVariables = {
    # Prevent interactive update prompts (agents should never hang on TUI UX).
    CODING_AGENT_SEARCH_NO_UPDATE_PROMPT = "1";
  };

  home.packages = lib.optionals pkgs.stdenv.isDarwin [ cassIndexerPkg ];
} // lib.optionalAttrs pkgs.stdenv.isDarwin {
  # Keep cass indexed automatically (zero-maintenance). Works cross-agent and cross-repo.
  #
  # - First run: performs a full index build if DB/index missing.
  # - Steady state: watches agent session roots and incrementally reindexes.
  # - Restart behavior: always restart on exit.
  launchd.agents.cass-indexer = {
    enable = true;
    config = {
      ProgramArguments = [ cassIndexerBin ];
      KeepAlive = true;
      ThrottleInterval = 5;
      RunAtLoad = true;

      StandardOutPath = "${homeDir}/Library/Logs/cass-indexer.stdout.log";
      StandardErrorPath = "${homeDir}/Library/Logs/cass-indexer.stderr.log";

      EnvironmentVariables = {
        HOME = "${homeDir}";
        CODING_AGENT_SEARCH_NO_UPDATE_PROMPT = "1";
      };
    };
  };
} // lib.optionalAttrs pkgs.stdenv.isLinux {
  systemd.user.services.cass-indexer = {
    Unit = {
      Description = "cass indexer (watch mode)";
    };

    Service = {
      ExecStart = "${cassIndexerPkg}/bin/cass-indexer";
      Restart = "always";
      RestartSec = 5;
      Environment = [
        "CODING_AGENT_SEARCH_NO_UPDATE_PROMPT=1"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
