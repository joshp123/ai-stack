{
  description = "ai-stack: public, no-PII AI stack modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-clawdbot.url = "github:clawdbot/nix-clawdbot";
  };

  outputs = { self, nixpkgs, home-manager, nix-clawdbot }:
    let
      module = { ... }: {
        imports = [
          nix-clawdbot.homeManagerModules.clawdis
          ./modules/ai-stack.nix
        ];
      };
    in {
      homeManagerModules.ai-stack = module;
    };
}
