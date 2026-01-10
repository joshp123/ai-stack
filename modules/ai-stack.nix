{ lib, config, pkgs, ... }:
let
  codexAgents = pkgs.concatTextFile {
    name = "codex-agents.md";
    files = [
      ../docs/agents/GLOBAL_PREAMBLE.md
      ../docs/agents/GLOBAL_CODEX_APPENDIX.md
    ];
  };
  claudeAgents = pkgs.concatTextFile {
    name = "claude-agents.md";
    files = [
      ../docs/agents/GLOBAL_PREAMBLE.md
      ../docs/agents/GLOBAL_CLAUDE_APPENDIX.md
    ];
  };
in
{
  imports = [
    ./codex-config.nix
    ./clawdbot-config.nix
    ./cass.nix
    ./ghostty.nix
    ./zsh.nix
  ];

  config = lib.mkMerge [
    {
      programs.clawdbot.documents = lib.mkDefault ../documents;

      home.file = {
        ".codex/AGENTS.md".source = codexAgents;
        ".codex/AGENTS.md".force = true;
        ".claude/CLAUDE.md".source = claudeAgents;
        ".claude/CLAUDE.md".force = true;

        ".codex/skills".source = ../skills;
        ".codex/skills".force = true;
        ".claude/skills".source = ../skills;
        ".claude/skills".force = true;
      };
    }
    (lib.mkIf (lib.hasAttrByPath [ "programs" "clawdbot" ] config) {
      programs.clawdbot.reloadScript.enable = lib.mkDefault true;
      home.activation.oracleKeychainAccess =
        lib.mkIf (config.programs.clawdbot.firstParty.oracle.enable or false)
          (lib.hm.dag.entryAfter [ "writeBoundary" ]
            (builtins.readFile ../scripts/oracle-keychain-access.sh));
    })
  ];
}
