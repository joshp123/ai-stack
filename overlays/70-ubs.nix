{ inputs }:
final: prev:
let
  rev = inputs.ubs.rev or "unknown";
  shortRev = inputs.ubs.shortRev or (if rev == "unknown" then rev else builtins.substring 0 7 rev);
  version = "unstable-${shortRev}";
in {
  # Ultimate Bug Scanner (ubs) - bug finding CLI for coding agents
  # https://github.com/Dicklesworthstone/ultimate_bug_scanner
  ubs = prev.stdenvNoCC.mkDerivation {
    pname = "ubs";
    inherit version;

    src = inputs.ubs;

    nativeBuildInputs = [ prev.makeWrapper ];
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      install -Dm755 ubs $out/libexec/ubs/ubs
      install -d $out/libexec/ubs/modules
      install -m755 modules/ubs-*.sh $out/libexec/ubs/modules/

      makeWrapper $out/libexec/ubs/ubs $out/bin/ubs \
        --set UBS_NO_AUTO_UPDATE 1 \
        --prefix PATH : ${prev.lib.makeBinPath [
          prev.ast-grep
          prev.coreutils
          prev.curl
          prev.findutils
          prev.gawk
          prev.gnused
          prev.git
          prev.jq
          prev.ripgrep
        ]}

      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Ultimate Bug Scanner: fast bug-finding assistant for coding agents";
      homepage = "https://github.com/Dicklesworthstone/ultimate_bug_scanner";
      license = licenses.mit;
      platforms = platforms.unix;
      mainProgram = "ubs";
    };
  };
}
