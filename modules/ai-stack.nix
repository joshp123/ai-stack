{ lib, config, ... }:
{
  imports = [
    ./codex-config.nix
  ];

  programs.clawdis.documents = lib.mkDefault ../documents;

  config = lib.mkIf (lib.hasAttrByPath [ "programs" "clawdis" ] config) {
    programs.clawdis.reloadScript.enable = lib.mkDefault true;
  };

  home.file = {
    ".codex/AGENTS.md".source = ../docs/agents/CODEX.md;
    ".claude/CLAUDE.md".source = ../docs/agents/CLAUDE.md;

    ".codex/skills".source = ../skills;
    ".claude/skills".source = ../skills;
  };
}
