# The nightly AI tools update, as a launchd user agent. As the user, in its own
# clone of the config repo: move the nix-ai-tools lock entry, commit, build the
# AI tools bundle, load the system's written pi extensions into its pi, build
# the system from that commit (the guard: main must always build), push,
# install the bundle into the user's AI profile and copy CuaDriver.app into
# /Applications. Only nix-ai-tools packages update this way; skills, prompts and
# pi extensions change only on a switch. It never touches the system
# configuration. ai-tools-mail emails when a failure has lasted three days.
#
# Runtime state: the profile, ~/.local/state/ai-tools/ (checkout and status
# files) and ~/Library/Logs/update-ai-tools.log. Cleanup: disable this module,
# switch, then move the profile's symlinks (`<profile>` and `<profile>-*-link`)
# to the Trash; `nix store gc` then frees the bundles. The profile is made by
# `nix build --profile`, so `nix profile remove` finds no packages in it.
{ config, pkgs, lib, ... }:

let
  cfg = config.services.update-ai-tools;
  home = "/Users/${cfg.user}";

  aiToolsSmoke = pkgs.writeShellApplication {
    name = "ai-tools-smoke";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./update-ai-tools/ai-tools-smoke.sh;
  };

  aiToolsExtensionCheck = pkgs.writeShellApplication {
    name = "ai-tools-extension-check";
    runtimeInputs = [ pkgs.coreutils pkgs.jq ];
    text = builtins.readFile ./update-ai-tools/ai-tools-extension-check.sh;
  };

  aiToolsModelCheck = pkgs.writeShellApplication {
    name = "ai-tools-model-check";
    runtimeInputs = [ pkgs.coreutils pkgs.gnugrep ];
    text = builtins.readFile ./update-ai-tools/ai-tools-model-check.sh;
  };

  aiToolsMail = pkgs.writeShellApplication {
    name = "ai-tools-mail";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = builtins.readFile ./update-ai-tools/ai-tools-mail.sh;
  };

  # nix itself comes from the launchd PATH (the system's nix), not from
  # nixpkgs, so the job uses the same daemon and settings as the user.
  updateAiTools = pkgs.writeShellApplication {
    name = "update-ai-tools";
    runtimeInputs = [ pkgs.git pkgs.curl pkgs.jq pkgs.coreutils aiToolsSmoke aiToolsExtensionCheck aiToolsModelCheck aiToolsMail ];
    text = builtins.readFile ./update-ai-tools/update-ai-tools.sh;
  };
in
{
  options.services.update-ai-tools = {
    enable = lib.mkEnableOption "the nightly AI tools update";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.system.primaryUser;
      description = "The user whose home holds the AI profile, the state and the log. launchd runs the agent as whoever is logged in to the GUI, so this must be that user.";
    };

    repo = lib.mkOption {
      type = lib.types.str;
      example = "git@github.com:you/nixos-config.git";
      description = "The config repo holding flake.lock and the ai-tools output; its main branch is updated.";
    };

    flakeAttr = lib.mkOption {
      type = lib.types.str;
      default = "ai-tools";
      description = "The repo's flake output for the AI tools bundle.";
    };

    piExtensionsAttr = lib.mkOption {
      type = lib.types.str;
      default = "pi-extensions";
      description = ''
        The repo's flake output for the written pi extensions the system links
        (programs.ai-profile.authoredPiExtensions). They are loaded into each
        new pi before it is pushed or installed.
      '';
    };

    systemAttr = lib.mkOption {
      type = lib.types.str;
      default = "darwinConfigurations.${pkgs.stdenv.hostPlatform.system}.system";
      description = "The system output built as the guard before a lock bump is pushed.";
    };

    profile = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.local/state/nix/profiles/ai";
      description = "The user-owned Nix profile the AI tools bundle is installed into.";
    };

    upstreamRuns = lib.mkOption {
      type = lib.types.str;
      example = "https://api.github.com/repos/you/nix-ai-tools/actions/workflows/auto-bump.yml/runs?status=success&per_page=1";
      description = "GitHub API query for the newest green run of the packages repo's update job; three days without one is reported.";
    };

    schedule = lib.mkOption {
      type = lib.types.attrs;
      default = { Hour = 5; Minute = 0; };
      description = "launchd StartCalendarInterval. A missed run fires on wake.";
    };

    mail = {
      to = lib.mkOption { type = lib.types.str; description = "Alert recipient."; };
      from = lib.mkOption { type = lib.types.str; description = "Gmail account the alert is sent from."; };
      passwordFile = lib.mkOption {
        type = lib.types.str;
        description = "File holding that account's app password (an agenix secret).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ updateAiTools aiToolsSmoke aiToolsExtensionCheck aiToolsModelCheck aiToolsMail ];

    launchd.user.agents.update-ai-tools.serviceConfig = {
      ProgramArguments = [ "${updateAiTools}/bin/update-ai-tools" ];
      StartCalendarInterval = [ cfg.schedule ];
      EnvironmentVariables = {
        PATH = "/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        UPDATE_AI_TOOLS_REPO = cfg.repo;
        UPDATE_AI_TOOLS_ATTR = cfg.flakeAttr;
        UPDATE_AI_TOOLS_SYSTEM_ATTR = cfg.systemAttr;
        UPDATE_AI_TOOLS_PI_EXTENSIONS_ATTR = cfg.piExtensionsAttr;
        UPDATE_AI_TOOLS_PROFILE = cfg.profile;
        UPDATE_AI_TOOLS_UPSTREAM_RUNS = cfg.upstreamRuns;
        AI_TOOLS_MAIL_TO = cfg.mail.to;
        AI_TOOLS_MAIL_FROM = cfg.mail.from;
        AI_TOOLS_MAIL_PASSWORD_FILE = cfg.mail.passwordFile;
      };
      StandardOutPath = "${home}/Library/Logs/update-ai-tools.log";
      StandardErrorPath = "${home}/Library/Logs/update-ai-tools.log";
    };
  };
}
