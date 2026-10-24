HISTORICAL INPUT. This file is the prompt for the first spec run of this repository.
Once that run lands SPEC.md and its node specs, they are the law; where
they differ from this file, they win. Written 2026-10-24 by an agent
working in nix-orca, from the owner's decision there (nix-orca root T18,
D22), as a handoff to a separate session.

Paradigm: paradigm (`github.com/pr0d1r2/paradigm`), the newest commit
when the run starts (fda10ea on 2026-10-24), with its language pages
`docs/NIX.md` and `docs/SHELL.md`. This repository conforms to the
paradigm process in full: the spec first, a gate laid before product
code, one change per commit, tests before scripts. Process, guardrail
roster and shared conventions come from there; this file states only the
product and its deviations.

nix-pnpm

pnpm 12, the JavaScript package manager, as a Nix flake on the fleet's
pinned nixpkgs, for the four systems the fleet uses, built from upstream's
release and cached on cachix. Shaped like `github.com/pr0d1r2/nix-hk`,
which does the same for hk: read its SPEC.md, flake.nix, pkgs/ and
scripts/ before starting.

# Problem and goals

The fleet's nixpkgs pin (`github.com/pr0d1r2/nixpkgs-lock`, nixos-26.05)
ships pnpm 11.27.0 (`pnpm`) and 10.34.0 (`pnpm_10`), and no pnpm 12.
Upstream projects already require 12. The first consumer is nix-orca:

- Orca (`stablyai/orca`) v1.4.237 declares
  `"packageManager": "pnpm@12.14.0+sha512.c18ba6d8…"` in package.json.
  Its pnpm-lock.yaml is `lockfileVersion: '9.0'`.
- nix-orca's JS deps fetch (`fetchPnpmDeps`) runs the pin's pnpm 11.27.0
  over that lockfile. It works today (nix-orca `nix/linux` R2), but a
  pnpm 12 lockfile change upstream can break it at any bump, and the hash
  of the fetched store depends on the pnpm that fetched it.
- Waiting for nixpkgs is not an option: 26.05 is a stable branch, which
  takes backports, not new major versions.

Goals:

1. `packages.<system>.pnpm` (and `default`): pnpm 12, the newest stable
   12.x release, for aarch64-darwin, x86_64-darwin, x86_64-linux and
   aarch64-linux.
2. `overlays.default` adds exactly `pnpm_12` and nothing else; consumers
   choose whether it replaces their `pnpm`.
3. It works as the `pnpm` argument of nixpkgs' `fetchPnpmDeps` and
   `pnpmConfigHook` (pnpm.fetchDeps and pnpm.configHook in nixpkgs'
   pnpm package), the way nix-orca uses it. Prove that with a check that
   fetches a small fixture's deps with this pnpm.
4. A bump script and workflow that move to the newest stable 12.x and
   nothing else: never a prerelease, never 13.x without an owner
   decision.
5. Built in CI, cached on cachix `pr0d1r2` (Linux only, as nix-orca does;
   darwin is cheap to build from the tarball).

# Upstream facts, measured 2026-10-24

- Releases: `github.com/pnpm/pnpm` tags. Stable 12.x: v12.15.0
  (2026-10-21), v12.14.0 (2026-10-15), v12.13.0, v12.12.1. pnpm still
  ships 11.x (v11.28.8, 2026-10-22) and 10.x in parallel.
- Each 12.x release has standalone binaries as assets:
  `pnpm-{darwin-arm64,darwin-x64,linux-x64,linux-arm64,linux-x64-musl,
  linux-arm64-musl,…}.tar.gz`, plus win32 zips.
- nixpkgs builds pnpm from the npm tarball
  (`https://registry.npmjs.org/pnpm/-/pnpm-<version>.tgz`) through
  `pkgs/development/tools/pnpm/generic.nix` (version + hash), which also
  provides `fetchDeps` and `configHook`. Evaluate first whether
  `callPackage "${pkgs.path}/pkgs/development/tools/pnpm/generic.nix"
  { version = "12.x.y"; hash = …; }` builds 12 unchanged. That keeps the
  fetcher integration nixpkgs maintains, and runs pnpm on the pin's
  nodejs instead of a prebuilt binary. Fall back to the release binaries
  only with a measured reason.
- Verify the npm tarball against upstream's own integrity data (the
  registry's `dist.integrity` sha512, and the `packageManager` sha512
  form) before trusting a hash; record the source of each hash.

# Decisions

D1. One input: `nixpkgs-lock`, with `nixpkgs.follows =
    "nixpkgs-lock/nixpkgs"`, as nix-hk. No second nixpkgs, no
    flake-utils.
D2. Build from the npm tarball on the pin's nodejs (generic.nix), unless
    the spec run measures that it fails; then the release binaries,
    with the reason in the spec.
D3. Track 12.x only. The bump picks the newest stable 12.x tag, writes
    only the version and hash (one sources file), and refuses a
    prerelease. A new major is an owner decision.
D4. Checks: `pnpm --version` equals the pinned version; a fixture
    project's deps fetch through `fetchPnpmDeps` with this pnpm builds
    and is reproducible (`--rebuild`); a pnpm 12 lockfile is read
    without a "lockfile version" warning.
D5. Cache: Linux outputs pushed to cachix `pr0d1r2` from CI only; never
    from a developer machine.
D6. Public from the start (the owner's decision), MIT like pnpm. No
    private repository is ever named in committed text.
D7. Consumers: nix-orca switches its deps fetch to this pnpm in its own
    PR once this flake is released; that PR re-measures both deps hashes.
    Not part of this repository's work.

# Out of scope

Packaging pnpm 11 or 10 (nixpkgs has them), corepack, and Windows.

# Decisions round 2, 2026-10-24 (spec run, measured)

Survey correction, measured 2026-10-24 on the pin (nixpkgs da6dc0e, the
rev nixpkgs-lock publishes), with `nix eval`, `nix build` and the
cache.nixos.org narinfo:

- The pin ships `pnpm_12` too: 12.9.0, built from Rust source through
  `pkgs/development/tools/pnpm/generic-rust.nix` on `rustPackages_1_97`,
  cached on cache.nixos.org for all four systems. `pnpm` is `pnpm_11`.
  "No pnpm 12" above is wrong; the gap stays, because 12.9.0 is older
  than the 12.14.0 Orca declares.
- `generic.nix` with 12.15.0 fails in postUnpack:
  `rm: cannot remove 'package/dist/vendor': No such file or directory`.
  The 12.x npm tarball is a shim: `install.js`, `@pnpm/exe.*`
  optionalDependencies, and a `bin/pnpm.mjs` that downloads the native
  binary on first use. It cannot run in the sandbox.
- `generic-rust.nix` with 12.15.0 fails after 252 s on aarch64-darwin:
  `couldn't read pnpm/crates/deps-restorer/src/cas-loader.mjs.inc`. The
  file is gitignored upstream and generated by esbuild from
  `pnpm/esm-loader`, which needs the `enhanced-resolve` npm dependency.
- The release asset `pnpm-darwin-arm64.tar.gz` holds one Mach-O `pnpm`
  (41 MB, system frameworks and libiconv only) plus a `dist/` payload;
  `pnpm --version` prints 12.15.0. `pnpm-linux-x64.tar.gz` holds a
  dynamically linked glibc ELF. Each asset's sha256 equals the `digest`
  GitHub reports for it.
- pnpm 12.15.0 writes `lockfileVersion: '9.0'` and keeps its store
  under `v11`, which the pin's `fetchPnpmDeps` fixup already handles.

D8. (owner, 2026-10-24; local) Amends D2: build from upstream's release
    binaries, `pnpm-{darwin-arm64,darwin-x64,linux-x64,linux-arm64}.tar.gz`,
    for the measured reason above. The owner's answer, verbatim:
    "1 into cachix only." Read as: the release binaries, delivered
    through cachix only, with no GitHub release assets.
D9. (agent under D8; local) Aligns goal 2: the overlay sets `pnpm_12`,
    which overrides the pin's 12.9.0, and it never touches `pnpm`.
D10. (agent under D8; local) Aligns D3: the bump reads upstream's
    release list filtered to `v12.*` tags that are not prereleases. It
    never uses `releases/latest`, because that flag can point at an 11.x
    and the list also carries `pnpr@*` tags. The one sources file holds
    the version and four hashes, each taken from the asset's GitHub
    `digest` and checked against a download.
