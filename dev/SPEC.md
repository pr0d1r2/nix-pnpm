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

## §C CONSTRAINTS

- own `dev/flake.lock`; inputs `nixpkgs-lock` (nixpkgs follows it) + pklith (catalog: hk, mth, sherd, itok); pklith's nixpkgs follows ours ∴ 1 nixpkgs in dev lock graph too.
- tools: hk, pkl, mth, sherd, itok, nixfmt, statix, deadnix, shellcheck, shfmt, bats, actionlint, jq, gh. ⊥ lefthook (`paradigm/V26`).
- root `.envrc` = `use flake ./dev`; hooks installed on shell entry (`hk install`).
- shell on ∀ 4 systems (`paradigm/V20`).

## §I INTERFACES

- file: `dev/flake.nix` & `dev/flake.lock`.
- file: `.envrc` — `use flake ./dev`.
- cmd: `nix develop ./dev -c hk check --all` — same gate CI runs.

## §V INVARIANTS

V1: ∀ tool gate step calls resolves inside dev shell (`command -v`) ∀ 4 systems.
V2: dev lock graph: exactly 1 nixpkgs node, = `nixpkgs-lock`'s rev.
V3: root `flake.lock` ⊥ gains input from dev tooling (`.:V1`).

## §T TASKS

id|status|task|cites
T1|.|`dev/flake.nix` + lock, `.envrc`; tool presence check; human shell reload|V1,V2,V3

## §B BUGS

id|date|cause|fix
