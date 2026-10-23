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

check "Go 1.26 is the toolchain on PATH" \
  sh -c 'go version | grep -q "go1\.26"'
check "go.mod is readable by the build" \
  go list -m
check "go vet passes" \
  go vet ./...
check "the project test suite passes" \
  go test ./...
check "the container does not run as root" \
  sh -c 'test "$(id -u)" != "0"'

if (( failures > 0 )); then
  printf '\n%d check(s) failed.\n' "$failures"
  exit 1
fi

printf '\nAll checks passed.\n'
