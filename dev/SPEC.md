# SPEC

## §G GOAL

`dev/flake.nix`: dev shell pinning ∀ tool gate, hooks & CI run (`paradigm/V20`), kept out of root flake ∴ consumers lock only `nixpkgs-lock` (`.:V1`).

## §N NAV

rel|path|lens
up|.|-
self|dev|dev shell flake `dev/flake.nix`, `.envrc`, hook install on entry
sib|pkgs|pnpm derivation from release assets; `pkgs/pnpm/sources.json`
sib|checks|flake checks & fixture: version, `fetchPnpmDeps`, `pnpmConfigHook`, overlay
sib|scripts|bash: newest stable 12.x, bump of `sources.json`, upstream detection; mirrored bats
sib|gate|gate scripts: lock-graph, root-inputs & name guards; their bats

## §C CONSTRAINTS

- own `dev/flake.lock`, ⊥ in consumers' locks. inputs `nixpkgs-lock` (nixpkgs follows it), `nix-hk`, & fleet tools pinned to tags, each following `nixpkgs-lock` & `nix-hk`: microlith `v0.7.4`, sherd `v0.5.4`, characterminator `v0.1.1`, pklith `v0.1.0`, actlith `v0.1.0`, xenolith `v0.1.0` (as nix-orca, 2026-10-24). tag bump = own commit.
- tools: hk, pkl, git, bats, shellcheck, shfmt, nixfmt, statix, deadnix, gitleaks, jq, cachix, gh + the 6 fleet tools + whatever `pklith gen` names in `nix/pklith.nix`. ⊥ lefthook (`paradigm/V26`).
- `.envrc` = `use flake ./dev` + `source_env_if_exists .envrc.local`.
- hooks: shell hook points `core.hooksPath` at pklith-seeded tracked `.githooks/` on every entry once `hk.pkl` exists, idempotent; ⊥ `hk install`; ⊥ hk → says so, ⊥ fallback runner (`paradigm/V23`).
- shell hook = `dev/shell-hook.sh` (bats `tests/unit/dev/shell-hook.bats`), ⊥ inline in nix; ⊥ fails shell entry.
- shell on ∀ 4 systems (`paradigm/V20`); fleet tool w/o build on a system (x86_64-darwin today: microlith, characterminator, pklith, actlith, xenolith) → shell still evaluates & names them on entry; gate needing one fails, ⊥ skips.

## §I INTERFACES

- file: `dev/flake.nix` & `dev/flake.lock`.
- file: `.envrc` — `use flake ./dev`.
- cmd: `nix develop ./dev -c hk check --all` — same gate CI runs.
- cmd: `dev/shell-hook.sh SYSTEM [ABSENT-TOOL...]` — exit 0 always; stderr names missing hk | absent tools.

## §V INVARIANTS

V1: ∀ tool gate step calls resolves inside dev shell (`command -v`) ∀ 4 systems.
V2: dev lock graph: exactly 1 nixpkgs node, = `nixpkgs-lock`'s rev.
V3: root `flake.lock` ⊥ gains input from dev tooling (`.:V1`).

## §T TASKS

id|status|task|cites
T1|x|`dev/flake.nix` + lock, `.envrc`; tool presence check; human shell reload|V1,V2,V3

## §B BUGS

id|date|cause|fix
