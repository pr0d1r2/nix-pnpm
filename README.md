# nix-pnpm

pnpm 12, the JavaScript package manager, as a Nix flake on the fleet's
pinned nixpkgs ([nixpkgs-lock](https://github.com/pr0d1r2/nixpkgs-lock),
nixos-26.05), for aarch64-darwin, x86_64-darwin, x86_64-linux and
aarch64-linux. It packages upstream's release binaries, follows the newest
stable 12.x, and works as the `pnpm` argument of nixpkgs' `fetchPnpmDeps`
and `pnpmConfigHook`.

## Why

The pin's newest pnpm is `pnpm_12` 12.9.0, and projects already declare a
newer 12.x in `packageManager` (Orca asks for 12.14.0). nixos-26.05 is a
stable branch, so it takes backports, not new pnpm releases. This flake
keeps 12.14.0 or newer, built against the same nixpkgs as the rest of the
fleet.

It does not build pnpm from source. Measured on the pin, both nixpkgs
recipes fail on 12.15.0: the npm tarball is only a stub that downloads the
real binary on first run, and the Rust source build needs a generated file
the release tag does not carry. The record is in [`SPEC.md`](SPEC.md) §R.

## Use it

```nix
{
  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";
    nix-pnpm = {
      url = "github:pr0d1r2/nix-pnpm";
      inputs.nixpkgs-lock.follows = "nixpkgs-lock";
    };
  };
}
```

- `nix-pnpm.packages.<system>.pnpm` (also `default`): `pnpm`, `pnpx`,
  `pn` and `pnx`, with bash, fish and zsh completions.
- `nix-pnpm.overlays.default` sets `pnpm_12` and nothing else. Your
  `pnpm` stays the pin's unless you point it at `pnpm_12` yourself.

To fetch a project's dependencies with it:

```nix
pnpmDeps = pkgs.fetchPnpmDeps {
  inherit (finalAttrs) pname version src;
  pnpm = nix-pnpm.packages.${system}.pnpm;
  fetcherVersion = 4;
  hash = "sha256-…";
};
nativeBuildInputs = [ pnpm pkgs.pnpmConfigHook pnpm.nodejs-slim ];
```

The deps hash depends on the pnpm that fetched it, so moving from the
pin's pnpm to this one changes it. It can also differ between darwin and
Linux: pnpm 12.15.0 leaves an empty `v11/links/` directory in the store on
darwin and not on Linux.

## Binary cache

CI pushes what it builds on `main` to `pr0d1r2.cachix.org`, and checks
afterwards that the cache really holds every path. The flake's
`nixConfig` names the substituter:

```text
https://pr0d1r2.cachix.org
pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=
```

## Updates

`scripts/bump-pnpm.sh` moves `pkgs/pnpm/sources.json` to the newest stable
12.x. It never takes a prerelease or a 13.x, never goes below 12.14.0, and
takes each hash from GitHub's own digest of the asset, checked against a
download. A daily workflow goes red when upstream is ahead. It does not
open pull requests: a person runs the bump and the gate decides.

## How it is built

The repository follows [paradigm](https://github.com/pr0d1r2/paradigm):
the spec first ([`SPEC.md`](SPEC.md) and one per directory), a gate laid
before product code, tests before scripts, one change per commit. The
same `hk.pkl` gate runs on commit, on push and in CI. It was written by an
LLM; see [`docs/LLM-DISCLAIMER.md`](docs/LLM-DISCLAIMER.md).

## License

MIT, as pnpm. See [`LICENSE`](LICENSE).
