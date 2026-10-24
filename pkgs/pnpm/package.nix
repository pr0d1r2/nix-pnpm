{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
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
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  # Measured on x86_64-linux: the binary needs libc.so.6, libm, libdl,
  # libpthread, librt (glibc, which autoPatchelfHook's bintools brings) and
  # libgcc_s.so.1, which only gcc's lib output carries. The cc itself is
  # never used: the derivation stays stdenvNoCC.
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

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

  # On Linux the binary runs only once its interpreter is set, and the
  # completions below run it, so autoPatchelf runs here rather than as the
  # hook's own postFixup step.
  dontAutoPatchelf = true;

  postInstall =
    lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
      autoPatchelf "$out"
    ''
    + lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
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
  + lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    interpreter=$(patchelf --print-interpreter "$out"/libexec/pnpm/pnpm)
    case "$interpreter" in
      ${builtins.storeDir}/*) ;;
      *) echo "pkgs V3: interpreter $interpreter is outside the store" >&2; exit 1 ;;
    esac
    libs=$("$interpreter" --list "$out"/libexec/pnpm/pnpm)
    echo "$libs"
    if grep -q 'not found' <<<"$libs"; then
      echo "pkgs V3: a shared library of the binary is not found" >&2
      exit 1
    fi
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
