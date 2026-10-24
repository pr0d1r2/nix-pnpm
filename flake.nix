{
  description = "pnpm 12 for the fleet's pinned nixpkgs, from upstream's release binaries";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [
      "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM="
    ];
  };

  # ONE input (root V1, D1). nixpkgs-lock is the fleet's sole nixpkgs
  # authority and nixpkgs follows it, so every consumer resolves to the same
  # nixpkgs rev and the cachix binaries hit.
  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";
  };

  outputs =
    { nixpkgs, ... }:
    let
      # x86_64-darwin is built locally until CI carries it (root T9).
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          pnpm = pkgs.callPackage ./pkgs/pnpm/package.nix { };
        in
        {
          inherit pnpm;
          default = pnpm;
        }
      );

      # Exactly one attribute (root V2): the pin's own `pnpm` stays as it is.
      overlays.default = final: _prev: {
        pnpm_12 = final.callPackage ./pkgs/pnpm/package.nix { };
      };
    };
}
