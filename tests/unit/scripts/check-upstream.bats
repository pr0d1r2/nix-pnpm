#!/usr/bin/env bats
# scripts/check-upstream.sh (root §I.ci, scripts §I): the daily upstream
# detection. Green when the pin is upstream's newest stable 12.x, red
# with a `::error::` line naming both versions when it is not. gh is a
# stub behind the GH seam, the sources file a fixture behind SOURCES.

bats_require_minimum_version 1.5.0

setup() {
  check="$BATS_TEST_DIRNAME/../../../scripts/check-upstream.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  cat >releases.json <<'JSON'
[
  { "tag_name": "v11.28.8", "prerelease": false, "draft": false },
  { "tag_name": "v12.16.0-rc.1", "prerelease": true, "draft": false },
  { "tag_name": "v12.15.0", "prerelease": false, "draft": false }
]
JSON
  echo '{ "version": "12.15.0", "assets": {} }' >sources.json
  cat >gh <<'STUB'
#!/usr/bin/env bash
[ "$*" = "api --paginate repos/pnpm/pnpm/releases" ] || exit 9
cat "$BATS_TEST_TMPDIR/releases.json"
STUB
  chmod +x gh
  export GH="$BATS_TEST_TMPDIR/gh"
  export SOURCES="$BATS_TEST_TMPDIR/sources.json"
}

@test "the pin is upstream's newest stable 12.x: exit 0" {
  run --separate-stderr "$check"
  [ "$status" -eq 0 ]
  [ "$output" = "check-upstream: pnpm 12.15.0 is upstream's newest stable 12.x" ]
}

@test "a newer stable 12.x upstream: exit 1, one ::error:: line naming both" {
  jq '. + [{ "tag_name": "v12.16.0", "prerelease": false, "draft": false }]' releases.json >r.json
  mv r.json releases.json
  run --separate-stderr "$check"
  [ "$status" -eq 1 ]
  [ "$output" = "::error::pnpm 12.16.0 is upstream's newest stable 12.x, the pin is 12.15.0; run scripts/bump-pnpm.sh" ]
}

@test "a pin newer than upstream's newest is red too, both named" {
  echo '{ "version": "12.17.0", "assets": {} }' >sources.json
  run --separate-stderr "$check"
  [ "$status" -eq 1 ]
  [ "$output" = "::error::the pin 12.17.0 is not upstream's newest stable 12.x 12.15.0; check upstream's release list" ]
}

@test "upstream unreadable is exit 1" {
  printf '#!/usr/bin/env bash\nexit 1\n' >gh
  run --separate-stderr "$check"
  [ "$status" -eq 1 ]
}

@test "a missing sources file is exit 1 and names it" {
  rm sources.json
  run --separate-stderr "$check"
  [ "$status" -eq 1 ]
  [ "$output" = "::error::cannot read the pinned version from $SOURCES" ]
}

@test "any argument is a usage error, exit 2" {
  run --separate-stderr "$check" --force
  [ "$status" -eq 2 ]
  [ "$stderr" = "usage: check-upstream.sh" ]
}
