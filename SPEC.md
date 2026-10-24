# SPEC

## §G GOAL

`nix-pnpm` — pnpm 12 (newest stable 12.x, now 12.15.0) as nix flake on fleet nixpkgs pin (`nixpkgs-lock`), ∀ 4 fleet systems, from upstream's release binaries; works as `pnpm` arg of pin's `fetchPnpmDeps` & `pnpmConfigHook`; Linux cached on `pr0d1r2.cachix.org` from CI.

LINEAGE: `SPEC-PROMPT.md` (HISTORICAL after this run). where it & this spec differ, this spec wins. prompt decisions cited `D<n>`. paradigm `fda10ea` + its `docs/NIX.md` & `docs/SHELL.md`; fleet rules cited `paradigm/V<n>`. shaped like `github.com/pr0d1r2/nix-hk`.
