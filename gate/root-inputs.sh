#!/usr/bin/env bash
# The root-inputs guard (gate V2, root V1): a flake lock's root node has
# exactly the inputs named, no more and no fewer, in any order. Each
# extra or missing input is a line on stderr, then exit 1.
# Usage: root-inputs.sh FLAKE-LOCK INPUT...
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: root-inputs.sh FLAKE-LOCK INPUT..." >&2
  exit 2
fi
lock=$1
shift

if ! have=$(jq -r '.nodes[.root].inputs | keys[]' "$lock" 2>/dev/null); then
  echo "root-inputs: $lock: not a flake lock (root V1)" >&2
  exit 1
fi
want=$(printf '%s\n' "$@" | sort -u)
have=$(printf '%s\n' "$have" | sort -u)

status=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  echo "root-inputs: $lock: root input $name is not allowed (root V1)" >&2
  status=1
done < <(comm -13 <(echo "$want") <(echo "$have"))
while IFS= read -r name; do
  [ -n "$name" ] || continue
  echo "root-inputs: $lock: root input $name is missing (root V1)" >&2
  status=1
done < <(comm -23 <(echo "$want") <(echo "$have"))
exit "$status"
