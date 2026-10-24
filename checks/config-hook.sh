#!/usr/bin/env bash
# The `config-hook` check's build (checks §I, checks V2, V3). RED stub:
# it never runs the hook and answers green, so its bats fails until the
# real check lands.
# Seams: PNPM_CONFIG_HOOK, PNPM, NODE, INSTALL_LOG, EXPECTED_VERSION.
# Usage: EXPECTED_VERSION=12.15.0 config-hook.sh
set -euo pipefail

echo "config-hook: pnpm ${EXPECTED_VERSION:-} installed the fixture offline; node requires is-number"
