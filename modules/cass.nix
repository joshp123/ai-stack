{
  config,
  pkgs,
  lib,
  ...
}:

let
  cassIndexerPkg = pkgs.writeShellApplication {
    name = "cass-indexer";
    runtimeInputs = [
      pkgs.cass
      pkgs.jq
    ];
    text = builtins.readFile ../scripts/cass-indexer.sh;
  };

in
{
  home.sessionVariables = {
    # Prevent interactive update prompts (agents should never hang on TUI UX).
    CODING_AGENT_SEARCH_NO_UPDATE_PROMPT = "1";
  };

  home.packages = lib.optionals pkgs.stdenv.isDarwin [ cassIndexerPkg ];
}
// lib.optionalAttrs pkgs.stdenv.isDarwin {
  # Keep cass indexed automatically (zero-maintenance). Works cross-agent and cross-repo.
  #
  # - First run: performs a full index build if DB/index missing.
  # - Steady state: watches agent session roots and incrementally reindexes.
  # - Restart behavior: always restart on exit.
  launchd.agents.cass-indexer = {
    enable = true;
    config = {
      # Stable name for macOS Login Items (avoid nix-store hash basenames).
      ProgramArguments = [ "${config.home.homeDirectory}/.nix-profile/bin/cass-indexer" ];
      KeepAlive = true;
      ThrottleInterval = 5;
      RunAtLoad = true;

      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/cass-indexer.stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/cass-indexer.stderr.log";

      EnvironmentVariables = {
        HOME = "${config.home.homeDirectory}";
        CODING_AGENT_SEARCH_NO_UPDATE_PROMPT = "1";
      };
    };
  };
}
// lib.optionalAttrs pkgs.stdenv.isLinux {
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
