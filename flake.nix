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

      mkAiStackModule = { withOpenclaw ? false, extraImports ? [ ] }: { ... }:
        let
          aiStackInputs = { inherit cass; }
            // nixpkgs.lib.optionalAttrs withOpenclaw { inherit openclaw nix-openclaw; };
        in {
          _module.args.aiStackInputs = aiStackInputs;
          imports = [ ./modules/ai-stack.nix ]
            ++ nixpkgs.lib.optionals withOpenclaw [
              nix-openclaw.homeManagerModules.openclaw
              ./modules/openclaw-config.nix
              ./modules/openclaw-documents.nix
            ]
            ++ extraImports;
          nixpkgs.overlays = [ self.overlays.default ]
            ++ nixpkgs.lib.optionals withOpenclaw [ nix-openclaw.overlays.default ];
        };

      aiStackModule = mkAiStackModule { };
      djtbotGatewayModule = mkAiStackModule {
        withOpenclaw = true;
        extraImports = [ ./modules/bots/djtbot-gateway.nix ];
      };
      djtbotMacNodeModule = mkAiStackModule {
        withOpenclaw = true;
        extraImports = [ ./modules/bots/djtbot-mac-node.nix ];
      };

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
