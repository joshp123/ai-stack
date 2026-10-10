{
  description = "ai-stack: public, no-PII AI stack modules";

  nixConfig = {
    fallback = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    cass = {
      url = "github:Dicklesworthstone/coding_agent_session_search";
      flake = false;
    };
    prime-agent-src = {
      url = "github:PrimeIntellect-ai/prime-agent/v0.7.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, cass, prime-agent-src }:
    let
      aiStackOverlays = import ./overlays { inputs = { inherit cass prime-agent-src; }; };

      aiStackModule = { ... }: {
        imports = [ ./modules/ai-stack.nix ];
        nixpkgs.overlays = [ self.overlays.default ];
      };
    in {
      overlays.default = nixpkgs.lib.composeManyExtensions aiStackOverlays;

      packages = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in {
          prime-agent = pkgs.prime-agent;
        });

      homeManagerModules = {
        ai-stack = aiStackModule;
      };
    };
}
