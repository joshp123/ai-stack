{ config, lib, ... }:
{
  config = {
    programs.openclaw = {
      # Transitional macOS node/test profile used by the private repo.
      # Reusable OpenClaw app/lifecycle behavior belongs in nix-openclaw.
      #
      # We want the macOS app available for node-mode.
      # Force: ai-stack base sets installApp=false by default.
      installApp = lib.mkForce true;

      # Ensure the local prod gateway is not running from this public profile.
      # The private repo owns the active prod gateway host.
      instances.prod.enable = lib.mkForce false;

      # Keep a local test gateway around for dev (your preference).
      instances.test = {
        enable = lib.mkDefault true;

        # macOS: launchd.
        launchd.enable = lib.mkDefault true;
        systemd.enable = lib.mkDefault false;

        gatewayPort = lib.mkDefault 18790;

        # Don’t fight the app’s own remote/node-mode settings.
        appDefaults.enable = lib.mkDefault false;

        config = {
          agents = {
            list = [
              {
                id = "main";
                default = true;
                model = "anthropic/claude-opus-4-6";
                identity = {
                  name = "DJTBOT-TEST";
                  emoji = "🧪";
                };
              }
            ];

            # Keep the test gateway workspace isolated too.
            defaults.workspace = "~/.openclaw-test/workspace";
          };

          gateway.mode = "local";

          # Keep local test safe by default.
          discovery.mdns.mode = "minimal";
          channels.telegram.enabled = lib.mkDefault false;
        };
      };
    };

    # Operational note:
    # - The private repo configures the macOS app's active remote gateway.
    # - This public profile only ensures node/test defaults are available.
  };
}
