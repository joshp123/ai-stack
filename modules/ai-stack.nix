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
      ".codex/AGENTS.md".source = ../docs/agents/GLOBAL_CODEX.md;
      ".claude/CLAUDE.md".source = ../docs/agents/GLOBAL_CLAUDE.md;

      ".codex/skills".source = ../skills;
      ".claude/skills".source = ../skills;
    };
  } // (lib.mkIf (lib.hasAttrByPath [ "programs" "clawdbot" ] config) {
    programs.clawdbot.reloadScript.enable = lib.mkDefault true;
  });
}
