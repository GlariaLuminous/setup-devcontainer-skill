#!/usr/bin/env bash
# Static checks for the fixture projects under tests/fixtures/.
#
# These checks do NOT need Docker. They catch the class of bug that only
# shows up at build time -- a compose service pointing at a Dockerfile that
# does not exist, a build context that escapes the fixture, a devcontainer
# that would run as a user the image does not have -- before CI spends
# minutes building images.
#
# The real build is exercised by .github/workflows/validate.yml, which runs
# each fixture through @devcontainers/cli.
set -euo pipefail

cd "$(dirname "$0")/.."

failures=0

check() {
  local description="$1"
  shift
  if "$@"; then
    printf 'PASS  %s\n' "$description"
  else
    printf 'FAIL  %s\n' "$description"
    failures=$((failures + 1))
  fi
}

fixtures=$(find tests/fixtures -mindepth 1 -maxdepth 1 -type d | sort)

check "There is at least one fixture project" \
  test -n "$fixtures"

for fixture in $fixtures; do
  name=$(basename "$fixture")
  config="$fixture/.devcontainer/devcontainer.json"

  check "$name has a devcontainer.json" \
    test -f "$config"
  check "$name devcontainer.json is valid JSON" \
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$config"
  check "$name ships a verify.sh for the CI build" \
    test -f "$fixture/verify.sh"
  check "$name does not expose the host SSH directory" \
    sh -c "! grep -Rqs 'localEnv:.*\.ssh' '$fixture'"
  check "$name runs as a non-root user that the image ships" \
    node tests/check-fixture-user.mjs "$config" "$fixture"
  check "$name has no dangling build references" \
    node tests/check-fixture-refs.mjs "$fixture"
done

if (( failures > 0 )); then
  printf '\n%d fixture validation(s) failed.\n' "$failures"
  exit 1
fi

printf '\nAll fixture validations passed.\n'
