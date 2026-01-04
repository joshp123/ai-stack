{ config, lib, ... }:
let
  cfg = config.ai.clawdbot.profile;

  mkTelegram = tokenFile: allowFrom: requireMention:
    if tokenFile == null then { } else {
      providers.telegram = {
        enable = true;
        botTokenFile = tokenFile;
        allowFrom = allowFrom;
        groups = {
          _default = { inherit requireMention; };
        };
      };
    };

  mkIdentity = name: emoji:
    if name == null && emoji == null then { } else {
      identity = lib.filterAttrs (_: v: v != null) {
        inherit name emoji;
      };
    };

  mkTranscribe = whisperPath:
    if whisperPath == null then { } else {
      inbound = {
        transcribeAudio = {
          command = [
            whisperPath
            "--model"
            "base"
            "--output_format"
            "txt"
            "--output_dir"
            "/tmp"
            "{{MediaPath}}"
          ];
          timeoutSeconds = 60;
        };
      };
    };
in
{
  options.ai.clawdbot.profile = {
    enableProd = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the prod Clawdbot instance.";
    };
    enableTest = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the test Clawdbot instance.";
    };

    anthropicApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to Anthropic API key file.";
    };

    prod = {
      plugins = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              description = "Plugin source pointer (e.g., github:owner/repo or path:/...).";
            };
            config = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Plugin-specific configuration (env/files/etc).";
            };
          };
        });
        default = [ ];
        description = "Additional plugins for the prod instance.";
      };
      telegramTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Telegram bot token file for prod.";
      };
      telegramAllowFrom = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        description = "Telegram allowlist for prod.";
      };
      requireMention = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Require @mention for prod group messages.";
      };
      identityName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Prod bot display name.";
      };
      identityEmoji = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Prod bot emoji.";
      };
      extraSkillDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra skill directories for prod.";
      };
    };

    test = {
      plugins = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              description = "Plugin source pointer (e.g., github:owner/repo or path:/...).";
            };
            config = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Plugin-specific configuration (env/files/etc).";
            };
          };
        });
        default = [ ];
        description = "Additional plugins for the test instance.";
      };
      telegramTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Telegram bot token file for test.";
      };
      telegramAllowFrom = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        description = "Telegram allowlist for test.";
      };
      requireMention = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Require @mention for test group messages.";
      };
      identityName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Test bot display name.";
      };
      identityEmoji = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Test bot emoji.";
      };
      extraSkillDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra skill directories for test.";
      };
    };

    whisperPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to whisper binary (if available).";
    };

    skillPaths = {
      gohome = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to gohome clawdbot skill directory.";
      };
      padel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to padel skill directory.";
      };
    };
  };

  config = lib.mkIf (lib.hasAttrByPath [ "programs" "clawdbot" ] config) {
    programs.clawdbot = {
      skills = lib.mkAfter (
        (lib.optional (cfg.skillPaths.gohome != null) {
          name = "gohome-clawdbot";
          mode = "symlink";
          source = cfg.skillPaths.gohome;
          description = "Gohome home assistant flows.";
        }) ++
        (lib.optional (cfg.skillPaths.padel != null) {
          name = "padel";
          mode = "symlink";
          source = cfg.skillPaths.padel;
          description = "Padel CLI booking and availability.";
        })
      );

      instances = lib.mkMerge [
        (lib.optionalAttrs cfg.enableProd {
          prod = lib.recursiveUpdate
            {
              providers.anthropic = lib.optionalAttrs (cfg.anthropicApiKeyFile != null) {
                apiKeyFile = cfg.anthropicApiKeyFile;
              };
              routing.queue = {
                mode = "interrupt";
                bySurface = {
                  telegram = "interrupt";
                  whatsapp = "interrupt";
                  discord = "queue";
                  webchat = "queue";
                };
              };
              gatewayPort = 18789;
              appDefaults.enable = false;
              plugins = cfg.prod.plugins;
              configOverrides = lib.recursiveUpdate
                (mkIdentity cfg.prod.identityName cfg.prod.identityEmoji)
                (lib.recursiveUpdate
                  (mkTranscribe cfg.whisperPath)
                  (lib.optionalAttrs (cfg.prod.extraSkillDirs != [ ]) {
                    skillsLoad.extraDirs = cfg.prod.extraSkillDirs;
                  }));
            }
            (mkTelegram cfg.prod.telegramTokenFile cfg.prod.telegramAllowFrom cfg.prod.requireMention);
        })
        (lib.optionalAttrs cfg.enableTest {
          test = lib.recursiveUpdate
            {
              launchd.label = "com.steipete.clawdbot.gateway.nix-test";
              providers.anthropic = lib.optionalAttrs (cfg.anthropicApiKeyFile != null) {
                apiKeyFile = cfg.anthropicApiKeyFile;
              };
              routing.queue = {
                mode = "interrupt";
                bySurface = {
                  telegram = "interrupt";
                  whatsapp = "interrupt";
                  discord = "queue";
                  webchat = "queue";
                };
              };
              gatewayPort = 18790;
              appDefaults.enable = false;
              plugins = cfg.test.plugins;
              configOverrides = lib.recursiveUpdate
                (mkIdentity cfg.test.identityName cfg.test.identityEmoji)
                (lib.recursiveUpdate
                  (mkTranscribe cfg.whisperPath)
                  (lib.optionalAttrs (cfg.test.extraSkillDirs != [ ]) {
                    skillsLoad.extraDirs = cfg.test.extraSkillDirs;
                  }));
            }
            (mkTelegram cfg.test.telegramTokenFile cfg.test.telegramAllowFrom cfg.test.requireMention);
        })
      ];
    };
  };
}
