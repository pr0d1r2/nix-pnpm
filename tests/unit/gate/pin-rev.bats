#!/usr/bin/env bats
# gate/pin-rev.sh (gate V4, root V1): the flake's nixpkgs is exactly the
# rev nixpkgs-lock publishes. nix is a stub; no network.

bats_require_minimum_version 1.5.0

setup() {
  guard="$BATS_TEST_DIRNAME/../../../gate/pin-rev.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  mkdir stubs
  cat >stubs/nix <<'STUB'
#!/usr/bin/env bash
[ "$*" = "flake metadata --json github:pr0d1r2/nixpkgs-lock" ] || exit 9
[ -n "${STUB_FAIL:-}" ] && exit 1
printf '{"locks":{"nodes":{"nixpkgs":{"locked":{"rev":"%s"}}}}}\n' "$STUB_REV"
STUB
  chmod +x stubs/nix
  export NIX="$BATS_TEST_TMPDIR/stubs/nix"
  export STUB_REV=aaa111
  printf '{"nodes":{"nixpkgs":{"locked":{"rev":"aaa111"}},"root":{}},"root":"root"}\n' >flake.lock
}

@test "the lock's nixpkgs is the published rev: pass, quietly" {
  run --separate-stderr "$guard" flake.lock
  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
}

@test "a drifted rev is refused, naming both" {
  STUB_REV=bbb222 run --separate-stderr "$guard" flake.lock
  [ "$status" -eq 1 ]
  [ "$stderr" = "pin-rev: flake.lock locks nixpkgs aaa111, nixpkgs-lock publishes bbb222 (root V1)" ]
}

@test "a lock without a nixpkgs rev is refused" {
  printf '{"nodes":{"root":{}},"root":"root"}\n' >flake.lock
  run --separate-stderr "$guard" flake.lock
  [ "$status" -eq 1 ]
  [ "$stderr" = "pin-rev: flake.lock: no nixpkgs rev in the lock (root V1)" ]
}

@test "nixpkgs-lock that cannot be read is refused, not passed" {
  STUB_FAIL=1 run --separate-stderr "$guard" flake.lock
  [ "$status" -eq 1 ]
  [ "$stderr" = "pin-rev: cannot read the rev nixpkgs-lock publishes (root V1)" ]
}

@test "anything but one file is a usage error, exit 2" {
  run --separate-stderr "$guard"
  [ "$status" -eq 2 ]
  [ "$stderr" = "usage: pin-rev.sh FLAKE-LOCK" ]
}
