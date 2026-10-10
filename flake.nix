{
  description = "ai-stack: a complete AI coding setup for Claude Code, Codex and pi, as Nix";

  nixConfig = {
    fallback = false;
    extra-substituters = [ "https://joshp123-nix-ai-tools.cachix.org?priority=30" ];
    extra-trusted-public-keys = [
      "joshp123-nix-ai-tools.cachix.org-1:JvngUIbNs+IgAmU07ecK7JYV5t0/LD+ng1bXQCRJWjo="
    ];
  };

  inputs = {
    # The AI tool packages, bumped hourly by their own CI. Their nixpkgs is the
    # only nixpkgs here, so the bundle's glue derivations share it.
    nix-ai-tools.url = "github:joshp123/nix-ai-tools";
    nixpkgs.follows = "nix-ai-tools/nixpkgs";
    # OpenAI's build-macos-apps plugin: the source of one pi skill collection.
    openai-plugins = {
      url = "github:openai/plugins/11c74d6ba24d3a6d48f54a194cd00ef3beea18f9";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-ai-tools, openai-plugins }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      lib = {
        # Builds the AI bundle: every tool plus its config and skills, laid out
        # for the user profile. Arguments: ai-home/default.nix.
        mkAiHome = args: import ./ai-home ({ inherit nix-ai-tools openai-plugins; } // args);
      };

      homeManagerModules = {
        ai-profile = import ./modules/home/ai-profile.nix;
        zsh = import ./modules/home/zsh.nix;
        ghostty = import ./modules/home/ghostty.nix;
      };

      darwinModules = {
        update-ai-tools = import ./modules/darwin/update-ai-tools.nix;
        codex-defaults = import ./modules/darwin/codex-defaults.nix;
      };

      # The bundle with no private additions: what CI builds, and what you get
      # before plugging in a private repo.
      packages.${system}.ai-home = self.lib.mkAiHome {
        inherit pkgs;
        rev = self.rev or self.dirtyRev or "unknown";
      };
    };
}
