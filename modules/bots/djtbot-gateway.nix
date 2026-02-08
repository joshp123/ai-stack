{ config, lib, ... }:
let
  # Public defaults only. Secrets + PII live in nixos-config.
  #
  # Expected private overlay responsibilities:
  # - channels.telegram.* (tokenFile, allowFrom, groups)
  # - OPENCLAW_GATEWAY_TOKEN in the gateway service environment
  # - plugin secret files under /run/agenix (padel-auth, xuezh keys, ...)
  homeDir = config.home.homeDirectory or "~";

  pluginSourcesOverride = config.programs.openclaw.pluginSourcesOverride or {};
  # Pin plugin sources (pure flakes). Override in private repo for local dev.
  defaultPluginSources = {
    padel = "github:joshp123/padel-cli?rev=0022bb42bca7847d1856e24f2b3307defa00237c&narHash=sha256-vGNYZyriTXkvW77TBuJl0otDCpmVzTF/p3kU/THIzGs=";
    gohome = "github:joshp123/gohome?rev=f084ae5512c0862cea7dd22f0c1e77e620642433&narHash=sha256-kRN0JvOPCzqJOcUAzNm1MK08SUzdDmG3B2d/vfsGiH0=";
    xuezh = "github:joshp123/xuezh?rev=1181520f77450dcd0bdda05025504612015b6d7c&narHash=sha256-j7pWAcyWHz4/2bFRqaUGDV+sg9rJPnCCo95KJUm59k4=";
  };
  pluginSources = defaultPluginSources // pluginSourcesOverride;

  padelPlugin = {
    source = pluginSources.padel;
    config.env = {
      PADEL_AUTH_FILE = "/run/agenix/padel-auth";
      PADEL_CONFIG_DIR = "${homeDir}/.config/padel";
    };
  };

  gohomePlugin = {
    source = pluginSources.gohome;
  };

  xuezhPlugin = {
    source = pluginSources.xuezh;
    config.env = {
      XUEZH_AZURE_SPEECH_KEY_FILE = "/run/agenix/xuezh-azure-speech-key";
      XUEZH_AZURE_SPEECH_REGION = "/run/agenix/xuezh-azure-speech-region";
    };
  };

  basePlugins = [ padelPlugin gohomePlugin xuezhPlugin ];

in {
  config = {
    programs.openclaw = {
      installApp = lib.mkDefault false;

      # Compose plugins the idiomatic way (so bundledPlugins/firstParty still work).
      customPlugins = lib.mkDefault basePlugins;

      # Canonical gateway: VPS.
      instances.prod = {
        enable = lib.mkDefault true;

        # VPS: systemd user service.
        systemd.enable = lib.mkDefault true;
        launchd.enable = lib.mkDefault false;
        appDefaults.enable = lib.mkDefault false;

        gatewayPort = lib.mkDefault 18789;

        config = {
          agents = {
            list = [
              {
                id = "main";
                default = true;
                model = "anthropic/claude-opus-4-6";
                identity = { name = "DJTBOT"; emoji = "🇺🇸"; };
              }
            ];
            defaults = {
              # IMPORTANT: OpenClaw defaults the agent workspace to ~/.openclaw/workspace
              # unless you override it. For profile/instance isolation we want the
              # workspace to live alongside the instance stateDir.
              workspace = "${homeDir}/.openclaw-prod/workspace";

              maxConcurrent = 4;
              subagents.maxConcurrent = 8;

              models = {
                "anthropic/claude-opus-4-6" = { alias = "opus"; };
                "openai-codex/gpt-5.3-codex" = { alias = "codex"; };
              };
            };
          };

          commands = {
            native = "auto";
            nativeSkills = "auto";
          };

          gateway = {
            mode = "local";
            bind = "tailnet";
            auth = {
              mode = "token";
              token = "\${OPENCLAW_GATEWAY_TOKEN}";
              allowTailscale = false;
            };
          };

          discovery.mdns.mode = "off";

          # Public default: Telegram disabled. Private repo must explicitly enable + configure.
          channels.telegram.enabled = lib.mkDefault false;

          messages.ackReactionScope = "group-mentions";

          plugins.entries.telegram.enabled = lib.mkDefault true;
        };
      };
    };
  };
}
