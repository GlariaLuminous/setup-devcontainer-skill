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

check "workspaceFolder is the mounted project root" \
  sh -c 'test "$PWD" = "/workspace"'
check "compose injects DATABASE_URL" \
  sh -c 'test -n "$DATABASE_URL"'
check "the db service resolves by name and accepts connections" \
  sh -c 'pg_isready -h db -p 5432 -U app'
check "postCreateCommand ran npm ci" \
  test -d node_modules
check "the project test suite passes" \
  npm test
check "the container does not run as root" \
  sh -c 'test "$(id -u)" != "0"'

if (( failures > 0 )); then
  printf '\n%d check(s) failed.\n' "$failures"
  exit 1
fi

printf '\nAll checks passed.\n'
