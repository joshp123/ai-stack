{ lib, ... }:
{
  options.ai.clawdbot = {
    channel = lib.mkOption {
      type = lib.types.enum [ "local" "stable" ];
      default = "stable";
      description = "Clawdbot nix-clawdbot source (local checkout or stable release).";
    };
  };
}
