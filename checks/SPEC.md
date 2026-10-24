# SPEC

## §G GOAL

`checks/`: flake `checks.<system>` proving pnpm works as `fetchPnpmDeps` & `pnpmConfigHook` arg on pin, on fixture project committed here (D4, goal 3).

## §N NAV

rel|path|lens
up|.|-
self|checks|flake checks & fixture: version, `fetchPnpmDeps`, `pnpmConfigHook`, overlay
sib|pkgs|pnpm derivation from release assets; `pkgs/pnpm/sources.json`
sib|scripts|bash: newest stable 12.x, bump of `sources.json`, upstream detection; mirrored bats
sib|dev|dev shell flake `dev/flake.nix`, `.envrc`, hook install on entry

## §C CONSTRAINTS

- `checks/default.nix` = `{ pkgs, pnpm }: { … }`, wired from root `flake.nix` ∀ 4 systems.
- fixture `checks/fixture/`: `package.json` (1 dep `is-number@7.0.0`, 0 transitive) + `pnpm-lock.yaml` written by pinned pnpm 12 (`lockfileVersion: '9.0'`, `.:R7`). `packageManager` = `pnpm@12.14.0` on purpose (≠ pinned) ∴ proves ⊥ self-switch inside fetcher (`.:R8` `pm_on_fail=ignore`).
- fixture lockfile regenerated only when pnpm 12 lockfile format changes; regen = own commit naming the pnpm version.
- deps hash fixed in `checks/default.nix`; mismatch → red, ⊥ auto-update.
- shell in checks via `builtins.readFile` of `checks/*.sh`, ⊥ inline (`docs/SHELL.md`); each mirrored by `tests/unit/checks/<name>.bats`.
- reproducibility (`--rebuild`) = CLI flag, ⊥ expressible as derivation ∴ CI step, ⊥ flake check.

## §I INTERFACES

- check: `version` — `pnpm --version` = `sources.json` version & ≥ `12.14.0` (`.:V9`).
- check: `fetch-deps` — `fetchPnpmDeps { pname = "nix-pnpm-fixture"; src = ./fixture; inherit pnpm; fetcherVersion = 4; hash = …; }`.
- check: `config-hook` — `stdenvNoCC` drv w/ `nativeBuildInputs = [ pnpm pnpmConfigHook nodejs-slim ]`, `pnpmDeps` = `fetch-deps`; installs offline, runs `node -e "require('is-number')"`; log ⊥ lockfile-version warning.
- check: `overlay` — pin + `overlays.default` attr diff = `[ "pnpm_12" ]` (`.:V2`).
- ci: `nix build --rebuild .#checks.<system>.fetch-deps` after first build.

## §V INVARIANTS

V1: `fetch-deps` builds w/ committed hash ∀ CI system & `nix build --rebuild` reproduces it (D4).
V2: `config-hook` install log ∌ `lockfile` + `version` warning (case-insensitive) & ∌ `ERR_PNPM_`; exit 0 (D4).
V3: inside `fetch-deps` & `config-hook`, `pnpm --version` = pinned version though fixture `packageManager` differs.
V4: ∀ check offline except `fetch-deps` (fixed-output) (`.:V7`).
V5: `overlay` check fails when overlay sets any attr ≠ `pnpm_12` (`.:V2`).

## §T TASKS

id|status|task|cites
T1|.|fixture `package.json` & `pnpm-lock.yaml` via pinned pnpm 12|V1,V3
T2|.|`fetch-deps` + hash; `--rebuild` CI step|V1,V4
T3|.|`config-hook` w/ log assert; planted lockfile `lockfileVersion: '10.0'` proves V2 check rejects|V2,V3
T4|.|`version` & `overlay` checks; planted extra overlay attr proves V5|V5

## §B BUGS

id|date|cause|fix
