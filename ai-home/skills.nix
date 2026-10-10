# Skill trees for the three harnesses.
#   pi      curated collections (a COLLECTION.md per directory, read by the
#           progressive-resources extension), never the whole public tree
#   Claude  every public skill except anti-slop-output (a plugin provides it),
#           pi-autoresearch's skills, and the consumer's extra skills
#   Codex   a fixed list of public skills, served from /etc/codex/skills
{ pkgs, lib, ai, openai-plugins, extraSkills, piCollections }:

let
  publicSkills = ../skills;

  directoryNames = root:
    builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir root));

  links = prefix: source: names:
    map (name: { name = "${prefix}${name}"; path = "${source}/${name}"; }) names;

  # One pi collection: its COLLECTION.md plus one link per skill directory.
  collectionLinks = { name, collection, skills }:
    [ { name = "${name}/COLLECTION.md"; path = collection; } ]
    ++ links "${name}/" skills (directoryNames skills);

  # OpenAI's build-macos-apps skills with their Codex-app-only instructions
  # removed (openai-skills/*.sed); the manifest records the source and edits.
  openaiSkillsSource = openai-plugins + "/plugins/build-macos-apps/skills";
  openaiSkills = pkgs.stdenvNoCC.mkDerivation {
    name = "openai-build-macos-apps-skills";
    dontUnpack = true;
    builder = "${pkgs.bash}/bin/bash";
    args = [
      ./openai-skills/build.sh
      "${pkgs.coreutils}/bin/cp"
      "${pkgs.coreutils}/bin/mkdir"
      "${pkgs.findutils}/bin/find"
      "${pkgs.coreutils}/bin/unlink"
      "${pkgs.gnused}/bin/sed"
      openaiSkillsSource
      ./openai-skills/adapt-build-run-debug.sed
      ./openai-skills/adapt-swiftui-patterns.sed
      ./openai-skills/manifest.json
    ];
  };

  pi = pkgs.linkFarm "pi-skills" (
    [ { name = "shared/ai-stack/COLLECTION.md"; path = ./pi-collections/shared-ai-stack/COLLECTION.md; } ]
    ++ links "shared/ai-stack/" publicSkills [ "grill-me" "skill-creator" "summarize" ]
    ++ [ { name = "openai/build-macos-apps/COLLECTION.md"; path = ./pi-collections/openai-build-macos-apps/COLLECTION.md; } ]
    ++ links "openai/build-macos-apps/" openaiSkills (directoryNames openaiSkillsSource)
    # cua-driver ships exactly one skill; naming it avoids reading a store
    # path at evaluation time.
    ++ [
      { name = "tools/cua-driver/COLLECTION.md"; path = ./pi-collections/tools-cua-driver/COLLECTION.md; }
      { name = "tools/cua-driver/cua-driver"; path = "${ai.cua-driver}/share/cua-driver/skills/cua-driver"; }
    ]
    ++ lib.concatMap collectionLinks piCollections
  );

  claude = pkgs.symlinkJoin {
    name = "claude-skills";
    paths = [
      (pkgs.linkFarm "claude-public-skills"
        (links "" publicSkills (lib.remove "anti-slop-output" (directoryNames publicSkills))))
      "${ai.pi-autoresearch}/share/pi-autoresearch/skills"
    ] ++ extraSkills;
  };

  codex = pkgs.linkFarm "codex-skills" (links "" publicSkills [
    "ask-questions-if-underspecified"
    "frontend-design"
    "markdown-converter"
    "summarize"
    "summarize-youtube"
    "trmnl-image-generator"
    "update-ai-tools"
    "xcodebuildmcp-cli"
  ]);
in
{
  inherit pi claude codex;
}
