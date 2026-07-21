{
  lib,
  pkgs,
  inputs ? { },
  aiStackInputs ? { },
  ...
}:
let
  effectiveInputs = (pkgs.inputs or { }) // aiStackInputs // inputs;
  openclawInput = effectiveInputs.openclaw;
  substituteScript =
    replacements: path:
    lib.replaceStrings
      (map (replacement: replacement.from) replacements)
      (map (replacement: replacement.to) replacements)
      (builtins.readFile path);
  openclawDocs = pkgs.runCommand "openclaw-documents" { } (
    substituteScript [
      {
        from = "@buildOpenclawDocuments@";
        to = "${../scripts/build-openclaw-documents.sh}";
      }
      {
        from = "@documentsDir@";
        to = "${../documents}";
      }
      {
        from = "@openclawUpstreamAgents@";
        to = "${openclawInput}/docs/reference/templates/AGENTS.md";
      }
      {
        from = "@joshAgents@";
        to = "${../documents/AGENTS.josh.md}";
      }
    ] ../scripts/build-openclaw-documents-derivation.sh
  );
in
{
  programs.openclaw = {
    documents = lib.mkDefault openclawDocs;
    reloadScript.enable = lib.mkDefault true;
  };
}
