#!/usr/bin/env bats
# checks/config-hook.sh (checks §I `config-hook`, checks V2, V3): the hook
# installs with its log kept, and the build is red on a lockfile-version
# warning, on ERR_PNPM_, on another pnpm than the pin, or when node cannot
# require is-number. The hook, pnpm and node are stubs behind the
# PNPM_CONFIG_HOOK, PNPM and NODE seams; the hook stub prints the lines of
# hook.out. The script runs under bash, as the readFile'd buildPhase does.

bats_require_minimum_version 1.5.0

setup() {
  check="$BATS_TEST_DIRNAME/../../../checks/config-hook.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  # A clean install, as the pin's hook prints it with pnpm 12.15.0
  # (2026-10-24): `trustLockfile` names the lockfile, never a version.
  cat >hook.out <<'LOG'
Executing pnpmConfigHook
Found 'pnpm' with version '12.15.0'
Using fetcherVersion: 4
Configuring pnpm store
Installing dependencies
  "trustLockfile": true,
Lockfile is up to date, resolution step is skipped
+ is-number 7.0.0
Done in 49ms using pnpm v12.15.0
Finished pnpmConfigHook
LOG
  cat >hook <<'STUB'
#!/usr/bin/env bash
cat "$BATS_TEST_TMPDIR/hook.out"
exit "${HOOK_STATUS:-0}"
STUB
  cat >pnpm <<'STUB'
#!/usr/bin/env bash
[ "$*" = --version ] || exit 9
echo "${PNPM_STUB_VERSION:-12.15.0}"
STUB
  cat >node <<'STUB'
#!/usr/bin/env bash
echo "$*" >>"$BATS_TEST_TMPDIR/node.calls"
exit "${NODE_STATUS:-0}"
STUB
  chmod +x hook pnpm node
  export PNPM_CONFIG_HOOK="$BATS_TEST_TMPDIR/hook"
  export PNPM="$BATS_TEST_TMPDIR/pnpm"
  export NODE="$BATS_TEST_TMPDIR/node"
  export EXPECTED_VERSION=12.15.0
}

@test "a clean install: exit 0, the log kept in install.log, node requires is-number" {
  run --separate-stderr bash "$check"
  [ "$status" -eq 0 ]
  [ "${lines[-1]}" = "config-hook: pnpm 12.15.0 installed the fixture offline; node requires is-number" ]
  cmp hook.out install.log
  [ "$(cat node.calls)" = "-e require('is-number')" ]
}

@test "INSTALL_LOG names where the log goes" {
  INSTALL_LOG="$BATS_TEST_TMPDIR/elsewhere.log" run --separate-stderr bash "$check"
  [ "$status" -eq 0 ]
  cmp hook.out elsewhere.log
}

@test "a lockfile-version warning, any case: exit 1, the line quoted (checks V2)" {
  echo 'WARN  Ignoring not compatible LOCKFILE at pnpm-lock.yaml: its Version is 10.0' >>hook.out
  run --separate-stderr bash "$check"
  [ "$status" -eq 1 ]
  [ "$stderr" = "WARN  Ignoring not compatible LOCKFILE at pnpm-lock.yaml: its Version is 10.0
config-hook: the install log warns about the lockfile version (checks V2)" ]
  [ ! -e node.calls ]
}

@test "pnpm 12.15.0's own words for a lockfile too new are red (checks V2)" {
  echo '      pnpm-lock.yaml" is broken: The lockfileVersion of 10.0 is incompatible' >>hook.out
  run --separate-stderr bash "$check"
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"config-hook: the install log warns about the lockfile version (checks V2)" ]]
}

@test "ERR_PNPM_ in the log: exit 1, the line quoted (checks V2)" {
  echo 'Error: ERR_PNPM_NO_OFFLINE_TARBALL  A package is missing from the store' >>hook.out
  run --separate-stderr bash "$check"
  [ "$status" -eq 1 ]
  [ "$stderr" = "Error: ERR_PNPM_NO_OFFLINE_TARBALL  A package is missing from the store
config-hook: the install log holds ERR_PNPM_ (checks V2)" ]
}

@test "a failing hook fails the build, its output still shown" {
  HOOK_STATUS=1 run --separate-stderr bash "$check"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Executing pnpmConfigHook"* ]]
  [ ! -e node.calls ]
}

@test "another pnpm than the pin after the hook: exit 1, names both (checks V3)" {
  PNPM_STUB_VERSION=12.14.0 run --separate-stderr bash "$check"
  [ "$status" -eq 1 ]
  [ "$stderr" = "config-hook: pnpm --version is 12.14.0 after the hook, sources.json pins 12.15.0 (checks V3)" ]
  [ ! -e node.calls ]
}

@test "node cannot require is-number: exit 1" {
  NODE_STATUS=1 run --separate-stderr bash "$check"
  [ "$status" -eq 1 ]
}

@test "no expected version is a usage error, exit 2, the hook never runs" {
  EXPECTED_VERSION='' run --separate-stderr bash "$check"
  [ "$status" -eq 2 ]
  [ "$stderr" = "config-hook.sh: EXPECTED_VERSION must be set" ]
  [ ! -e install.log ]
}
