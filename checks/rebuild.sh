#!/usr/bin/env bash
# The reproducibility check (checks V1, checks T2): build the current
# system's fixture deps fetch, then build it again with --rebuild, which
# fails when the second output differs. A CLI flag, not a derivation, so
# CI runs it (assert.yml) rather than `nix flake check`.
# Seam: NIX (default nix).
# Usage: rebuild.sh
set -euo pipefail

NIX=${NIX:-nix}

if [ "$#" -ne 0 ]; then
  echo "usage: rebuild.sh" >&2
  exit 2
fi

system=$("$NIX" eval --raw --impure --expr builtins.currentSystem)
attr=".#checks.$system.fetch-deps"

if ! "$NIX" build --print-build-logs --no-link "$attr"; then
  echo "rebuild: $attr does not build (checks V1)" >&2
  exit 1
fi
if ! "$NIX" build --rebuild --print-build-logs --no-link "$attr"; then
  echo "rebuild: $attr is not reproducible (checks V1)" >&2
  exit 1
fi
