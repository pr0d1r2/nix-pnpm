#!/usr/bin/env bash
# The daily upstream detection (root §I.ci): compares the pin in
# sources.json with upstream's newest stable 12.x from latest-pnpm-12.sh
# beside this script. Equal is exit 0. Otherwise one `::error::` line
# naming both versions, then exit 1. It only reports: never bumps, never
# pushes a branch, never opens a PR (nix-hk B8, B9).
# Seams: GH (default gh), SOURCES (default pkgs/pnpm/sources.json under
# the repository root).
# Usage: check-upstream.sh
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
GH=${GH:-gh}
SOURCES=${SOURCES:-$here/../pkgs/pnpm/sources.json}
export GH

if [ "$#" -ne 0 ]; then
  echo "usage: check-upstream.sh" >&2
  exit 2
fi

pinned=$(jq -r '.version // empty' "$SOURCES" 2>/dev/null) || pinned=
if [ -z "$pinned" ]; then
  echo "::error::cannot read the pinned version from $SOURCES"
  exit 1
fi
newest=$("$here/latest-pnpm-12.sh")

if [ "$newest" = "$pinned" ]; then
  echo "check-upstream: pnpm $pinned is upstream's newest stable 12.x"
  exit 0
fi
if [ "$(printf '%s\n' "$newest" "$pinned" | sort -V | tail -n 1)" = "$newest" ]; then
  echo "::error::pnpm $newest is upstream's newest stable 12.x, the pin is $pinned; run scripts/bump-pnpm.sh"
else
  echo "::error::the pin $pinned is not upstream's newest stable 12.x $newest; check upstream's release list"
fi
exit 1
