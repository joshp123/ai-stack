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

  openclawInput =
    if effectiveInputs ? openclaw
    then effectiveInputs.openclaw
    else null;
  openclawUpstreamAgents =
    if openclawInput != null
    then "${openclawInput}/docs/reference/templates/AGENTS.md"
    else null;

  openclawDocs =
    if openclawUpstreamAgents != null then
      pkgs.runCommand "openclaw-documents" {} ''
        bash ${../scripts/build-openclaw-documents.sh} \
          ${../documents} \
          ${openclawUpstreamAgents} \
          ${../documents/AGENTS.josh.md} \
          $out
      ''
    else
      ../documents;
in
{
  imports = [
    ./openclaw-config.nix
    ./cass.nix
    ./ghostty.nix
    ./pi-coding-agent.nix
    ./zsh.nix
  ];

  config = lib.mkMerge [
    {
      programs.openclaw.documents = lib.mkDefault openclawDocs;

      home.file = {
        ".codex/AGENTS.md".source = codexAgents;
        ".codex/AGENTS.md".force = true;
        ".pi/agent/AGENTS.md".source = piAgents;
        ".pi/agent/AGENTS.md".force = true;
        ".claude/CLAUDE.md".source = claudeAgents;
        ".claude/CLAUDE.md".force = true;

        ".pi/agent/skills".source = skillsDir;
        ".pi/agent/skills".force = true;
        ".claude/skills".source = skillsDir;
        ".claude/skills".force = true;
      };
    }
    (lib.mkIf (lib.hasAttrByPath [ "programs" "openclaw" ] config) {
      programs.openclaw.reloadScript.enable = lib.mkDefault true;
      home.activation.oracleKeychainAccess =
        lib.mkIf (config.programs.openclaw.firstParty.oracle.enable or false)
          (lib.hm.dag.entryAfter [ "writeBoundary" ]
            (builtins.readFile ../scripts/oracle-keychain-access.sh));
    })
  ];
}
