{ config, lib, ... }:
let
  root = config.ai.clawdbot;
  cfg = root.profile;

  defaultPluginSources = {
    padel = "github:joshp123/padel-cli";
    gohome = "github:joshp123/gohome";
    picnic = "github:joshp123/picnic";
  };

  pluginSource = name:
    if root.localPlugins.${name} != null
    then "path:${root.localPlugins.${name}}"
    else defaultPluginSources.${name};

  mkTelegram = tokenFile: allowFrom: requireMention: groups:
    if tokenFile == null then { } else {
      providers.telegram = {
        enable = true;
        botTokenFile = tokenFile;
        allowFrom = allowFrom;
        groups = {
          _default = { inherit requireMention; };
        } // groups;
      };
    };

  mkIdentity = name: emoji:
    if name == null && emoji == null then { } else {
      identity = lib.filterAttrs (_: v: v != null) {
        inherit name emoji;
      };
    };

  mkConcurrency = maxConcurrent:
    if maxConcurrent == null then { } else {
      agent = { inherit maxConcurrent; };
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

  padelPlugin =
    if root.plugins.padel.enable && root.secrets.padelAuthFile != null then {
      source = pluginSource "padel";
      config = {
        env = {
          PADEL_AUTH_FILE = root.secrets.padelAuthFile;
          PADEL_CONFIG_DIR = root.padel.configDir;
        };
      };
    } else null;

  picnicPlugin =
    if root.plugins.picnic.enable && root.secrets.picnicAuthFile != null then {
      source = pluginSource "picnic";
      config = {
        env = {
          PICNIC_AUTH_FILE = root.secrets.picnicAuthFile;
          PICNIC_COUNTRY = root.picnic.country;
        };
      };
    } else null;

  gohomePlugin =
    if root.plugins.gohome.enable then {
      source = pluginSource "gohome";
    } else null;

  basePlugins = lib.filter (p: p != null) [ padelPlugin gohomePlugin picnicPlugin ];

  padelConfig = {
    default_location = root.padel.defaultLocation;
    favourite_clubs = root.padel.favouriteClubs;
    preferred_times = root.padel.preferredTimes;
    preferred_duration = root.padel.preferredDuration;
  };

  padelConfigFiltered = lib.filterAttrs (_: v:
    v != null && v != [ ]
  ) padelConfig;
in
{
  options.ai.clawdbot = {
    localPlugins = {
      padel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Local path to padel-cli plugin (path:/... override).";
      };
      gohome = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Local path to gohome plugin (path:/... override).";
      };
      picnic = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Local path to picnic plugin (path:/... override).";
      };
    };

    secrets = {
      padelAuthFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to padel auth file (PADEL_AUTH_FILE).";
      };
      picnicAuthFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to picnic auth file (PICNIC_AUTH_FILE).";
      };
    };

    plugins = {
      padel.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the padel plugin.";
      };
      gohome.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the gohome plugin.";
      };
      picnic.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the picnic plugin.";
      };
    };

    padel = {
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "~/.config/padel";
        description = "Padel config directory (PADEL_CONFIG_DIR).";
      };
      defaultLocation = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Padel default location (PII).";
      };
      favouriteClubs = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            id = lib.mkOption { type = lib.types.str; };
            alias = lib.mkOption { type = lib.types.str; };
          };
        });
        default = [ ];
        description = "Padel favourite clubs (public).";
      };
      preferredTimes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Padel preferred times (public).";
      };
      preferredDuration = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Padel preferred duration in minutes (public).";
      };
    };

    picnic = {
      country = lib.mkOption {
        type = lib.types.str;
        default = "NL";
        description = "Picnic country code (public).";
      };
    };
  };

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
      telegramGroups = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Telegram per-group overrides for prod (chat-id -> options).";
      };
      requireMention = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Require @mention for prod group messages.";
      };
      maxConcurrent = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Max concurrent runs for prod (agent.maxConcurrent).";
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
      telegramGroups = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Telegram per-group overrides for test (chat-id -> options).";
      };
      requireMention = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Require @mention for test group messages.";
      };
      maxConcurrent = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Max concurrent runs for test (agent.maxConcurrent).";
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
              plugins = basePlugins ++ cfg.prod.plugins;
              configOverrides = lib.recursiveUpdate
                (mkIdentity cfg.prod.identityName cfg.prod.identityEmoji)
                (lib.recursiveUpdate
                  (mkTranscribe cfg.whisperPath)
                  (lib.recursiveUpdate
                    (mkConcurrency cfg.prod.maxConcurrent)
                    (lib.optionalAttrs (cfg.prod.extraSkillDirs != [ ]) {
                      skillsLoad.extraDirs = cfg.prod.extraSkillDirs;
                    })));
            }
            (mkTelegram cfg.prod.telegramTokenFile cfg.prod.telegramAllowFrom cfg.prod.requireMention cfg.prod.telegramGroups);
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
              plugins = basePlugins ++ cfg.test.plugins;
              configOverrides = lib.recursiveUpdate
                (mkIdentity cfg.test.identityName cfg.test.identityEmoji)
                (lib.recursiveUpdate
                  (mkTranscribe cfg.whisperPath)
                  (lib.recursiveUpdate
                    (mkConcurrency cfg.test.maxConcurrent)
                    (lib.optionalAttrs (cfg.test.extraSkillDirs != [ ]) {
                      skillsLoad.extraDirs = cfg.test.extraSkillDirs;
                    })));
            }
            (mkTelegram cfg.test.telegramTokenFile cfg.test.telegramAllowFrom cfg.test.requireMention cfg.test.telegramGroups);
        })
      ];
    };

    home.file = lib.optionalAttrs (root.plugins.padel.enable && padelConfigFiltered != { }) {
      ".config/padel/config.json".text = builtins.toJSON padelConfigFiltered;
    };

  };
}
