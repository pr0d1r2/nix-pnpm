#!/usr/bin/env bats
# scripts/bump-pnpm.sh (scripts V2-V4, root V9): moves sources.json to the
# newest stable 12.x, every hash the GitHub digest, cross-checked by
# download. gh, curl and nix are stubs behind the GH, CURL and NIX seams;
# the sources file is a fixture behind the SOURCES seam; no network. The
# stub nix "hashes" an asset by printing its bytes, so an asset's fixture
# content is the sha256 hex it hashes to.

bats_require_minimum_version 1.5.0

setup() {
  bump="$BATS_TEST_DIRNAME/../../../scripts/bump-pnpm.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  mkdir -p stubs assets pkgs/pnpm
  hex_darwin_arm64=$(printf 'a%.0s' {1..64})
  hex_darwin_x64=$(printf 'b%.0s' {1..64})
  hex_linux_x64=$(printf 'c%.0s' {1..64})
  hex_linux_arm64=$(printf 'd%.0s' {1..64})
  for pair in darwin-arm64:"$hex_darwin_arm64" darwin-x64:"$hex_darwin_x64" \
    linux-x64:"$hex_linux_x64" linux-arm64:"$hex_linux_arm64"; do
    printf '%s' "${pair#*:}" >"assets/pnpm-${pair%%:*}.tar.gz"
  done

  # Upstream's list: 12.15.0 is the newest stable 12.x.
  cat >releases.json <<'JSON'
[
  { "tag_name": "v11.28.8", "prerelease": false, "draft": false },
  { "tag_name": "pnpr@0.1.0-alpha.16", "prerelease": true, "draft": false },
  { "tag_name": "v12.15.0", "prerelease": false, "draft": false },
  { "tag_name": "v12.14.0", "prerelease": false, "draft": false }
]
JSON
  cat >release-v12.15.0.json <<JSON
{
  "tag_name": "v12.15.0",
  "assets": [
    { "name": "pnpm-darwin-arm64.tar.gz", "digest": "sha256:$hex_darwin_arm64" },
    { "name": "pnpm-darwin-x64.tar.gz", "digest": "sha256:$hex_darwin_x64" },
    { "name": "pnpm-linux-x64.tar.gz", "digest": "sha256:$hex_linux_x64" },
    { "name": "pnpm-linux-arm64.tar.gz", "digest": "sha256:$hex_linux_arm64" },
    { "name": "pnpm-linux-x64-musl.tar.gz", "digest": "sha256:$(printf 'e%.0s' {1..64})" }
  ]
}
JSON

  # Pinned: 12.14.0, written as the script writes it (jq -S).
  jq -S . >pkgs/pnpm/sources.json <<'JSON'
{
  "version": "12.14.0",
  "assets": {
    "aarch64-darwin": { "url": "https://github.com/pnpm/pnpm/releases/download/v12.14.0/pnpm-darwin-arm64.tar.gz", "hash": "sha256-old1", "source": "github-digest" },
    "x86_64-darwin": { "url": "https://github.com/pnpm/pnpm/releases/download/v12.14.0/pnpm-darwin-x64.tar.gz", "hash": "sha256-old2", "source": "github-digest" },
    "x86_64-linux": { "url": "https://github.com/pnpm/pnpm/releases/download/v12.14.0/pnpm-linux-x64.tar.gz", "hash": "sha256-old3", "source": "github-digest" },
    "aarch64-linux": { "url": "https://github.com/pnpm/pnpm/releases/download/v12.14.0/pnpm-linux-arm64.tar.gz", "hash": "sha256-old4", "source": "github-digest" }
  }
}
JSON
  cp pkgs/pnpm/sources.json before.json

  cat >stubs/gh <<'STUB'
#!/usr/bin/env bash
echo "$*" >>"$BATS_TEST_TMPDIR/gh.calls"
case "$*" in
"api --paginate repos/pnpm/pnpm/releases") cat "$BATS_TEST_TMPDIR/releases.json" ;;
"api repos/pnpm/pnpm/releases/tags/"*) cat "$BATS_TEST_TMPDIR/release-${2##*/}.json" ;;
*) exit 9 ;;
esac
STUB
  cat >stubs/curl <<'STUB'
#!/usr/bin/env bash
[ "$1 $2" = "-fsSL -o" ] || exit 9
echo "$4" >>"$BATS_TEST_TMPDIR/curl.calls"
name=${4##*/}
[ ! -e "$BATS_TEST_TMPDIR/fail-$name" ] || exit 22
cp "$BATS_TEST_TMPDIR/assets/$name" "$3"
STUB
  cat >stubs/nix <<'STUB'
#!/usr/bin/env bash
case "$*" in
"hash file --type sha256 --base16 "*) cat "$6" ;;
"hash convert --hash-algo sha256 --to sri "*) echo "sha256-sri-of-$7" ;;
*) exit 9 ;;
esac
STUB
  # The bump never touches git (scripts C, nix-hk B9).
  cat >stubs/git <<'STUB'
#!/usr/bin/env bash
echo "$*" >>"$BATS_TEST_TMPDIR/git.calls"
STUB
  chmod +x stubs/*
  export PATH="$BATS_TEST_TMPDIR/stubs:$PATH"
  export GH="$BATS_TEST_TMPDIR/stubs/gh"
  export CURL="$BATS_TEST_TMPDIR/stubs/curl"
  export NIX="$BATS_TEST_TMPDIR/stubs/nix"
  export SOURCES="$BATS_TEST_TMPDIR/pkgs/pnpm/sources.json"
}

@test "a newer 12.x is written: version, 4 assets, each hash the digest's SRI, keys sorted" {
  run --separate-stderr "$bump"
  [ "$status" -eq 0 ]
  [ "$output" = "NEW_VERSION=12.15.0" ]
  [ "$(jq -r .version "$SOURCES")" = 12.15.0 ]
  [ "$(jq -r '.assets | keys | join(" ")' "$SOURCES")" = "aarch64-darwin aarch64-linux x86_64-darwin x86_64-linux" ]
  base=https://github.com/pnpm/pnpm/releases/download/v12.15.0
  [ "$(jq -c '.assets["aarch64-darwin"]' "$SOURCES")" = "{\"hash\":\"sha256-sri-of-$hex_darwin_arm64\",\"source\":\"github-digest\",\"url\":\"$base/pnpm-darwin-arm64.tar.gz\"}" ]
  [ "$(jq -c '.assets["x86_64-darwin"]' "$SOURCES")" = "{\"hash\":\"sha256-sri-of-$hex_darwin_x64\",\"source\":\"github-digest\",\"url\":\"$base/pnpm-darwin-x64.tar.gz\"}" ]
  [ "$(jq -c '.assets["x86_64-linux"]' "$SOURCES")" = "{\"hash\":\"sha256-sri-of-$hex_linux_x64\",\"source\":\"github-digest\",\"url\":\"$base/pnpm-linux-x64.tar.gz\"}" ]
  [ "$(jq -c '.assets["aarch64-linux"]' "$SOURCES")" = "{\"hash\":\"sha256-sri-of-$hex_linux_arm64\",\"source\":\"github-digest\",\"url\":\"$base/pnpm-linux-arm64.tar.gz\"}" ]
  jq -S . "$SOURCES" | cmp - "$SOURCES"
}

@test "every asset is downloaded once, and nothing is left beside the sources file" {
  run --separate-stderr "$bump"
  [ "$status" -eq 0 ]
  [ "$(sort curl.calls | tr '\n' ' ')" = "https://github.com/pnpm/pnpm/releases/download/v12.15.0/pnpm-darwin-arm64.tar.gz https://github.com/pnpm/pnpm/releases/download/v12.15.0/pnpm-darwin-x64.tar.gz https://github.com/pnpm/pnpm/releases/download/v12.15.0/pnpm-linux-arm64.tar.gz https://github.com/pnpm/pnpm/releases/download/v12.15.0/pnpm-linux-x64.tar.gz " ]
  [ "$(ls pkgs/pnpm)" = sources.json ]
}

@test "the bump never runs git" {
  run --separate-stderr "$bump"
  [ "$status" -eq 0 ]
  [ ! -e git.calls ]
}

@test "already current is exit 0, silent, the file untouched, no release fetched" {
  "$bump" >/dev/null
  cp "$SOURCES" current.json
  rm curl.calls gh.calls
  run --separate-stderr "$bump"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  cmp current.json "$SOURCES"
  [ ! -e curl.calls ]
  [ "$(cat gh.calls)" = "api --paginate repos/pnpm/pnpm/releases" ]
}

@test "--force re-resolves the current version: right hashes are no change, no stdout" {
  "$bump" >/dev/null
  cp "$SOURCES" current.json
  rm curl.calls
  run --separate-stderr "$bump" --force
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  cmp current.json "$SOURCES"
  [ "$(wc -l <curl.calls)" -eq 4 ]
}

@test "--force at the current version repairs a wrong hash and says NEW_VERSION" {
  "$bump" >/dev/null
  jq -S '.assets["x86_64-linux"].hash = "sha256-wrong"' "$SOURCES" >wrong.json
  mv wrong.json "$SOURCES"
  run --separate-stderr "$bump" --force
  [ "$status" -eq 0 ]
  [ "$output" = "NEW_VERSION=12.15.0" ]
  [ "$(jq -r '.assets["x86_64-linux"].hash' "$SOURCES")" = "sha256-sri-of-$hex_linux_x64" ]
}

@test "a downgrade is refused, with --force too, the file byte-identical" {
  jq -S '.version = "12.16.0"' before.json >"$SOURCES"
  cp "$SOURCES" before.json
  for args in "" --force; do
    # shellcheck disable=SC2086 # no argument at all on the first pass
    run --separate-stderr "$bump" $args
    [ "$status" -eq 1 ]
    [ -z "$output" ]
    [ "$stderr" = "bump-pnpm: upstream's newest stable 12.x is 12.15.0, older than the pinned 12.16.0; refusing to downgrade (scripts V2)" ]
    cmp before.json "$SOURCES"
  done
  [ ! -e curl.calls ]
}

@test "a newest below the 12.14.0 floor is refused, the file byte-identical" {
  jq -S '.version = "12.9.0"' before.json >"$SOURCES"
  cp "$SOURCES" before.json
  jq '.[2].tag_name = "v12.13.0" | del(.[3])' releases.json >r.json
  mv r.json releases.json
  run --separate-stderr "$bump"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "bump-pnpm: upstream's newest stable 12.x is 12.13.0, below the floor 12.14.0; refusing (scripts V2, root V9)" ]
  cmp before.json "$SOURCES"
}

@test "a download that hashes to other than its digest is refused, the file byte-identical" {
  printf '%s' "$hex_darwin_x64" >assets/pnpm-linux-arm64.tar.gz
  run --separate-stderr "$bump"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "bump-pnpm: pnpm-linux-arm64.tar.gz hashes to $hex_darwin_x64, its digest says $hex_linux_arm64; sources untouched (scripts V3)" ]
  cmp before.json "$SOURCES"
  [ "$(ls pkgs/pnpm)" = sources.json ]
}

@test "an asset with no digest is refused, the file byte-identical" {
  jq '(.assets[] | select(.name == "pnpm-darwin-x64.tar.gz")) |= del(.digest)' release-v12.15.0.json >r.json
  mv r.json release-v12.15.0.json
  run --separate-stderr "$bump"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "bump-pnpm: v12.15.0 pnpm-darwin-x64.tar.gz has no sha256 digest; sources untouched (scripts V3)" ]
  cmp before.json "$SOURCES"
}

@test "a release missing an asset is refused, the file byte-identical" {
  jq 'del(.assets[] | select(.name == "pnpm-linux-x64.tar.gz"))' release-v12.15.0.json >r.json
  mv r.json release-v12.15.0.json
  run --separate-stderr "$bump"
  [ "$status" -eq 1 ]
  [ "$stderr" = "bump-pnpm: v12.15.0 pnpm-linux-x64.tar.gz has no sha256 digest; sources untouched (scripts V3)" ]
  cmp before.json "$SOURCES"
}

@test "a failed download is refused, the file byte-identical" {
  touch fail-pnpm-darwin-arm64.tar.gz
  run --separate-stderr "$bump"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "bump-pnpm: download of https://github.com/pnpm/pnpm/releases/download/v12.15.0/pnpm-darwin-arm64.tar.gz failed; sources untouched (scripts V3)" ]
  cmp before.json "$SOURCES"
}

@test "no stable 12.x upstream is exit 1, the file byte-identical" {
  jq '[.[] | select(.tag_name | startswith("v12.") | not)]' releases.json >r.json
  mv r.json releases.json
  run --separate-stderr "$bump"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  cmp before.json "$SOURCES"
}

@test "a missing sources file is exit 1 and names it" {
  rm "$SOURCES"
  run --separate-stderr "$bump"
  [ "$status" -eq 1 ]
  [ "$stderr" = "bump-pnpm: cannot read the pinned version from $SOURCES" ]
}

@test "an unknown argument is a usage error, exit 2, the file untouched" {
  for args in --frce "--force --force"; do
    # shellcheck disable=SC2086 # split on purpose: two arguments
    run --separate-stderr "$bump" $args
    [ "$status" -eq 2 ]
    [ "$stderr" = "usage: bump-pnpm.sh [--force]" ]
  done
  cmp before.json "$SOURCES"
}
