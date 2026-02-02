{ config, lib, ... }:
let
  homeDir = config.home.homeDirectory or "~";

  pluginSourcesOverride = config.programs.openclaw.pluginSourcesOverride or {};
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

  baseConfig = {
    gateway = {
      mode = "local";
    };
    channels.telegram = {
      enabled = true;
      allowFrom = lib.mkDefault [ ];
      groups = { "*" = { requireMention = true; }; };
    };
    messages.queue = {
      mode = "interrupt";
      byChannel = {
        telegram = "interrupt";
        whatsapp = "interrupt";
        discord = "queue";
        webchat = "queue";
      };
    };
    agents = {};
  };

  baseInstance = {
    enable = true;
    plugins = lib.mkDefault basePlugins;
    appDefaults.enable = false;
  };

  prodInstance = lib.recursiveUpdate baseInstance {
    gatewayPort = 18789;
    config = {
      agents.list = [
        {
          id = "main";
          default = true;
          model = "anthropic/claude-opus-4-5";
          identity = { name = "DJTBOT"; emoji = "🇺🇸"; };
        }
      ];
      skills.load.extraDirs = [
        "${homeDir}/.openclaw-prod/workspace/skills"
      ];
    };
  };

  testInstance = lib.recursiveUpdate baseInstance {
    gatewayPort = 18790;
    config = {
      agents.list = [
        {
          id = "main";
          default = true;
          model = "anthropic/claude-opus-4-5";
          identity = { name = "DJTBOT-TEST"; emoji = "🧪"; };
        }
      ];
      skills.load.extraDirs = [
        "${homeDir}/.openclaw-test/workspace/skills"
      ];
    };
  };
in
{
  options.programs.openclaw.pluginSourcesOverride = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    description = "Override plugin sources by name (e.g. local dev paths).";
  };

  config = lib.mkIf (lib.hasAttrByPath [ "programs" "openclaw" ] config) {
    programs.openclaw = {
      installApp = lib.mkDefault false;
      firstParty.oracle.enable = lib.mkDefault true;
      config = baseConfig;
      instances = {
        prod = prodInstance;
        test = testInstance;
      };
    };
  };
}
