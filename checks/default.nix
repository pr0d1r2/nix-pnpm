# Flake checks (checks node): this pnpm as the pin's `fetchPnpmDeps` and
# `pnpmConfigHook` argument, on the fixture project in ./fixture, plus its
# version and the overlay's one attribute. Shell comes from ./*.sh by
# builtins.readFile (`docs/SHELL.md`).
{
  pkgs,
  pnpm,
  # overlays.default, as the root flake exports it.
  overlay,
}:

let
  inherit (pkgs) lib;

  # The pin itself, read from the file the bump writes, never from the
  # derivation under test.
  pinned = (lib.importJSON ../pkgs/pnpm/sources.json).version;
  # Root V9: owner 2026-10-24, Orca's `packageManager`.
  floor = "12.14.0";

  # Checks V1, V3: the fixture's deps as a consumer fetches them. The hash
  # is fixed; a mismatch is red, never updated by itself (checks §C).
  fetch-deps = pkgs.fetchPnpmDeps {
    pname = "nix-pnpm-fixture";
    version = "0.0.0";
    src = ./fixture;
    inherit pnpm;
    fetcherVersion = 4;
    # Measured 2026-10-24: on darwin pnpm 12.15.0 leaves an empty
    # `v11/links/` in the store and on Linux it does not; the two tarballs
    # differ by that directory alone, so the hash is per OS.
    hash =
      if pkgs.stdenvNoCC.hostPlatform.isDarwin then
        "sha256-hieVZKtXaEJNz2y7Yn1eh85k0tfg1zEd1xJnsna0OqQ="
      else
        "sha256-duv8c+5cLVlcEAYwNA06NOROBMNHkzHlW/MDMG7yRcE=";
    # Checks V3: inside the fetcher, after it exports pm_on_fail=ignore and
    # in the fixture whose `packageManager` is pnpm@12.14.0.
    prePnpmInstall = builtins.readFile ./version.sh;
    EXPECTED_VERSION = pinned;
    FLOOR_VERSION = floor;
  };
in
{
  inherit fetch-deps;

  # Checks §I `version`, root V9. Offline (checks V4).
  version =
    pkgs.runCommand "nix-pnpm-check-version"
      {
        nativeBuildInputs = [
          pnpm
          pkgs.writableTmpDirAsHomeHook
        ];
        EXPECTED_VERSION = pinned;
        FLOOR_VERSION = floor;
      }
      ''
        ${builtins.readFile ./version.sh}
        touch "$out"
      '';

  # Checks V2, V3: a consumer's build over the fetched deps, offline. The
  # hook runs from ./config-hook.sh, which keeps its log; $out holds it.
  config-hook = pkgs.stdenvNoCC.mkDerivation {
    pname = "nix-pnpm-check-config-hook";
    version = "0.0.0";
    src = ./fixture;
    pnpmDeps = fetch-deps;
    nativeBuildInputs = [
      pnpm
      pkgs.pnpmConfigHook
      pnpm.nodejs-slim
    ];
    # The hook runs in the buildPhase, where its log is kept, not on its own
    # after the configurePhase.
    dontPnpmConfigure = true;
    EXPECTED_VERSION = pinned;
    buildPhase = builtins.readFile ./config-hook.sh;
    installPhase = ''install -Dm644 install.log "$out"/install.log'';
  };

  # Checks V5, root V2: the overlay sets exactly pnpm_12, so the pin's
  # `pnpm` stays the pin's. An attribute name never forces its value.
  overlay =
    let
      names = builtins.attrNames (overlay pkgs pkgs);
      expected = [ "pnpm_12" ];
      message = "checks V5: overlays.default sets ${builtins.toJSON names}, not exactly ${builtins.toJSON expected} (root V2)";
    in
    assert lib.assertMsg (names == expected) message;
    pkgs.runCommand "nix-pnpm-check-overlay" { } ''touch "$out"'';
}
