{
  lib,
  config,
  pkgs,
  ...
}:
let
  # Temporary vanilla Codex trial requested in Codex thread
  # 019e88ac-5d8e-73a3-a101-84735a0fc85e. This normally concatenates
  # GLOBAL_PREAMBLE.md plus GLOBAL_CODEX_APPENDIX.md; keep the deployed
  # ~/.codex/AGENTS.md minimal until the global prompt is restored.
  codexAgents = pkgs.writeText "codex-agents.md" "this user is Josh\n";
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

  baseSkills = ../skills;
  availableSkillNames = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir baseSkills)
  );
  piAutoresearchSkills = lib.optionals (builtins.hasAttr "pi-autoresearch" pkgs) [
    "${pkgs.pi-autoresearch}/share/pi-autoresearch/skills"
  ];
  extraSkills = piAutoresearchSkills;
  skillsDir =
    if extraSkills == [ ] then
      baseSkills
    else
      pkgs.symlinkJoin {
        name = "ai-stack-skills";
        paths = [ baseSkills ] ++ extraSkills;
      };
  piSkillNames = config.programs.aiStack.piSkillNames;
  piSkillsDir =
    if piSkillNames == null then
      skillsDir
    else
      pkgs.linkFarm "ai-stack-pi-skills" (
        map (name: {
          inherit name;
          path = "${baseSkills}/${name}";
        }) piSkillNames
      );

in
{
  options.programs.aiStack.piSkillNames = lib.mkOption {
    type = lib.types.nullOr (lib.types.listOf (lib.types.enum availableSkillNames));
    default = null;
    example = [
      "ask-questions-if-underspecified"
      "skill-creator"
    ];
    description = ''
      Names from ai-stack's public skill directory to expose to Pi. The default
      null value preserves the complete shared skill tree. Set a list, including
      an empty list, to give Pi an explicit allowlist without changing the
      Claude or Codex skill sources.
    '';
  };

  imports = [
    ./cass.nix
    ./ghostty.nix
    ./pi-coding-agent.nix
    ./zsh.nix
  ];

  config = lib.mkMerge [
    {
      home.file = {
        ".codex/AGENTS.md".source = codexAgents;
        ".codex/AGENTS.md".force = true;
        ".pi/agent/AGENTS.md".source = piAgents;
        ".pi/agent/AGENTS.md".force = true;
        ".claude/CLAUDE.md".source = claudeAgents;
        ".claude/CLAUDE.md".force = true;
        ".config/ai/rules.md".source = ../docs/agents/rules.md;
        ".config/ai/rules.md".force = true;
        ".config/ai/models.md".source = ../docs/agents/models.md;
        ".config/ai/models.md".force = true;

        ".pi/agent/skills".source = piSkillsDir;
        ".pi/agent/skills".force = true;
        ".claude/skills".source = skillsDir;
        ".claude/skills".force = true;
      };
    }
  ];
}
