{
  description = "ai-stack: public, no-PII AI stack modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-clawdis.url = "github:joshp123/nix-clawdis";
  };

  outputs = { self, nixpkgs, home-manager, nix-clawdis }:
    let
      module = { ... }: {
        imports = [
          nix-clawdis.homeManagerModules.clawdis
          ./modules/ai-stack.nix
        ];
      };
    in {
      homeManagerModules.ai-stack = module;
    };
}
