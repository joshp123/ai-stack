{ config, lib, ... }:
let
  homeDir = config.home.homeDirectory or "~";

  defaultPluginSources = {
    padel = "github:joshp123/padel-cli";
    gohome = "github:joshp123/gohome";
    picnic = "github:joshp123/picnic";
  };

  padelPlugin = {
    source = defaultPluginSources.padel;
    config.env = {
      PADEL_AUTH_FILE = "/run/agenix/padel-auth";
      PADEL_CONFIG_DIR = "${homeDir}/.config/padel";
    };
  };

  picnicPlugin = {
    source = defaultPluginSources.picnic;
    config.env = {
      PICNIC_AUTH_FILE = "/run/agenix/picnic-auth";
      PICNIC_COUNTRY = "NL";
    };
  };

  gohomePlugin = {
    source = defaultPluginSources.gohome;
  };

  basePlugins = [ padelPlugin gohomePlugin picnicPlugin ];

  baseInstance = {
    enable = true;
    providers.telegram = {
      enable = true;
      botTokenFile = "";
      allowFrom = [ ];
      groups = { "*" = { requireMention = true; }; };
    };
    providers.anthropic.apiKeyFile = "";
    routing.queue = {
      mode = "interrupt";
      bySurface = {
        telegram = "interrupt";
        whatsapp = "interrupt";
        discord = "queue";
        webchat = "queue";
      };
    };
    plugins = basePlugins;
    configOverrides = {
      agent.maxConcurrent = 5;
    };
    appDefaults.enable = false;
  };

  prodInstance = lib.recursiveUpdate baseInstance {
    gatewayPort = 18789;
  };

  testInstance = lib.recursiveUpdate baseInstance {
    gatewayPort = 18790;
  };
in
{
  config = lib.mkIf (lib.hasAttrByPath [ "programs" "clawdbot" ] config) {
    programs.clawdbot = {
      defaults.model = lib.mkDefault "anthropic/claude-opus-4-5";
      defaults.thinkingDefault = lib.mkDefault "high";
      firstParty.oracle.enable = lib.mkDefault true;
      instances = {
        prod = prodInstance;
        test = testInstance;
      };
    };
  };
}
