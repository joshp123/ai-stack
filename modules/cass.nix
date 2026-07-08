{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.cassIndexer;

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
  # mkEnableOption already defaults to false; kept off until the leak below is fixed.
  options.programs.cassIndexer.enable = lib.mkEnableOption ''
    the cass background indexer (watch mode) as a launchd/systemd user service.

    Disabled by default: this service has a known catastrophic memory leak
    (unbounded growth under `cass index --watch`). Do not enable until that
    is fixed upstream. The one-shot `cass` CLI itself is unaffected and stays
    installed via nix-ai-tools regardless of this option
  '';

  config = {
    home.sessionVariables = {
      # Prevent interactive update prompts (agents should never hang on TUI UX).
      # Applies to any interactive `cass` invocation, not just the indexer service.
      CODING_AGENT_SEARCH_NO_UPDATE_PROMPT = "1";
    };
  }
  // lib.optionalAttrs (cfg.enable && pkgs.stdenv.isDarwin) {
    home.packages = [ cassIndexerPkg ];

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
  // lib.optionalAttrs (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ cassIndexerPkg ];

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
  };
}
