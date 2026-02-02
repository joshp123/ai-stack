{
  description = "ai-stack: public, no-PII AI stack modules";

  nixConfig = {
    fallback = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    openclaw = {
      url = "github:openclaw/openclaw";
      flake = false;
    };
    nix-openclaw.url = "github:openclaw/nix-openclaw";
    ubs = {
      url = "github:Dicklesworthstone/ultimate_bug_scanner";
      flake = false;
    };
    cass = {
      url = "github:Dicklesworthstone/coding_agent_session_search";
      flake = false;
    };
    dev-browser = {
      url = "github:joshp123/dev-browser-go";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, openclaw, nix-openclaw, ubs, cass, dev-browser }:
    let
      aiStackOverlays = import ./overlays { inputs = { inherit ubs cass dev-browser; }; };
      module = { ... }:
        let
          aiStackInputs = { inherit openclaw nix-openclaw ubs cass dev-browser; };
        in {
        _module.args.aiStackInputs = aiStackInputs;
        imports = [
          nix-openclaw.homeManagerModules.openclaw
          ./modules/ai-stack.nix
        ];
        nixpkgs.overlays = [
          nix-openclaw.overlays.default
          self.overlays.default
        ];
      };
    in {
      overlays.default = nixpkgs.lib.composeManyExtensions aiStackOverlays;
      homeManagerModules.ai-stack = module;
    };
}
