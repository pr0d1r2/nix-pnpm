# SPEC

## §G GOAL

`nix-pnpm` — pnpm 12 (newest stable 12.x, now 12.15.0) as nix flake on fleet nixpkgs pin (`nixpkgs-lock`), ∀ 4 fleet systems, from upstream's release binaries; works as `pnpm` arg of pin's `fetchPnpmDeps` & `pnpmConfigHook`; Linux cached on `pr0d1r2.cachix.org` from CI.

LINEAGE: `SPEC-PROMPT.md` (HISTORICAL after this run). where it & this spec differ, this spec wins. prompt decisions cited `D<n>`. paradigm `fda10ea` + its `docs/NIX.md` & `docs/SHELL.md`; fleet rules cited `paradigm/V<n>`. shaped like `github.com/pr0d1r2/nix-hk`.

## §D DESCRIPTION

nix flake + bash scripts. packaging only: fetch upstream's prebuilt `pnpm`, patch for nix on Linux, test, cache. ⊥ fork, ⊥ source build (D8). consumer surface: `packages.<system>.pnpm` & `default`, `overlays.default` (`pnpm_12` only). first consumer nix-orca, switches in own PR (D7). public, MIT (D6). fleet member, full paradigm conformance.

## §F FEDERATION

dir|owns|⊥owns|tokens

## §N NAV

rel|path|lens
up|-|-
self|.|-

## §C CONSTRAINTS

- lang = nix + bash. paradigm `docs/NIX.md`: nixfmt, statix, deadnix, `nix flake check` only when push touches what flake reads. `docs/SHELL.md`: one script one job, ⊥ shell functions except `info` `warn` `fatal`, extract ⊥ embed (⊥ inline shell in nix | workflow), mirrored bats both ways, TDD order on push, env-var seams named in script header.
- 1 root input `nixpkgs-lock`; `nixpkgs.follows = "nixpkgs-lock/nixpkgs"`; ⊥ 2nd nixpkgs, ⊥ flake-utils (D1). pin today `da6dc0e` (nixos-26.05). gate tools in dev shell, ⊥ extra root input.
- systems: `aarch64-darwin` `x86_64-darwin` `x86_64-linux` `aarch64-linux` (goal 1, `paradigm/V28`). actlith refuses `x86_64-darwin` today (paradigm T19) ∴ that one built locally until pipelith carries it, as nix-hk.
- src = upstream GitHub release assets `pnpm-darwin-arm64` `pnpm-darwin-x64` `pnpm-linux-x64` `pnpm-linux-arm64` `.tar.gz` (D8). ⊥ musl, ⊥ npm tarball (shim downloads binary on first use), ⊥ pin `generic.nix` | `generic-rust.nix` (both fail on 12.15.0, §R).
- asset = `pnpm` executable + `dist/` (bundled node-gyp & helpers) ∴ install both side by side: binary finds `dist/` next to itself.
- Linux asset = dynamically linked glibc ELF ∴ `autoPatchelfHook`; darwin asset links system frameworks + `/usr/lib/libiconv.2.dylib` only ∴ ⊥ patched.
- pin `fetchPnpmDeps` reads `pnpm.version` (lockfile major check) & `pnpm.nodejs-slim` (`pnpm-fixup-state-db` override) ∴ package ! carry `passthru.nodejs-slim` = pin's `nodejs-slim`. ⊥ `passthru.fetchDeps` | `configHook` (deprecated in pin).
- track stable 12.x only: bump picks newest non-prerelease `v12.*` tag from release list, ⊥ `releases/latest`, ⊥ `pnpr@*`, ⊥ 13.x w/o owner decision (D3, D10).
- one sources file: version + 4 hashes; ∀ hash = GitHub asset `digest` (sha256), cross-checked by download; source of each recorded (D10, prompt "verify the tarball").
- cache: Linux outputs pushed to cachix `pr0d1r2` from CI only, ⊥ developer machine (D5); cachix = only binary channel, ⊥ GitHub release assets (D8).
- public from start, MIT (D6). ⊥ private repo named in committed text (`paradigm/V37`).
- outward acts need explicit owner approval: create GitHub repo, first push, cachix token, upstream issues.
- out of scope: pnpm 11 | 10 (pin has them), corepack, Windows, musl. nix-orca switch = nix-orca's own PR (D7).

## §I INTERFACES

- flake: `packages.<system>.pnpm` & `default` ∀ 4 systems (goal 1). `bin/` = `pnpm`, `pnpx` (`pnpm dlx`), `pn`, `pnx`, as pin's `pnpm_12`; completions bash, fish, zsh. `meta.mainProgram = "pnpm"`, `meta.license = mit`, `meta.sourceProvenance = binaryNativeCode`.
- flake: `overlays.default` = `final: prev: { pnpm_12 = …; }`, exactly that attr; ⊥ `pnpm` (goal 2, D9).
- flake: `checks.<system>` — version, fetch-deps, lockfile (`checks` node, D4).
- flake: `devShells.<system>.default` — gate tools (`dev` node).
- flake: `nixConfig` substituter `https://pr0d1r2.cachix.org` + its public key, as nix-hk.
- consumer: `fetchPnpmDeps { pnpm = nix-pnpm.packages.<system>.pnpm; fetcherVersion = 4; … }` & `pnpmConfigHook` w/ same pnpm in `nativeBuildInputs` (goal 3).
- file: `pkgs/pnpm/sources.json` — version + per-system asset url & hash (`pkgs` node, D10).
- cmd: `scripts/bump-pnpm.sh [--force]` — move to newest stable 12.x, prints `NEW_VERSION=<v>` when changed (`scripts` node, goal 4).
- ci: GitHub Actions rendered by actlith from `.actlith` (`paradigm/V28`): build & `nix flake check` ∀ CI system; cachix push Linux on `main` only; `verify-cache` job after build; daily upstream detection, red on newer 12.x, ⊥ pushes branch, ⊥ opens PR (nix-hk B8, B9).
