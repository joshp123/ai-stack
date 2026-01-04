{ lib, config, ... }:
{
  imports = [
    ./codex-config.nix
    ./clawdbot-config.nix
    ./zsh.nix
  ];

  config = {
    programs.clawdbot.documents = lib.mkDefault ../documents;

    home.file = {
      ".codex/AGENTS.md".source = ../docs/agents/CODEX.md;
      ".claude/CLAUDE.md".source = ../docs/agents/CLAUDE.md;

      ".codex/skills".source = ../skills;
      ".claude/skills".source = ../skills;
    };
  } // (lib.mkIf (lib.hasAttrByPath [ "programs" "clawdbot" ] config) {
    programs.clawdbot.reloadScript.enable = lib.mkDefault true;
  });
}
