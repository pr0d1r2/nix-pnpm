#!/usr/bin/env bash
# The newest stable pnpm 12.x upstream (scripts V1, root V4): every page of
# the release list, never releases/latest; tags `v12.x.y` only, no
# prerelease, no draft, so no 11.x, 13.x or pnpr@* (root R2). The max is
# by version order (`sort -V`), never by date or lexically. Prints `12.x.y`;
# none is exit 1.
# Seams: GH (default gh).
# Usage: latest-pnpm-12.sh
set -euo pipefail

GH=${GH:-gh}

if [ "$#" -ne 0 ]; then
  echo "usage: latest-pnpm-12.sh" >&2
  exit 2
fi

# `--paginate` prints one JSON array per page; jq reads each in turn.
releases=$("$GH" api --paginate repos/pnpm/pnpm/releases)
versions=$(jq -r '.[]
  | select(.prerelease == false and .draft == false)
  | .tag_name
  | select(test("^v12\\.[0-9]+\\.[0-9]+$"))
  | ltrimstr("v")' <<<"$releases")
newest=$(sort -V <<<"$versions" | tail -n 1)

if [ -z "$newest" ]; then
  echo "latest-pnpm-12: no stable v12.x.y release in repos/pnpm/pnpm/releases (scripts V1)" >&2
  exit 1
fi
echo "$newest"
