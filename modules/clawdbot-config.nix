{ config, lib, ... }:
let
  homeDir = config.home.homeDirectory or "~";

  pluginSourcesOverride = config.programs.clawdbot.pluginSourcesOverride or {};
  defaultPluginSources = {
    padel = "github:joshp123/padel-cli";
    gohome = "github:joshp123/gohome";
    picnic = "github:joshp123/picnic-cli";
  };
  pluginSources = defaultPluginSources // pluginSourcesOverride;

  padelPlugin = {
    source = pluginSources.padel;
    config.env = {
      PADEL_AUTH_FILE = "/run/agenix/padel-auth";
      PADEL_CONFIG_DIR = "${homeDir}/.config/padel";
    };
  };

  picnicPlugin = {
    source = pluginSources.picnic;
    config.env = {
      PICNIC_AUTH_FILE = "/run/agenix/picnic-auth";
      PICNIC_COUNTRY = "NL";
    };
  };

  gohomePlugin = {
    source = pluginSources.gohome;
  };

  basePlugins = [ padelPlugin gohomePlugin picnicPlugin ];

  baseInstance = {
    enable = true;
    providers.telegram = {
      enable = true;
      botTokenFile = lib.mkDefault "";
      allowFrom = lib.mkDefault [ ];
      groups = { "*" = { requireMention = true; }; };
    };
    providers.anthropic.apiKeyFile = lib.mkDefault "";
    routing.queue = {
      mode = "interrupt";
      byProvider = {
        telegram = "interrupt";
        whatsapp = "interrupt";
        discord = "queue";
        webchat = "queue";
      };
    };
    plugins = lib.mkDefault basePlugins;
    configOverrides = {
      agents.defaults.maxConcurrent = 5;
    };
    appDefaults.enable = false;
  };

  prodInstance = lib.recursiveUpdate baseInstance {
    gatewayPort = 18789;
    configOverrides = {
      agents.list = [
        {
          id = "main";
          default = true;
          identity = { name = "DJTBOT"; emoji = "🇺🇸"; };
        }
      ];
      skillsLoad.extraDirs = [
        "${homeDir}/.clawdbot-prod/workspace/skills"
      ];
    };
  };

  testInstance = lib.recursiveUpdate baseInstance {
    gatewayPort = 18790;
    configOverrides = {
      agents.list = [
        {
          id = "main";
          default = true;
          identity = { name = "DJTBOT-TEST"; emoji = "🧪"; };
        }
      ];
      skillsLoad.extraDirs = [
        "${homeDir}/.clawdbot-test/workspace/skills"
      ];
    };
  };
in
{
  options.programs.clawdbot.pluginSourcesOverride = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    description = "Override plugin sources by name (e.g. local dev paths).";
  };

  config = lib.mkIf (lib.hasAttrByPath [ "programs" "clawdbot" ] config) {
    programs.clawdbot = {
      defaults.model = lib.mkDefault "anthropic/claude-opus-4-5";
      defaults.thinkingDefault = lib.mkDefault "high";
      installApp = lib.mkDefault false;
      firstParty.oracle.enable = lib.mkDefault true;
      instances = {
        prod = prodInstance;
        test = testInstance;
      };
    };
  };
}
