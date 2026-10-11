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
    # The AI tool packages, bumped hourly by their own CI. The tools bundle is
    # built from their nixpkgs (nix-ai-tools.inputs.nixpkgs), never the
    # consumer's.
    nix-ai-tools.url = "github:joshp123/nix-ai-tools";
    # OpenAI's build-macos-apps plugin: the source of one pi skill collection.
    openai-plugins = {
      url = "github:openai/plugins/11c74d6ba24d3a6d48f54a194cd00ef3beea18f9";
      flake = false;
    };
  };

  outputs = { self, nix-ai-tools, openai-plugins }:
    let
      system = "aarch64-darwin";
      mkContent = args: import ./content ({ inherit openai-plugins; } // args);
    in
    {
      lib = {
        # The AI tools bundle for the user profile: packages only (ai-tools/).
        mkAiTools = { system }: import ./ai-tools { inherit nix-ai-tools system; };
        # The written skills, pi extensions and prompts as store trees
        # (content/default.nix lists the arguments). The modules below use it.
        inherit mkContent;
      };

      homeManagerModules = {
        ai-profile = import ./modules/home/ai-profile.nix { inherit mkContent; };
        zsh = import ./modules/home/zsh.nix;
        ghostty = import ./modules/home/ghostty.nix;
      };

      darwinModules = {
        update-ai-tools = import ./modules/darwin/update-ai-tools.nix;
        codex-defaults = import ./modules/darwin/codex-defaults.nix { inherit mkContent; };
      };

      # What the nightly job installs, and what CI builds.
      packages.${system}.ai-tools = self.lib.mkAiTools { inherit system; };

      # The written trees with no private additions, built in CI. The profile
      # path is a placeholder: the package-owned links dangle here.
      checks.${system}.content =
        let
          pkgs = nix-ai-tools.inputs.nixpkgs.legacyPackages.${system};
          content = mkContent { inherit pkgs; profile = "/nonexistent/ai-profile"; };
        in
        pkgs.linkFarm "ai-content" [
          { name = "pi-skills"; path = content.piSkills; }
          { name = "pi-extensions"; path = content.piExtensions; }
          { name = "claude-skills"; path = content.claudeSkills; }
          { name = "codex-skills"; path = content.codexSkills; }
          { name = "CLAUDE.md"; path = content.claudeMd; }
        ];
    };
}
