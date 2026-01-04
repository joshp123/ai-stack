{ lib, ... }:
{
  options.ai.clawdis = {
    channel = lib.mkOption {
      type = lib.types.enum [ "local" "stable" ];
      default = "stable";
      description = "Clawdis nix-clawdis source (local checkout or stable release).";
    };
  };
}
