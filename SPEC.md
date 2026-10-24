# SPEC

## §G GOAL

`nix-pnpm` — pnpm 12 (newest stable 12.x, now 12.15.0) as nix flake on fleet nixpkgs pin (`nixpkgs-lock`), ∀ 4 fleet systems, from upstream's release binaries; works as `pnpm` arg of pin's `fetchPnpmDeps` & `pnpmConfigHook`; ∀ CI system cached on `pr0d1r2.cachix.org` from CI (V10).

LINEAGE: `SPEC-PROMPT.md` (HISTORICAL after this run). where it & this spec differ, this spec wins. prompt decisions cited `D<n>`. paradigm `fda10ea` + its `docs/NIX.md` & `docs/SHELL.md`; fleet rules cited `paradigm/V<n>`. shaped like `github.com/pr0d1r2/nix-hk`.

## §D DESCRIPTION

nix flake + bash scripts. packaging only: fetch upstream's prebuilt `pnpm`, patch for nix on Linux, test, cache. ⊥ fork, ⊥ source build (D8). consumer surface: `packages.<system>.pnpm` & `default`, `overlays.default` (`pnpm_12` only). first consumer nix-orca, switches in own PR (D7). public, MIT (D6). fleet member, full paradigm conformance.

## §F FEDERATION

dir|owns|⊥owns|tokens
pkgs|pnpm derivation from release assets; `pkgs/pnpm/sources.json`|flake wiring (root `flake.nix`), checks (`checks`), bump (`scripts`)|-
checks|flake checks & fixture: version, `fetchPnpmDeps`, `pnpmConfigHook`, overlay|derivation (`pkgs`), CI steps (`.actlith`)|-
scripts|bash: newest stable 12.x, bump of `sources.json`, upstream detection; mirrored bats|derivation (`pkgs`), workflows (`.actlith`)|-
dev|dev shell flake `dev/flake.nix`, `.envrc`, hook install on entry|hk steps (`.pklith`, `hk.pkl`), package (`pkgs`)|-
gate|gate scripts: lock-graph, root-inputs & name guards; their bats|hk steps (`.pklith`, `hk.pkl`), dev shell (`dev`)|-

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
- track stable 12.x only: bump picks newest non-prerelease `v12.*` tag from release list, ⊥ `releases/latest`, ⊥ `pnpr@*`, ⊥ 13.x w/o owner decision (D3, D10). floor 12.14.0 (owner 2026-10-24, Orca `packageManager`, `.:R9`).
- one sources file: version + 4 hashes; ∀ hash = GitHub asset `digest` (sha256), cross-checked by download; source of each recorded (D10, prompt "verify the tarball").
- cache: ∀ CI-built output pushed to cachix `pr0d1r2` from CI only, ⊥ developer machine (D5 amended by owner 2026-10-24: all CI systems, ⊥ Linux only); cachix = only binary channel, ⊥ GitHub release assets (D8).
- public from start, MIT (D6). ⊥ private repo named in committed text (`paradigm/V37`).
- outward acts need explicit owner approval: create GitHub repo, first push, cachix token, upstream issues.
- out of scope: pnpm 11 | 10 (pin has them), corepack, Windows, musl. nix-orca switch = nix-orca's own PR (D7).

## §I INTERFACES

- flake: `packages.<system>.pnpm` & `default` ∀ 4 systems (goal 1). `bin/` = `pnpm`, `pnpx` (`pnpm dlx`), `pn`, `pnx`, as pin's `pnpm_12`; completions bash, fish, zsh. `meta.mainProgram = "pnpm"`, `meta.license = mit`, `meta.sourceProvenance = binaryNativeCode`.
- flake: `overlays.default` = `final: prev: { pnpm_12 = …; }`, exactly that attr; ⊥ `pnpm` (goal 2, D9).
- flake: `checks.<system>` — `version`, `fetch-deps`, `config-hook`, `overlay` (`checks` node, D4).
- flake: ⊥ `devShells` in root flake; dev shell = `dev/flake.nix` (`dev` node, `dev:V3`).
- flake: `nixConfig` substituter `https://pr0d1r2.cachix.org` + its public key, as nix-hk.
- consumer: `fetchPnpmDeps { pnpm = nix-pnpm.packages.<system>.pnpm; fetcherVersion = 4; … }` & `pnpmConfigHook` w/ same pnpm in `nativeBuildInputs` (goal 3).
- file: `pkgs/pnpm/sources.json` — version + per-system asset url & hash (`pkgs` node, D10).
- cmd: `scripts/bump-pnpm.sh [--force]` — move to newest stable 12.x, prints `NEW_VERSION=<v>` when changed (`scripts` node, goal 4).
- ci: GitHub Actions rendered by actlith from `.actlith` (`paradigm/V28`): build & `nix flake check` ∀ CI system; cachix push ∀ CI system on `main` only; `verify-cache` job after build; daily upstream detection, red on newer 12.x, ⊥ pushes branch, ⊥ opens PR (nix-hk B8, B9).

## §R RESEARCH

id|topic|finding|src
R1|pin pnpm 2026-10-24|pin `da6dc0e`: `pnpm` = `pnpm_11` 11.27.0, `pnpm_10` 10.34.0, `pnpm_12` 12.9.0 (Rust, `generic-rust.nix`, `rustPackages_1_97`), cache.nixos.org 200 ∀ 4 systems. prompt's "no pnpm 12" wrong; gap = 12.9.0 < Orca's 12.14.0|`nix eval` `.pnpm_12.version` & outPath, narinfo `curl`
R2|upstream releases 2026-10-24|stable 12.x newest `v12.15.0` (2026-10-21); 11.x (`v11.28.8`, 2026-10-22) & 10.x ship in parallel; list also carries `pnpr@0.1.0-alpha.*` prereleases. `releases/latest` = `v12.15.0` today, ⊥ guaranteed|`gh api repos/pnpm/pnpm/releases`
R3|npm tarball 12.15.0|shim: `install.js` pre/postinstall, 14 `@pnpm/exe.*` optionalDependencies, `bin/pnpm.mjs` downloads native binary on first use (corepack path). `dist.integrity` sha512 = local `openssl dgst -sha512` of tarball; nix sha256 `sha256-9Rc/YSfMUFzbNuwXcZ/lSoURxv2FYMfOtL98c+O0RYs=`|`registry.npmjs.org/pnpm/12.15.0`, tarball listing
R4|pin `generic.nix` @ 12.15.0|fails postUnpack: `rm: cannot remove 'package/dist/vendor': No such file or directory`. would install shim anyway|`nix build` of `callPackage generic.nix { version = "12.15.0"; … }`, aarch64-darwin
R5|pin `generic-rust.nix` @ 12.15.0|`srcHash` `sha256-G2WL5n96GUWcST9qNZH4pnceAUugUAUuwmYGmqgGYDs=`, `cargoHash` `sha256-tvxkHVpr364Tst6mIOlBpOMZSuH+E4wqYv27p6OShGI=`; 899 crates; `12-bump-webpki.patch` already upstream. fails @ 252 s: `couldn't read pnpm/crates/deps-restorer/src/cas-loader.mjs.inc` — gitignored, esbuild output of `pnpm/esm-loader` (needs `enhanced-resolve`). toolchain `1.97.0`|`nix build`, aarch64-darwin, `rust-toolchain.toml`
R6|release assets 12.15.0|14 assets; ours: `darwin-arm64` sha256 `6a41a287…6ef27`, `darwin-x64` `2d7b3368…b47f`, `linux-x64` `55b5ed00…0598`, `linux-arm64` `d7ce93a2…6117`. each = GitHub `digest`; darwin-arm64 & linux-x64 downloads match. tarball = `pnpm` (41 MB Mach-O: Security, CoreFoundation, libiconv, libSystem) + `dist/` (4.5 MB: node-gyp, `node_modules`). linux-x64 = glibc PIE, interp `/lib64/ld-linux-x86-64.so.2`. `pnpm --version` → 12.15.0; `completion bash\|fish\|zsh` work|`gh api …/releases/tags/v12.15.0`, `shasum`, `otool -L`, `file`
R7|pnpm 12 lockfile & store|12.15.0 `install --lockfile-only` writes `lockfileVersion: '9.0'` ∴ pin fetcher's major check (9 ≤ 12) passes. store dir `STORE_VERSION = "v11"` ∴ fetcher's `v11` fixup (`index.db` → SQL dump @ `fetcherVersion = 4`) applies|fixture run; `pnpm/crates/store-dir/src/store_dir.rs`
R8|pin `fetchPnpmDeps`|args `pnpm`, `fetcherVersion` ∈ 1–4 (required); reads `pnpm.version` & `pnpm.nodejs-slim`; pnpm ≥ 11 → env `pnpm_config_pm_on_fail=ignore`, `side_effects_cache=false`, `force_ignores_platform=true`; `install --force --ignore-scripts --frozen-lockfile`|`pkgs/build-support/node/fetch-pnpm-deps/default.nix` @ pin
R9|consumer nix-orca 2026-10-24|`nix/linux/sources.nix`: 2 `fetchPnpmDeps` (`fetcherVersion = 4`) on pin pnpm 11.27.0 over Orca `pnpm-lock.yaml` v9.0; `package.nix` uses `pnpmConfigHook`. Orca v1.4.237 `packageManager` `pnpm@12.14.0`|nix-orca `nix/linux/SPEC.md` R2, R3; `packageManager` from prompt (v1.4.237)
R10|package build wave 1 2026-10-24|aarch64-darwin `/nix/store/zn2f3grvfifg9rmpmz3prxm7hm66gvi3-pnpm-12.15.0` (`codesign -v` ok); x86_64-linux `/nix/store/4lzab59p6r19zk9gypgvmhqvlsrh029x-pnpm-12.15.0`, closure 96.7 MiB (glibc, gcc libgcc, bash); linux-x64 needs `libgcc_s.so.1` `librt` `libpthread` `libm` `libdl` `libc`. x86_64-darwin ⊥ buildable on owner Mac (⊥ Rosetta). aarch64-linux evaluates, ⊥ builder here|wave-1 `pkgs` worker, `nix build`, remote builder `ssh-ng`
R11|checks wave 2 2026-10-24|fixture deps hash per OS: aarch64-darwin `sha256-hieVZKtXaEJNz2y7Yn1eh85k0tfg1zEd1xJnsna0OqQ=`, x86_64-linux `sha256-duv8c+5cLVlcEAYwNA06NOROBMNHkzHlW/MDMG7yRcE=`; only diff = empty `v11/links/` on darwin; `--rebuild` reproduces both. pin fetcher's lockfile check `${lockfileVersion:0:1} -gt 12` compares 1 char ∴ `'10.0'` passes it; pnpm refuses instead: `ERR_PNPM_BROKEN_LOCKFILE … lockfileVersion of 10.0 is incompatible`. outside fetcher pnpm 12.15.0 obeys `packageManager` (downloads it) unless `pnpm_config_pm_on_fail=ignore`|wave-2 `checks` worker, `nix build`, tarball diff

## §V INVARIANTS

V1: lock graph: root inputs = exactly `nixpkgs-lock`; exactly 1 nixpkgs node; its rev = rev `nixpkgs-lock` publishes; gate fails else (D1).
V2: `overlays.default` applied to pin → attr names it sets = exactly `[ "pnpm_12" ]`; `pnpm` stays pin's (D9).
V3: `packages.<system>.pnpm` & `checks.<system>` evaluate ∀ 4 systems; CI builds ∀ system actlith carries (`paradigm/V28`).
V4: pinned version ∈ stable 12.x: matches `^12\.[0-9]+\.[0-9]+$`; ⊥ prerelease suffix; 13.x only after owner decision (D3, D10).
V5: ∀ cachix push from CI on `main`, Linux outputs only; ⊥ push from developer machine; `verify-cache` job after build → narinfo 200 ∀ Linux `pnpm` path, else red (D5; nix-hk B3–B5: `cachix-action` exits 0 on empty | 403 token). [superseded by V10]
V6: ⊥ GitHub release asset in this repo; cachix = only binary channel (D8).
V7: build & checks ⊥ network except fixed-output fetches (`fetchurl` asset, `fetchPnpmDeps`).
V8: ⊥ private repo named in committed text (`paradigm/V37`, D6).
V9: pinned version ≥ `12.14.0` (owner 2026-10-24); `checks` `version` & `scripts/bump-pnpm.sh` refuse below (version order, `sort -V`).
V10: ∀ cachix push from CI on `main`, ∀ system CI builds (x86_64-linux, aarch64-linux, aarch64-darwin; owner 2026-10-24, amends D5); ⊥ push from developer machine; `verify-cache` job after build → narinfo 200 ∀ built `pnpm` path, else red (nix-hk B3–B5).

## §T TASKS

id|status|task|cites
T1|x|`.context-limits`: ∀ node measured by `sherd budget` + 12–20% slack (`paradigm/V12`)|-
T2|x|dev shell per `dev` node; human reloads shell after it lands (`paradigm/V20`)|V1
T3|~|guardrails via pklith `.pklith` → `hk.pkl`, one check per commit, planted violation each (`paradigm/V21`): nixfmt, statix, deadnix, shellcheck, shfmt, bats mirror both ways, TDD order, actionlint, spec checks, lock-graph guard, name guard|V1,V8
T4|~|CI via actlith `.actlith`: build & `nix flake check`, cachix push ∀ CI system on `main`, `verify-cache`, daily upstream detection (§I.ci)|V3,V6,V10
T5|~|waves, hand-planned (`sherd wave` reads Rust edges only, sherd#132): wave 1 = `pkgs` (+ root `flake.nix` wiring) ∥ `scripts`; wave 2 = `checks` (needs `pkgs`). one node per worker, own worktree, TDD (`paradigm/V14`); wave ends w/ reconciliation commit (`paradigm/V18`)|V2,V4,V7
T6|.|docs: `README.md` (consumer snippet for `fetchPnpmDeps`), `LICENSE` MIT, `docs/LLM-DISCLAIMER.md` (`paradigm/V33`)|V8
T7|.|GitHub repo `pr0d1r2/nix-pnpm` PUBLIC, first push, `CACHIX_AUTH_TOKEN` secret (per-cache write token): ∀ w/ owner approval|V5,V8
T8|.|after first green `main` w/ cache: issue in nix-orca to switch its deps fetch to this pnpm & re-measure both deps hashes, w/ owner approval (D7)|V5
T9|.|`x86_64-darwin` in CI once pipelith carries it (paradigm T19); until then built locally before each bump lands|V3
T10|.|RISK 2026-10-21: nixpkgs 26.05 last w/ `x86_64-darwin` (paradigm T21); revisit system list before `nixpkgs-lock` moves past 26.05|V3
T11|.|nixpkgs `fetchPnpmDeps` lockfile-major check compares 1 char (`.:R11`): issue upstream w/ owner approval; note per-OS deps hash for consumers in README (`.:T6`)|V7

## §B BUGS

id|date|cause|fix
