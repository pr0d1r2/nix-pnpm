#!/usr/bin/env bats
# gate/root-inputs.sh (gate V2, root V1): a flake lock's root node has
# exactly the inputs named, no more and no fewer.

bats_require_minimum_version 1.5.0

setup() {
  guard="$BATS_TEST_DIRNAME/../../../gate/root-inputs.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  cat >flake.lock <<'LOCK'
{
  "nodes": {
    "nixpkgs-lock": { "inputs": { "nixpkgs": "nixpkgs" } },
    "nixpkgs": { "locked": { "owner": "NixOS", "repo": "nixpkgs" } },
    "root": {
      "inputs": {
        "nixpkgs": ["nixpkgs-lock", "nixpkgs"],
        "nixpkgs-lock": "nixpkgs-lock"
      }
    }
  },
  "root": "root",
  "version": 7
}
LOCK
}

@test "the root flake's two inputs pass, quietly, in any order" {
  run --separate-stderr "$guard" flake.lock nixpkgs-lock nixpkgs
  [ "$status" -eq 0 ]
  [ -z "$stderr" ]
}

@test "an extra root input is refused by name" {
  jq '.nodes.root.inputs["flake-utils"] = "flake-utils"' flake.lock >extra.lock
  run --separate-stderr "$guard" extra.lock nixpkgs nixpkgs-lock
  [ "$status" -eq 1 ]
  [ "$stderr" = "root-inputs: extra.lock: root input flake-utils is not allowed (root V1)" ]
}

@test "a missing root input is refused by name" {
  jq 'del(.nodes.root.inputs.nixpkgs)' flake.lock >missing.lock
  run --separate-stderr "$guard" missing.lock nixpkgs nixpkgs-lock
  [ "$status" -eq 1 ]
  [ "$stderr" = "root-inputs: missing.lock: root input nixpkgs is missing (root V1)" ]
}

@test "a file that is no lock is refused" {
  printf 'not json\n' >bad.lock
  run --separate-stderr "$guard" bad.lock nixpkgs
  [ "$status" -eq 1 ]
  [ "$stderr" = "root-inputs: bad.lock: not a flake lock (root V1)" ]
}

@test "no input names is a usage error, exit 2" {
  run --separate-stderr "$guard" flake.lock
  [ "$status" -eq 2 ]
  [ "$stderr" = "usage: root-inputs.sh FLAKE-LOCK INPUT..." ]
}
