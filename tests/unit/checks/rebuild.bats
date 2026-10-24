#!/usr/bin/env bats
# checks/rebuild.sh (checks V1, checks T2): the fixture's fixed-output
# deps fetch builds, then builds again with --rebuild. nix is a stub that
# logs its calls; no network.

bats_require_minimum_version 1.5.0

setup() {
  script="$BATS_TEST_DIRNAME/../../../checks/rebuild.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  mkdir stubs
  cat >stubs/nix <<'STUB'
#!/usr/bin/env bash
echo "$*" >>"$BATS_TEST_TMPDIR/calls"
case "$*" in
eval*) echo aarch64-darwin ;;
*--rebuild*) [ -z "${STUB_REBUILD_FAIL:-}" ] || {
  echo "error: derivation may not be deterministic" >&2
  exit 1
} ;;
build*) [ -z "${STUB_BUILD_FAIL:-}" ] || exit 1 ;;
esac
STUB
  chmod +x stubs/nix
  export NIX="$BATS_TEST_TMPDIR/stubs/nix"
}

@test "builds the current system's fetch-deps, then rebuilds it" {
  run --separate-stderr "$script"
  [ "$status" -eq 0 ]
  [ "$(sed -n 1p calls)" = "eval --raw --impure --expr builtins.currentSystem" ]
  [ "$(sed -n 2p calls)" = "build --print-build-logs --no-link .#checks.aarch64-darwin.fetch-deps" ]
  [ "$(sed -n 3p calls)" = "build --rebuild --print-build-logs --no-link .#checks.aarch64-darwin.fetch-deps" ]
}

@test "a rebuild that differs is red and says so" {
  STUB_REBUILD_FAIL=1 run --separate-stderr "$script"
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"rebuild: .#checks.aarch64-darwin.fetch-deps is not reproducible (checks V1)"* ]]
}

@test "a first build that fails is red and never rebuilds" {
  STUB_BUILD_FAIL=1 run --separate-stderr "$script"
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"rebuild: .#checks.aarch64-darwin.fetch-deps does not build (checks V1)"* ]]
  [ "$(wc -l <calls)" -eq 2 ]
}

@test "any argument is a usage error, exit 2" {
  run --separate-stderr "$script" extra
  [ "$status" -eq 2 ]
  [ "$stderr" = "usage: rebuild.sh" ]
}
