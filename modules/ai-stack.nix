{ lib, config, pkgs, inputs ? {}, ... }:
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

  effectiveInputs = (pkgs.inputs or {}) // inputs;

  baseSkills = ../skills;
  devBrowserSkill =
    if effectiveInputs ? dev-browser
    then
      (if lib.hasAttrByPath [ "packages" pkgs.system "dev-browser-skill" ] effectiveInputs.dev-browser
       then effectiveInputs.dev-browser.packages.${pkgs.system}.dev-browser-skill
       else null)
    else null;
  extraSkills = lib.optionals (devBrowserSkill != null) [ devBrowserSkill ];
  skillsDir =
    if extraSkills == []
    then baseSkills
    else pkgs.symlinkJoin {
      name = "ai-stack-skills";
      paths = [ baseSkills ] ++ extraSkills;
    };

  clawdbotInput =
    if effectiveInputs ? clawdbot
    then effectiveInputs.clawdbot
    else null;
  clawdbotUpstreamAgents =
    if clawdbotInput != null
    then "${clawdbotInput}/docs/reference/templates/AGENTS.md"
    else null;

  clawdbotDocs =
    if clawdbotUpstreamAgents != null then
      pkgs.runCommand "clawdbot-documents" {} ''
        bash ${../scripts/build-clawdbot-documents.sh} \
          ${../documents} \
          ${clawdbotUpstreamAgents} \
          ${../documents/AGENTS.josh.md} \
          $out
      ''
    else
      ../documents;
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
      programs.clawdbot.documents = lib.mkDefault clawdbotDocs;

      home.file = {
        ".codex/AGENTS.md".source = codexAgents;
        ".codex/AGENTS.md".force = true;
        ".claude/CLAUDE.md".source = claudeAgents;
        ".claude/CLAUDE.md".force = true;

        ".codex/skills".source = skillsDir;
        ".codex/skills".force = true;
        ".claude/skills".source = skillsDir;
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
