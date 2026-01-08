{ inputs }:
final: prev:
let
  rev = inputs.cass.rev or "unknown";
  shortRev = inputs.cass.shortRev or (if rev == "unknown" then rev else builtins.substring 0 7 rev);
  version = "unstable-${shortRev}";
  opensslCombined = prev.symlinkJoin {
    name = "openssl-combined";
    paths = [ prev.openssl.out prev.openssl.dev ];
  };
in {
  # cass - Cross-agent session search / "collective agent memory" CLI
  # https://github.com/Dicklesworthstone/coding_agent_session_search
  cass = prev.rustPlatform.buildRustPackage {
    pname = "cass";
    inherit version;

    src = inputs.cass;

    cargoLock = {
      lockFile = "${inputs.cass}/Cargo.lock";
      outputHashes = { };
    };

    nativeBuildInputs = [ prev.pkg-config ];
    buildInputs = [ prev.openssl prev.onnxruntime ];
    env = {
      OPENSSL_NO_VENDOR = "1";
      OPENSSL_DIR = "${opensslCombined}";
      OPENSSL_INCLUDE_DIR = "${opensslCombined}/include";
      OPENSSL_LIB_DIR = "${opensslCombined}/lib";
      PKG_CONFIG_PATH = "${opensslCombined}/lib/pkgconfig";
      ORT_LIB_LOCATION = "${prev.onnxruntime.out}/lib";
      ORT_SKIP_DOWNLOAD = "1";
      ORT_PREFER_DYNAMIC_LINK = "1";
    };

    doCheck = false;

    meta = with prev.lib; {
      description = "Cross-agent session search CLI";
      homepage = "https://github.com/Dicklesworthstone/coding_agent_session_search";
      license = licenses.mit;
      platforms = platforms.unix;
      mainProgram = "cass";
    };
  };
}
