# The AI tools bundle: the nix-ai-tools packages, as one store path that the
# nightly update-ai-tools job installs into a user-owned Nix profile without
# root. It holds packages and the files those packages ship, nothing written
# by hand: skills, prompts and pi extensions are Home Manager files (content/)
# and change only on a system switch.
#
# Built from nix-ai-tools' own packages and nixpkgs, so a nix-ai-tools bump is
# the only thing that changes this store path.
#
# Arguments
#   nix-ai-tools  the nix-ai-tools flake
#   system        the target system
{ nix-ai-tools, system }:

let
  pkgs = nix-ai-tools.inputs.nixpkgs.legacyPackages.${system};
  ai = nix-ai-tools.packages.${system};

  # bin/ and share/ of the bundle. Package-owned files the harnesses read come
  # with their package: pi packages under share/pi/packages, herdr's pi
  # integration under share/herdr, pi-autoresearch's skills under
  # share/pi-autoresearch. cua-driver is deliberately absent: its app must run
  # from /Applications (layout.sh links it there) and its store copy must never
  # run.
  tools = [
    ai.claude-code
    ai.codex
    ai.pi-coding-agent
    ai.herdr
    ai.pi-web-search
    ai.dash-mcp-server
    ai.xcodebuildmcp
    ai.markit
    ai.markitdown
    ai.qmd
    ai.pi-autoresearch
  ];

  layout = pkgs.runCommand "ai-tools-layout" {
    cuaApp = "${ai.cua-driver}/Applications/CuaDriver.app";
    cuaShare = "${ai.cua-driver}/share/cua-driver";
  } (builtins.readFile ./layout.sh);
in
pkgs.symlinkJoin {
  name = "ai-tools";
  paths = tools ++ [ layout ];
}
