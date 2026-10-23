#!/usr/bin/env bash
# Runs inside the built container, with the workspace as the working directory.
set -euo pipefail

failures=0

check() {
  local description="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS  %s\n' "$description"
  else
    printf 'FAIL  %s\n' "$description"
    failures=$((failures + 1))
  fi
}

check "Node 22 is the runtime on PATH" \
  sh -c 'node --version | grep -q "^v22\."'
check "postCreateCommand ran npm ci" \
  test -d node_modules
check "the project test suite passes" \
  npm test
check "the workspace mount is writable" \
  sh -c 'touch .verify-probe && rm .verify-probe'
check "the container does not run as root" \
  sh -c 'test "$(id -u)" != "0"'

if (( failures > 0 )); then
  printf '\n%d check(s) failed.\n' "$failures"
  exit 1
fi

printf '\nAll checks passed.\n'
