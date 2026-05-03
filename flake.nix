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
    cass = {
      url = "github:Dicklesworthstone/coding_agent_session_search";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, openclaw, nix-openclaw, cass }:
    let
      aiStackOverlays = import ./overlays { inputs = { inherit cass; }; };

      mkAiStackModule = extraImports: { ... }:
        let
          aiStackInputs = { inherit openclaw nix-openclaw cass; };
        in {
          _module.args.aiStackInputs = aiStackInputs;
          imports = [
            nix-openclaw.homeManagerModules.openclaw
            ./modules/ai-stack.nix
          ] ++ extraImports;
          nixpkgs.overlays = [
            nix-openclaw.overlays.default
            self.overlays.default
          ];
        };

      aiStackModule = mkAiStackModule [ ];
      djtbotGatewayModule = mkAiStackModule [ ./modules/bots/djtbot-gateway.nix ];
      djtbotMacNodeModule = mkAiStackModule [ ./modules/bots/djtbot-mac-node.nix ];

    in {
      overlays.default = nixpkgs.lib.composeManyExtensions aiStackOverlays;

      homeManagerModules = {
        ai-stack = aiStackModule;

        # Bot roles (opt-in)
        djtbot-gateway = djtbotGatewayModule;
        djtbot-mac-node = djtbotMacNodeModule;

        # Raw role modules (for advanced composition)
        bots = {
          djtbot-gateway = import ./modules/bots/djtbot-gateway.nix;
          djtbot-mac-node = import ./modules/bots/djtbot-mac-node.nix;
        };
      };
    };
}
