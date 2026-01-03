{ lib, ... }:
{
  imports = [
    ./codex-config.nix
  ];

  programs.clawdis.documents = lib.mkDefault ../documents;

  home.file = {
    ".codex/AGENTS.md".source = ../docs/agents/CODEX.md;
    ".claude/CLAUDE.md".source = ../docs/agents/CLAUDE.md;

    ".codex/skills".source = ../skills;
    ".claude/skills".source = ../skills;
  };
}
