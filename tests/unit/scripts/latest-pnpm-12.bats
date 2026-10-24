#!/usr/bin/env bats
# scripts/latest-pnpm-12.sh (scripts V1, root V4): the newest stable 12.x
# from the release list, by version order. gh is a stub behind the GH
# seam that prints the fixture pages; no network.

bats_require_minimum_version 1.5.0

setup() {
  latest="$BATS_TEST_DIRNAME/../../../scripts/latest-pnpm-12.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  # Two pages, as `gh api --paginate` prints them: one array after another.
  # 11.x and pnpr@* interleave, the 13.x, the rc and the draft are newer,
  # and 12.9.1 is newer by date than 12.10.0.
  cat >releases.json <<'JSON'
[
  { "tag_name": "v11.28.8", "prerelease": false, "draft": false, "published_at": "2026-10-22T00:00:00Z" },
  { "tag_name": "pnpr@0.1.0-alpha.16", "prerelease": true, "draft": false, "published_at": "2026-10-21T00:00:00Z" },
  { "tag_name": "v12.9.1", "prerelease": false, "draft": false, "published_at": "2026-10-20T00:00:00Z" },
  { "tag_name": "v13.0.0", "prerelease": false, "draft": false, "published_at": "2026-10-19T00:00:00Z" }
]
[
  { "tag_name": "v12.16.0-rc.1", "prerelease": true, "draft": false, "published_at": "2026-10-18T00:00:00Z" },
  { "tag_name": "v12.17.0", "prerelease": false, "draft": true, "published_at": "2026-10-17T00:00:00Z" },
  { "tag_name": "v12.10.0", "prerelease": false, "draft": false, "published_at": "2026-10-01T00:00:00Z" },
  { "tag_name": "v12.2.0", "prerelease": false, "draft": false, "published_at": "2026-09-01T00:00:00Z" }
]
JSON
  cat >gh <<'STUB'
#!/usr/bin/env bash
echo "$*" >>"$BATS_TEST_TMPDIR/gh.calls"
[ "$*" = "api --paginate repos/pnpm/pnpm/releases" ] || exit 9
cat "$BATS_TEST_TMPDIR/releases.json"
STUB
  chmod +x gh
  export GH="$BATS_TEST_TMPDIR/gh"
}

@test "prints 12.10.0: no 11.x, 13.x, pnpr@*, prerelease or draft, and 12.10.0 beats 12.9.1" {
  run --separate-stderr "$latest"
  [ "$status" -eq 0 ]
  [ "$output" = "12.10.0" ]
  [ -z "$stderr" ]
}

@test "asks for every page of the release list, never releases/latest" {
  run --separate-stderr "$latest"
  [ "$status" -eq 0 ]
  [ "$(cat gh.calls)" = "api --paginate repos/pnpm/pnpm/releases" ]
}

@test "no stable 12.x in the list is exit 1, and says so" {
  jq '[.[] | select(.tag_name | startswith("v12.") | not)]' releases.json >others.json
  mv others.json releases.json
  run --separate-stderr "$latest"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "latest-pnpm-12: no stable v12.x.y release in repos/pnpm/pnpm/releases (scripts V1)" ]
}

@test "a failing gh is exit 1, nothing printed" {
  printf '#!/usr/bin/env bash\necho "gh: HTTP 502" >&2\nexit 1\n' >gh
  run --separate-stderr "$latest"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "any argument is a usage error, exit 2" {
  run --separate-stderr "$latest" --force
  [ "$status" -eq 2 ]
  [ "$stderr" = "usage: latest-pnpm-12.sh" ]
}
