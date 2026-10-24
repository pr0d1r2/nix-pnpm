#!/usr/bin/env bash
# The `version` check (checks §I, root V9): `pnpm --version` is the version
# pkgs/pnpm/sources.json pins, and at or above the floor by version order
# (`sort -V`), never lexically. fetch-deps runs it too, inside the fetcher
# where the fixture's `packageManager` names another pnpm (checks V3).
# checks/default.nix loads it with builtins.readFile, so it takes no
# arguments and leaves $out to its caller.
# Seams: PNPM (default pnpm), EXPECTED_VERSION, FLOOR_VERSION (both required).
# Usage: EXPECTED_VERSION=12.15.0 FLOOR_VERSION=12.14.0 version.sh
set -euo pipefail

PNPM=${PNPM:-pnpm}

if [ -z "${EXPECTED_VERSION:-}" ] || [ -z "${FLOOR_VERSION:-}" ]; then
  echo "version.sh: EXPECTED_VERSION and FLOOR_VERSION must be set" >&2
  exit 2
fi

actual=$("$PNPM" --version)
if [ "$actual" != "$EXPECTED_VERSION" ]; then
  echo "version: pnpm --version is $actual, sources.json pins $EXPECTED_VERSION (checks V3)" >&2
  exit 1
fi
lowest=$(printf '%s\n%s\n' "$FLOOR_VERSION" "$actual" | sort -V | head -n 1)
if [ "$lowest" != "$FLOOR_VERSION" ]; then
  echo "version: pnpm $actual is below the floor $FLOOR_VERSION (root V9)" >&2
  exit 1
fi
echo "version: pnpm $actual is the pinned version, at or above $FLOOR_VERSION"
