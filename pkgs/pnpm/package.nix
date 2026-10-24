{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  installShellFiles,
  versionCheckHook,
  nodejs-slim,
}:

let
  sources = lib.importJSON ./sources.json;
  inherit (stdenvNoCC.hostPlatform) system;
  supported = builtins.attrNames sources.assets;
  asset =
    sources.assets.${system}
      or (throw "pnpm: unsupported system ${system}; supported: ${lib.concatStringsSep " " supported}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pnpm";
  inherit (sources) version;

  src = fetchurl { inherit (asset) url hash; };

  # The tarball holds `pnpm` and `dist/` at its top level, with no directory.
  sourceRoot = ".";

  nativeBuildInputs = [
    makeWrapper
    installShellFiles
  ];

  # The upstream binary is already stripped; touching it on darwin would
  # break its signature.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 pnpm "$out"/libexec/pnpm/pnpm
    cp -R dist "$out"/libexec/pnpm/dist
    mkdir -p "$out"/bin
    ln -s "$out"/libexec/pnpm/pnpm "$out"/bin/pnpm
    ln -s "$out"/bin/pnpm "$out"/bin/pn
    makeWrapper "$out"/bin/pnpm "$out"/bin/pnpx --add-flag dlx
    ln -s "$out"/bin/pnpx "$out"/bin/pnx
    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    export HOME="$TMPDIR"
    installShellCompletion --cmd pnpm \
      --bash <("$out"/bin/pnpm completion bash) \
      --fish <("$out"/bin/pnpm completion fish) \
      --zsh <("$out"/bin/pnpm completion zsh)
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  # pkgs V5: dist/ (node-gyp and its helpers) sits beside the binary, which
  # looks for dist/node-gyp-bin/node-gyp next to itself.
  # pkgs V4: on darwin the installed binary is the asset's, byte for byte.
  installCheckPhase = ''
    runHook preInstallCheck
    test -f "$out"/libexec/pnpm/dist/node-gyp-bin/node-gyp \
      || { echo "pkgs V5: $out/libexec/pnpm/dist/node-gyp-bin/node-gyp is missing" >&2; exit 1; }
  ''
  + lib.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    cmp pnpm "$out"/libexec/pnpm/pnpm \
      || { echo "pkgs V4: the installed binary differs from the asset's" >&2; exit 1; }
  ''
  + ''
    runHook postInstallCheck
  '';

  passthru = {
    majorVersion = lib.versions.major finalAttrs.version;
    inherit nodejs-slim;
  };

  meta = {
    description = "Fast, disk space efficient package manager for JavaScript";
    homepage = "https://pnpm.io/";
    changelog = "https://github.com/pnpm/pnpm/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "pnpm";
    platforms = supported;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
