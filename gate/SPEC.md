# SPEC

## §G GOAL

`gate/`: bash gate scripts hk steps run: lock-graph guard, root-inputs guard, name guard; mirrored bats under `tests/unit/gate/` (root T3).

## §N NAV

rel|path|lens
up|.|-
self|gate|gate scripts: lock-graph, root-inputs & name guards; their bats
sib|pkgs|pnpm derivation from release assets; `pkgs/pnpm/sources.json`
sib|checks|flake checks & fixture: version, `fetchPnpmDeps`, `pnpmConfigHook`, overlay
sib|scripts|bash: newest stable 12.x, bump of `sources.json`, upstream detection; mirrored bats
sib|dev|dev shell flake `dev/flake.nix`, `.envrc`, hook install on entry

## §C CONSTRAINTS

- hk steps from `.pklith` via pklith (`paradigm/V23`); 1 check per commit; planted violation in bats each (`paradigm/V21`).
- scripts follow `docs/SHELL.md`: one job each; jq rules in `.jq` file beside the script, ⊥ inline.
- lock-graph & root-inputs guards run on root `flake.lock` & `dev/flake.lock` (`.:V1`, `dev:V2`); offline. rev = `nixpkgs-lock`'s published rev needs network ∴ `gate/pin-rev.sh` runs in CI (`assert.yml`), ⊥ hk step.
- name guard: denylist local `.private/denylist`, ⊥ committed; hit prints file, line & entry number, ⊥ the name; ⊥ denylist → says so, passes (CI). allowlist half = CI (`paradigm/V37`).

## §I INTERFACES

- cmd: `gate/lock-graph.sh <flake.lock>` → exit 1 + 1 stderr line per problem: ≠ 1 nixpkgs node | input locking own nixpkgs; exit 2 usage.
- cmd: `gate/root-inputs.sh <flake.lock> <input>...` → exit 1 when root node's inputs ≠ exactly the names given; exit 2 usage.
- cmd: `gate/pin-rev.sh <flake.lock>` → exit 1 when lock's nixpkgs rev ≠ rev `nix flake metadata github:pr0d1r2/nixpkgs-lock` locks; seam `NIX`; network.
- cmd: `gate/name-guard.sh <file>...` → exit 1 on denylisted name; env `NAME_GUARD_DENYLIST` (default `.private/denylist`).

## §V INVARIANTS

V1: lock-graph guard fails on fixture w/ 2 nixpkgs nodes & on input w/ own nixpkgs; passes single-nixpkgs fixture (`.:V1`).
V2: root-inputs guard fails on fixture w/ extra root input; passes root lock w/ `nixpkgs`, `nixpkgs-lock` (`.:V1`).
V3: name guard fails on planted denylisted name, output ∌ the name (`.:V8`).
V4: pin-rev guard fails naming both revs when they differ; passes when equal (`.:V1`).

## §T TASKS

id|status|task|cites
T1|x|RED bats then `lock-graph.sh` + `lock-graph.jq`; hk check `lock-graph` on ∀ tracked `flake.lock`|V1
T2|x|RED bats then `root-inputs.sh`; hk check on root lock once root flake exists|V2
T3|x|RED bats then `name-guard.sh`; hk check `name-guard` on ∀ file|V3
T4|.|RED bats then `pin-rev.sh`; CI job `pins` in `assert.yml` (`.:T4`)|V4

## §B BUGS

id|date|cause|fix
