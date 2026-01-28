{ lib, config, pkgs, inputs ? {}, aiStackInputs ? {}, ... }:
let
  codexAgents = pkgs.concatTextFile {
    name = "codex-agents.md";
    files = [
      ../docs/agents/GLOBAL_PREAMBLE.md
      ../docs/agents/GLOBAL_CODEX_APPENDIX.md
    ];
  };
  piAgents = pkgs.concatTextFile {
    name = "pi-agents.md";
    files = [
      ../docs/agents/GLOBAL_PREAMBLE.md
      ../docs/agents/GLOBAL_PI_APPENDIX.md
    ];
  };
  claudeAgents = pkgs.concatTextFile {
    name = "claude-agents.md";
    files = [
      ../docs/agents/GLOBAL_PREAMBLE.md
      ../docs/agents/GLOBAL_CLAUDE_APPENDIX.md
    ];
  };

  effectiveInputs = (pkgs.inputs or {}) // aiStackInputs // inputs;

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

  moltbotInput =
    if effectiveInputs ? moltbot
    then effectiveInputs.moltbot
    else null;
  moltbotUpstreamAgents =
    if moltbotInput != null
    then "${moltbotInput}/docs/reference/templates/AGENTS.md"
    else null;

  moltbotDocs =
    if moltbotUpstreamAgents != null then
      pkgs.runCommand "moltbot-documents" {} ''
        bash ${../scripts/build-moltbot-documents.sh} \
          ${../documents} \
          ${moltbotUpstreamAgents} \
          ${../documents/AGENTS.josh.md} \
          $out
      ''
    else
      ../documents;
in
{
  imports = [
    ./codex-config.nix
    ./moltbot-config.nix
    ./cass.nix
    ./ghostty.nix
    ./pi-coding-agent.nix
    ./zsh.nix
  ];

  config = lib.mkMerge [
    {
      programs.moltbot.documents = lib.mkDefault moltbotDocs;

      home.file = {
        ".codex/AGENTS.md".source = codexAgents;
        ".codex/AGENTS.md".force = true;
        ".pi/agent/AGENTS.md".source = piAgents;
        ".pi/agent/AGENTS.md".force = true;
        ".claude/CLAUDE.md".source = claudeAgents;
        ".claude/CLAUDE.md".force = true;

        ".codex/skills".source = skillsDir;
        ".codex/skills".force = true;
        ".pi/agent/skills".source = skillsDir;
        ".pi/agent/skills".force = true;
        ".claude/skills".source = skillsDir;
        ".claude/skills".force = true;
      };
    }
    (lib.mkIf (lib.hasAttrByPath [ "programs" "moltbot" ] config) {
      programs.moltbot.reloadScript.enable = lib.mkDefault true;
      home.activation.oracleKeychainAccess =
        lib.mkIf (config.programs.moltbot.firstParty.oracle.enable or false)
          (lib.hm.dag.entryAfter [ "writeBoundary" ]
            (builtins.readFile ../scripts/oracle-keychain-access.sh));
    })
  ];
}
