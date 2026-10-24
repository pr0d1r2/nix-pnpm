#!/usr/bin/env bash
# The pin-rev guard (gate V4, root V1): the flake lock's nixpkgs is
# exactly the rev nixpkgs-lock publishes, the fleet's one nixpkgs. Reads
# nixpkgs-lock over the network, so CI runs it (assert.yml), not hk.
# Seam: NIX (default nix).
# Usage: pin-rev.sh FLAKE-LOCK
set -euo pipefail

NIX=${NIX:-nix}

if [ "$#" -ne 1 ]; then
  echo "usage: pin-rev.sh FLAKE-LOCK" >&2
  exit 2
fi
lock=$1

ours=$(jq -r '.nodes.nixpkgs.locked.rev // empty' "$lock" 2>/dev/null || true)
if [ -z "$ours" ]; then
  echo "pin-rev: $lock: no nixpkgs rev in the lock (root V1)" >&2
  exit 1
fi
if ! meta=$("$NIX" flake metadata --json github:pr0d1r2/nixpkgs-lock 2>/dev/null) ||
  ! theirs=$(jq -er '.locks.nodes.nixpkgs.locked.rev' <<<"$meta" 2>/dev/null); then
  echo "pin-rev: cannot read the rev nixpkgs-lock publishes (root V1)" >&2
  exit 1
fi
if [ "$ours" != "$theirs" ]; then
  echo "pin-rev: $lock locks nixpkgs $ours, nixpkgs-lock publishes $theirs (root V1)" >&2
  exit 1
fi
