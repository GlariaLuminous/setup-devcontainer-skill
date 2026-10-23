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

check "Python 3.12 is the interpreter on PATH" \
  sh -c 'python --version | grep -q "Python 3\.12"'
check "postCreateCommand installed requirements.txt" \
  python -c 'import pytest'
check "pytest runs from the installed environment" \
  python -m pytest -q
check "the workspace mount is writable" \
  sh -c 'touch .verify-probe && rm .verify-probe'
check "the container does not run as root" \
  sh -c 'test "$(id -u)" != "0"'

if (( failures > 0 )); then
  printf '\n%d check(s) failed.\n' "$failures"
  exit 1
fi

printf '\nAll checks passed.\n'
