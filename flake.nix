{
  description = "ai-stack: public, no-PII AI stack modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-clawdbot.url = "github:clawdbot/nix-clawdbot";
    ubs = {
      url = "github:Dicklesworthstone/ultimate_bug_scanner";
      flake = false;
    };
    cass = {
      url = "github:Dicklesworthstone/coding_agent_session_search";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-clawdbot, ubs, cass }:
    let
      aiStackOverlays = import ./overlays { inputs = { inherit ubs cass; }; };
      module = { ... }: {
        imports = [
          nix-clawdbot.homeManagerModules.clawdbot
          ./modules/ai-stack.nix
        ];
        nixpkgs.overlays = [
          nix-clawdbot.overlays.default
          self.overlays.default
        ];
      };
    in {
      overlays.default = nixpkgs.lib.composeManyExtensions aiStackOverlays;
      homeManagerModules.ai-stack = module;
    };
}
