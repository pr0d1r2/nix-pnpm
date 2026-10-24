#!/usr/bin/env bash
# Bump pkgs/pnpm/sources.json to the newest stable 12.x (scripts V2-V4,
# root V9). The newest comes from latest-pnpm-12.sh beside this script.
# A downgrade or a newest below 12.14.0 is refused. Each of the 4 assets'
# hash is the SRI of its GitHub `digest`, and each asset is downloaded and
# hashed to cross-check it; any refusal leaves the file byte-identical.
# `--force` re-resolves the current version. Prints NEW_VERSION=<v> on
# stdout only when the file changed. Never runs git, never pushes, never
# opens a PR (nix-hk B9).
# Seams: GH (default gh), CURL (default curl), NIX (default nix),
# SOURCES (default pkgs/pnpm/sources.json under the repository root).
# Usage: bump-pnpm.sh [--force]
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
GH=${GH:-gh}
CURL=${CURL:-curl}
NIX=${NIX:-nix}
SOURCES=${SOURCES:-$here/../pkgs/pnpm/sources.json}
export GH
floor=12.14.0

fatal() {
  echo "bump-pnpm: $*" >&2
  exit 1
}

force=false
case "$#:${1:-}" in
0:) ;;
1:--force) force=true ;;
*)
  echo "usage: bump-pnpm.sh [--force]" >&2
  exit 2
  ;;
esac

pinned=$(jq -r '.version // empty' "$SOURCES" 2>/dev/null) || pinned=
[ -n "$pinned" ] || fatal "cannot read the pinned version from $SOURCES"
newest=$("$here/latest-pnpm-12.sh")

# Version order, never lexical: the lower of two by `sort -V`.
if [ "$newest" != "$pinned" ] &&
  [ "$(printf '%s\n' "$newest" "$pinned" | sort -V | head -n 1)" = "$newest" ]; then
  fatal "upstream's newest stable 12.x is $newest, older than the pinned $pinned; refusing to downgrade (scripts V2)"
fi
if [ "$newest" != "$floor" ] &&
  [ "$(printf '%s\n' "$newest" "$floor" | sort -V | head -n 1)" = "$newest" ]; then
  fatal "upstream's newest stable 12.x is $newest, below the floor $floor; refusing (scripts V2, root V9)"
fi
if [ "$newest" = "$pinned" ] && [ "$force" = false ]; then
  exit 0
fi

release=$("$GH" api "repos/pnpm/pnpm/releases/tags/v$newest")
work=$(mktemp -d)
new=$(mktemp "$SOURCES.XXXXXX")
trap 'rm -rf "$work" "$new"' EXIT

assets='{}'
for pair in aarch64-darwin:darwin-arm64 x86_64-darwin:darwin-x64 \
  x86_64-linux:linux-x64 aarch64-linux:linux-arm64; do
  system=${pair%%:*}
  name=pnpm-${pair#*:}.tar.gz
  url=https://github.com/pnpm/pnpm/releases/download/v$newest/$name
  digest=$(jq -r --arg name "$name" \
    'first(.assets[] | select(.name == $name) | .digest) // empty' <<<"$release")
  [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] ||
    fatal "v$newest $name has no sha256 digest; sources untouched (scripts V3)"
  want=${digest#sha256:}
  "$CURL" -fsSL -o "$work/$name" "$url" ||
    fatal "download of $url failed; sources untouched (scripts V3)"
  got=$("$NIX" hash file --type sha256 --base16 "$work/$name")
  [ "$got" = "$want" ] ||
    fatal "$name hashes to $got, its digest says $want; sources untouched (scripts V3)"
  sri=$("$NIX" hash convert --hash-algo sha256 --to sri "$want")
  assets=$(jq --arg system "$system" --arg url "$url" --arg hash "$sri" \
    '.[$system] = {url: $url, hash: $hash, source: "github-digest"}' <<<"$assets")
done

jq -S -n --arg version "$newest" --argjson assets "$assets" \
  '{version: $version, assets: $assets}' >"$new"
if cmp -s "$new" "$SOURCES"; then
  exit 0
fi
chmod 644 "$new"
mv "$new" "$SOURCES"
echo "NEW_VERSION=$newest"
