# SPEC

## §G GOAL

`pkgs/pnpm/package.nix` + `pkgs/pnpm/sources.json`: pnpm derivation from upstream release asset per system, callable by flake `packages` & `overlays.default` alike.

## §N NAV

rel|path|lens
up|.|-
self|pkgs|pnpm derivation from release assets; `pkgs/pnpm/sources.json`
sib|checks|flake checks & fixture: version, `fetchPnpmDeps`, `pnpmConfigHook`, overlay
sib|scripts|bash: newest stable 12.x, bump of `sources.json`, upstream detection; mirrored bats
sib|dev|dev shell flake `dev/flake.nix`, `.envrc`, hook install on entry
sib|gate|gate scripts: lock-graph, root-inputs & name guards; their bats

## §C CONSTRAINTS

- `stdenvNoCC.mkDerivation`; `src = fetchurl { url; hash; }` from `sources.json` keyed by `stdenvNoCC.hostPlatform.system`; unknown system → `throw` naming the 4 supported.
- install: `pnpm` → `$out/libexec/pnpm/pnpm`, `dist/` → `$out/libexec/pnpm/dist`, symlink `$out/bin/pnpm`; `pn` → `pnpm`; `pnpx` & `pnx` = `makeWrapper … --add-flag dlx`, as pin's `generic-rust.nix`.
- Linux: `autoPatchelfHook` + `stdenv.cc.cc.lib` (measured: binary needs `libgcc_s.so.1`, only gcc lib output has it; glibc via hook bintools). `dontAutoPatchelf = true` & `autoPatchelf "$out"` in `postInstall` ∵ completions run binary before fixup. darwin: binary ⊥ modified (signature intact). `patchShebangs` rewrites `dist/` sh scripts → bash ∈ closure; binary untouched.
- `dontStrip = true`: upstream binary already stripped; ⊥ touch it beyond patchelf.
- completions via `installShellCompletion` from `$out/bin/pnpm completion <shell>`, only when `buildPlatform.canExecute hostPlatform`.
- passthru `nodejs-slim` = pin's `nodejs-slim`, `majorVersion` (`.:R8`).
- `meta.platforms` = the 4 systems; `meta.sourceProvenance = [ lib.sourceTypes.binaryNativeCode ]`.
- `sources.json` written only by `scripts/bump-pnpm.sh`; ⊥ hand edit except reviewed fix.

## §I INTERFACES

- file: `pkgs/pnpm/package.nix` — `{ lib, stdenv, stdenvNoCC, fetchurl, autoPatchelfHook, makeWrapper, installShellFiles, versionCheckHook, nodejs-slim }: …`; `stdenv` only names `stdenv.cc.cc.lib`.
- file: `pkgs/pnpm/sources.json` — `{ "version": "12.15.0", "assets": { "<system>": { "url": "https://github.com/pnpm/pnpm/releases/download/v<version>/pnpm-<os>-<arch>.tar.gz", "hash": "sha256-…", "source": "github-digest" } } }`; `<system>` ∈ 4 systems.

## §V INVARIANTS

V1: `$out/bin/pnpm --version` = `sources.json` `.version`, via `versionCheckHook` @ install check ∀ system (D4).
V2: ∀ `sources.json` asset: `hash` = SRI of GitHub asset `digest` for that tag & name (D10).
V3: Linux output: `ldd $out/libexec/pnpm/pnpm` ⊥ `not found`; interpreter ∈ `/nix/store`.
V4: darwin output: `libexec/pnpm/pnpm` bytes = asset's `pnpm` bytes.
V5: `$out/libexec/pnpm/dist/node-gyp-bin/node-gyp` ∃ beside binary (path pnpm probes).
V6: `passthru.nodejs-slim` ∃ & = pin's `nodejs-slim` (`.:R8`).

## §T TASKS

id|status|task|cites
T1|x|`sources.json` for 12.15.0 from GitHub digests, cross-checked by download|V2
T2|x|`package.nix` darwin path; build aarch64-darwin|V1,V4,V5,V6
T3|.|Linux path w/ `autoPatchelfHook`; measure runtime deps; build x86_64-linux & aarch64-linux (remote builder \| CI)|V1,V3,V5
T4|.|build x86_64-darwin: ⊥ Rosetta on owner aarch64 Mac (`arch -x86_64` → "Bad CPU type", `extra-platforms` empty) ∴ Intel host \| CI (`.:T9`)|V1,V4

## §B BUGS

id|date|cause|fix
