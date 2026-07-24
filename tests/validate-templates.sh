#!/usr/bin/env bash
set -euo pipefail

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

check "Compose build context points at the project root" \
  grep -q '^      context: \.\.$' templates/docker-compose.yml
check "Compose mounts the project root" \
  grep -q '^      - \.\./:/workspace$' templates/docker-compose.yml
check "Compose has no interpolated dependency keys" \
  sh -c '! grep -q "WITH_REDIS" templates/docker-compose.yml'
check "Compose has no malformed volume suffix" \
  sh -c '! grep -q "CONTAINER_VOLUME_DEPS" templates/docker-compose.yml'
check "Templates do not expose the host SSH directory" \
  sh -c '! grep -Rqs "localEnv:.*\.ssh" templates SKILL.md'
check "Swift creates a non-root development user" \
  grep -q '"dockerfile": "Swift.Dockerfile"' templates/swift.jsonc
check "Swift Dockerfile defines the vscode user" \
  grep -q '^ARG USERNAME=vscode$' templates/Swift.Dockerfile
check "Python install command is selected during generation" \
  grep -q '<install-command>' templates/python.jsonc
check "Node install command is selected during generation" \
  grep -q '<install-command>' templates/node.jsonc
check "Go initialization does not modify go.mod" \
  grep -q '"postCreateCommand": "go mod download"' templates/go.jsonc
check "Every documented language has a template" \
  sh -c 'test "$(find templates -maxdepth 1 -name "*.jsonc" | wc -l | tr -d " ")" = 13'

for template in templates/*.jsonc; do
  check "$template is valid JSON" node -e \
    'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$template"
done

if (( failures > 0 )); then
  printf '\n%d validation(s) failed.\n' "$failures"
  exit 1
fi

printf '\nAll template validations passed.\n'
