{
  lib,
  buildNpmPackage,
  cacert,
  cairo,
  fontconfig,
  freetype,
  giflib,
  libjpeg,
  libpng,
  makeWrapper,
  nodejs_22,
  nodejs-slim_22,
  pkg-config,
  pango,
  pixman,
  python3,
  uv,
  primeAgentSrc,
}:

let
  package = builtins.fromJSON (builtins.readFile "${primeAgentSrc}/package.json");
in
buildNpmPackage {
  pname = "prime-agent";
  inherit (package) version;
  src = primeAgentSrc;
  nodejs = nodejs_22;

  patches = [
    ../patches/prime-agent/deterministic-model-catalog.patch
    ../patches/prime-agent/responses-v2-compaction.patch
  ];

  npmDepsHash = "sha256-/jVTJAMcstZQm3Y3UA7ukI0knDw7Jj8gBoeEkqnaLF8=";
  npm_config_cafile = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  makeCacheWritable = true;
  npmInstallFlags = [
    "--offline=false"
    "--legacy-peer-deps"
  ];

  nativeBuildInputs = [ makeWrapper pkg-config python3 ];
  buildInputs = [ cairo fontconfig freetype giflib libjpeg libpng pango pixman ];

  installPhase = ''
    runHook preInstall

    packageOut="$out/lib/node_modules/prime-agent"
    mkdir -p "$packageOut" "$out/bin"
    cp -R \
      packages/coding-agent/dist \
      packages/coding-agent/docs \
      packages/coding-agent/examples \
      packages/coding-agent/skills \
      packages/coding-agent/package.json \
      packages/coding-agent/README.md \
      packages/coding-agent/CHANGELOG.md \
      "$packageOut/"
    mkdir -p "$packageOut/node_modules"
    cp -R \
      node_modules/cmake-ts \
      node_modules/koffi \
      node_modules/undici \
      node_modules/zeromq \
      node_modules/@mariozechner \
      node_modules/@silvia-odwyer \
      "$packageOut/node_modules/"

    makeWrapper ${nodejs-slim_22}/bin/node "$out/bin/prime-agent" \
      --add-flags "$packageOut/dist/bundle/cli.js" \
      --prefix PATH : ${lib.makeBinPath [ uv ]} \
      --set PRIME_AGENT_INSTALL_UV 0 \
      --set PI_SKIP_VERSION_CHECK 1 \
      --set PRIME_AGENT_LAUNCHER_PATH "$out/bin/prime-agent"

    runHook postInstall
  '';

  meta = {
    description = "Persistent coding-agent harness with an IPython runtime";
    homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
    license = lib.licenses.mit;
    mainProgram = "prime-agent";
    platforms = lib.platforms.unix;
  };
}
