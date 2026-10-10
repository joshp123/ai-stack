# The AI bundle: every AI tool plus its config and skills, as one store path
# that a nightly job installs into a user-owned Nix profile. The system never
# contains the tools; it points at fixed paths under this bundle (README.md).
#
# Arguments
#   pkgs            nixpkgs for the target system
#   nix-ai-tools    the nix-ai-tools flake (filled in by ai-stack's flake)
#   openai-plugins  OpenAI's plugins repo (filled in by ai-stack's flake)
#   rev             provenance string written to share/ai/rev
#   extraSkills     directories of extra skills for Claude Code (private skills)
#   piCollections   extra pi skill collections:
#                   { name = "apple/xcode-27"; collection = ./COLLECTION.md; skills = ./dir; }
#   piExtensions    extra pi extensions: { name = "foo.ts"; path = ./foo.ts; }
{ pkgs, nix-ai-tools, openai-plugins, rev ? "unknown"
, extraSkills ? [ ], piCollections ? [ ], piExtensions ? [ ] }:

let
  lib = pkgs.lib;
  ai = nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system};

  # bin/ of the bundle. cua-driver is deliberately absent: its app must run from
  # /Applications (layout.sh links it there) and its store copy must never run.
  tools = [
    ai.claude-code
    ai.codex
    ai.pi-coding-agent
    ai.herdr
    ai.pi-web-search
    ai.pi-agent-browser-native
    ai.agent-browser
    ai.dash-mcp-server
    ai.xcodebuildmcp
    ai.markit
    ai.markitdown
    ai.qmd
    ai.pi-autoresearch
  ];

  skills = import ./skills.nix { inherit pkgs lib ai openai-plugins extraSkills piCollections; };

  piExtensionLinks = pkgs.linkFarm "pi-extensions" ([
    { name = "herdr-agent-state.ts"; path = "${ai.herdr}/share/herdr/integrations/pi/herdr-agent-state.ts"; }
    { name = "progressive-resources.ts"; path = ../extensions/progressive-resources.ts; }
    { name = "responses-v2-compaction"; path = ../extensions/responses-v2-compaction; }
    { name = "subagent"; path = ../extensions/subagent; }
    { name = "claude-system-prompt-compat.ts"; path = ../extensions/claude-system-prompt-compat.ts; }
  ] ++ piExtensions);

  claudeAgents = pkgs.concatText "CLAUDE.md" [
    ../docs/agents/GLOBAL_PREAMBLE.md
    ../docs/agents/GLOBAL_CLAUDE_APPENDIX.md
  ];

  layout = pkgs.runCommand "ai-home-layout" {
    inherit claudeAgents rev;
    piExtensions = piExtensionLinks;
    piSkills = skills.pi;
    claudeSkills = skills.claude;
    codexSkills = skills.codex;
    rulesMd = ../docs/agents/rules.md;
    modelsMd = ../docs/agents/models.md;
    cuaApp = "${ai.cua-driver}/Applications/CuaDriver.app";
  } (builtins.readFile ./layout.sh);
in
pkgs.symlinkJoin {
  name = "ai-home";
  paths = tools ++ [ layout ];
}
