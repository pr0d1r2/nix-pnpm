#!/usr/bin/env bats
# checks/version.sh (checks §I `version`, checks V3, root V9): pnpm
# --version is the pinned version and at or above the floor, by version
# order. pnpm is a stub behind the PNPM seam; the script runs under bash,
# as the readFile'd build command does.

bats_require_minimum_version 1.5.0

setup() {
  version="$BATS_TEST_DIRNAME/../../../checks/version.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  cat >pnpm <<'STUB'
#!/usr/bin/env bash
[ "$*" = --version ] || exit 9
echo "$STUB_VERSION"
STUB
  chmod +x pnpm
  export PNPM="$BATS_TEST_TMPDIR/pnpm"
  export STUB_VERSION=12.15.0
  export EXPECTED_VERSION=12.15.0
  export FLOOR_VERSION=12.14.0
}

@test "the pinned version at or above the floor: exit 0, says so" {
  run --separate-stderr bash "$version"
  [ "$status" -eq 0 ]
  [ "$output" = "version: pnpm 12.15.0 is the pinned version, at or above 12.14.0" ]
  [ -z "$stderr" ]
}

@test "the floor itself is enough" {
  STUB_VERSION=12.14.0 EXPECTED_VERSION=12.14.0 run --separate-stderr bash "$version"
  [ "$status" -eq 0 ]
}

@test "pnpm answers another version than the pin: exit 1, names both (checks V3)" {
  STUB_VERSION=12.14.0 run --separate-stderr bash "$version"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "version: pnpm --version is 12.14.0, sources.json pins 12.15.0 (checks V3)" ]
}

@test "below the floor by version order: 12.9.0 < 12.14.0 though it sorts after lexically (root V9)" {
  STUB_VERSION=12.9.0 EXPECTED_VERSION=12.9.0 run --separate-stderr bash "$version"
  [ "$status" -eq 1 ]
  [ "$stderr" = "version: pnpm 12.9.0 is below the floor 12.14.0 (root V9)" ]
}

@test "a failing pnpm is a failure" {
  printf '#!/usr/bin/env bash\nexit 3\n' >pnpm
  run --separate-stderr bash "$version"
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}

@test "no expected version or no floor is a usage error, exit 2" {
  EXPECTED_VERSION='' run --separate-stderr bash "$version"
  [ "$status" -eq 2 ]
  [ "$stderr" = "version.sh: EXPECTED_VERSION and FLOOR_VERSION must be set" ]
  FLOOR_VERSION='' run --separate-stderr bash "$version"
  [ "$status" -eq 2 ]
}
