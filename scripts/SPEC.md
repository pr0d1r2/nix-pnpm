# SPEC

## §G GOAL

`scripts/`: bash for finding newest stable pnpm 12.x & bumping `pkgs/pnpm/sources.json` to it; mirrored bats under `tests/unit/scripts/` (goal 4, D3, D10).

## §N NAV

rel|path|lens
up|.|-
self|scripts|bash: newest stable 12.x, bump of `sources.json`, upstream detection; mirrored bats
sib|pkgs|pnpm derivation from release assets; `pkgs/pnpm/sources.json`
sib|checks|flake checks & fixture: version, `fetchPnpmDeps`, `pnpmConfigHook`, overlay
sib|dev|dev shell flake `dev/flake.nix`, `.envrc`, hook install on entry
sib|gate|gate scripts: lock-graph, root-inputs & name guards; their bats

## §C CONSTRAINTS

- `set -euo pipefail` ∀ script; CI steps run them under `shell: bash` ∴ pipefail holds (nix-hk B8).
- seams in header: `GH` (default `gh`), `CURL` (default `curl`), `NIX` (default `nix`); bats stub them, ⊥ network in tests.
- one script one job: `latest-pnpm-12.sh` finds; `bump-pnpm.sh` writes; `check-upstream.sh` compares for CI.
- release list via `$GH api --paginate repos/pnpm/pnpm/releases`; keep tag ~ `^v12\.[0-9]+\.[0-9]+$`, `prerelease == false`, `draft == false`; max by `sort -V`, ⊥ by date (11.x & `pnpr@*` interleave, `.:R2`).
- bump writes `pkgs/pnpm/sources.json` only (D3): version + 4 asset url/hash. ⊥ edits fixture deps hash; a pnpm whose fetch changes it → `fetch-deps` red → fix in own commit, naming that deps hashes depend on fetching pnpm (prompt; nix-orca D7 re-measures its own).
- hash = asset `digest` (`sha256:<hex>`) → SRI; download each asset & compare `sha256`; mismatch | missing digest → exit 1, sources untouched.
- write via temp file + `mv`; `jq` formats JSON stable (sorted keys).
- ⊥ git, ⊥ branch push, ⊥ PR from scripts (nix-hk B9).

## §I INTERFACES

- cmd: `scripts/latest-pnpm-12.sh` → stdout `12.x.y`; none → exit 1.
- cmd: `scripts/bump-pnpm.sh [--force]` → writes `sources.json` when newer (| `--force`: re-resolve current); stdout `NEW_VERSION=<v>` only when file changed; already current → exit 0, ⊥ stdout.
- cmd: `scripts/check-upstream.sh` → exit 0 when pinned = newest stable 12.x; exit 1 + `::error::` line naming both versions when newer exists.
- file: `tests/unit/scripts/<name>.bats` ∀ script (`docs/SHELL.md` mirror).

## §V INVARIANTS

V1: `latest-pnpm-12.sh` ⊥ prints prerelease, 11.x, 13.x, `pnpr@*`; picks `12.10.0` over `12.9.1` (version order, ⊥ lexical | date).
V2: `bump-pnpm.sh` ⊥ downgrades: newest < pinned | newest < `12.14.0` → exit 1, file untouched (`.:V9`).
V3: digest mismatch | missing digest | failed download → exit 1, `sources.json` byte-identical to before.
V4: after bump, `sources.json` passes `pkgs:V2` (hash = GitHub digest) ∀ 4 systems.
V5: ∀ script has mirrored bats & ∀ bats has script (`docs/SHELL.md`).

## §T TASKS

id|status|task|cites
T1|x|RED bats then `latest-pnpm-12.sh`, fixture release JSON incl. `v11.28.8`, `pnpr@0.1.0-alpha.16`, `v12.9.1`, `v12.10.0`, a prerelease|V1,V5
T2|x|RED bats then `bump-pnpm.sh`: newer, current, `--force`, downgrade, bad digest|V2,V3,V4,V5
T3|.|RED bats then `check-upstream.sh`|V5

## §B BUGS

id|date|cause|fix
