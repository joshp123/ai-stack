# Everything written by hand for the three harnesses: skills, pi extensions and
# the global prompts, as store trees. Home Manager (modules/home/ai-profile.nix)
# and nix-darwin (modules/darwin/codex-defaults.nix) link them from the system
# generation, so they change only on a system switch, never in the nightly
# tools update.
#
# A few entries are files a package ships, which must match its binary:
# cua-driver's skill, pi-autoresearch's skills and herdr's pi extension. Those
# are links to fixed paths in the AI tools profile, never store paths, so a
# tools update changes them without a switch. Each fixed path has its line in
# modules/darwin/update-ai-tools/ai-tools-smoke.sh.
#
# Arguments
#   pkgs               nixpkgs for the target system
#   openai-plugins     OpenAI's plugins repo (filled in by ai-stack's flake)
#   profile            the AI tools profile, e.g. ~/.local/state/nix/profiles/ai
#   extraClaudeSkills  directories of extra skills for Claude Code (private skills)
#   piCollections      extra pi skill collections:
#                      { name = "apple/xcode-27"; collection = ./COLLECTION.md; skills = ./dir; }
#   piExtensions       extra pi extensions: { name = "foo.ts"; path = ./foo.ts; }
{ pkgs, openai-plugins, profile
, extraClaudeSkills ? [ ], piCollections ? [ ], piExtensions ? [ ] }:

let
  inProfile = path: "${profile}/${path}";

  skills = import ./skills.nix {
    inherit pkgs openai-plugins inProfile extraClaudeSkills piCollections;
  };

  authoredPiExtensions = [
    { name = "progressive-resources.ts"; path = ../extensions/progressive-resources.ts; }
    { name = "responses-v2-compaction"; path = ../extensions/responses-v2-compaction; }
    { name = "subagent"; path = ../extensions/subagent; }
    { name = "claude-system-prompt-compat.ts"; path = ../extensions/claude-system-prompt-compat.ts; }
  ] ++ piExtensions;
in
{
  inherit (skills) piSkills claudeSkills codexSkills;

  # ~/.pi/agent/extensions: the authored extensions plus herdr's.
  piExtensions = pkgs.linkFarm "pi-extensions" (authoredPiExtensions ++ [
    { name = "herdr-agent-state.ts"; path = inProfile "share/herdr/integrations/pi/herdr-agent-state.ts"; }
  ]);

  # The authored extensions alone: what update-ai-tools loads against a new pi
  # before installing it.
  authoredPiExtensions = pkgs.linkFarm "pi-extensions-authored" authoredPiExtensions;

  claudeMd = pkgs.concatText "CLAUDE.md" [
    ../docs/agents/GLOBAL_PREAMBLE.md
    ../docs/agents/GLOBAL_CLAUDE_APPENDIX.md
  ];
  rulesMd = ../docs/agents/rules.md;
  modelsMd = ../docs/agents/models.md;
}
