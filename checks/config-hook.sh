#!/usr/bin/env bash
# The `config-hook` check's build (checks §I, checks V2, V3): pnpmConfigHook
# installs the fixture offline from fetch-deps with its log kept in
# INSTALL_LOG. Red when the log warns about the lockfile version (a line
# with `lockfile` and `version`, any case) or holds `ERR_PNPM_`, when
# `pnpm --version` here is not the pinned one though the fixture's
# `packageManager` names another, or when node cannot require is-number.
# checks/default.nix loads it with builtins.readFile as the buildPhase, so
# the hook runs in this shell and its exports (pnpm_config_pm_on_fail)
# reach the version probe, as in a consumer's build.
# Seams: PNPM_CONFIG_HOOK (default pnpmConfigHook), PNPM (default pnpm),
# NODE (default node), INSTALL_LOG (default install.log), EXPECTED_VERSION
# (required).
# Usage: EXPECTED_VERSION=12.15.0 config-hook.sh
set -euo pipefail

PNPM_CONFIG_HOOK=${PNPM_CONFIG_HOOK:-pnpmConfigHook}
PNPM=${PNPM:-pnpm}
NODE=${NODE:-node}
INSTALL_LOG=${INSTALL_LOG:-install.log}

if [ -z "${EXPECTED_VERSION:-}" ]; then
  echo "config-hook.sh: EXPECTED_VERSION must be set" >&2
  exit 2
fi

# The hook runs in this shell, never a subshell: its exports must stay.
# It reads unset variables (`$pnpmWorkspace`, the pin's hook line 77), so
# `set -u` is off for it alone. tee runs as a process substitution; a bare
# `wait` (bash >= 5.1) lets it finish writing the log.
set +u
"$PNPM_CONFIG_HOOK" > >(tee "$INSTALL_LOG") 2>&1
set -u
wait

if grep -iE 'lockfile.*version|version.*lockfile' "$INSTALL_LOG" >&2; then
  echo "config-hook: the install log warns about the lockfile version (checks V2)" >&2
  exit 1
fi
if grep 'ERR_PNPM_' "$INSTALL_LOG" >&2; then
  echo "config-hook: the install log holds ERR_PNPM_ (checks V2)" >&2
  exit 1
fi

actual=$("$PNPM" --version)
if [ "$actual" != "$EXPECTED_VERSION" ]; then
  echo "config-hook: pnpm --version is $actual after the hook, sources.json pins $EXPECTED_VERSION (checks V3)" >&2
  exit 1
fi

"$NODE" -e "require('is-number')"
echo "config-hook: pnpm $actual installed the fixture offline; node requires is-number"
