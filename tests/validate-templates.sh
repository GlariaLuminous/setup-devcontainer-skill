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
  grep -Eq '^      context: \.\.[[:space:]]*$' templates/docker-compose.yml
check "Compose mounts the project root" \
  grep -Eq '^      - \.\./:/workspace[[:space:]]*$' templates/docker-compose.yml
check "Compose has no interpolated dependency keys" \
  sh -c '! grep -q "WITH_REDIS" templates/docker-compose.yml'
check "Compose has no malformed volume suffix" \
  sh -c '! grep -q "CONTAINER_VOLUME_DEPS" templates/docker-compose.yml'
check "Templates do not expose the host SSH directory" \
  sh -c '! grep -Rqs "localEnv:.*\.ssh" templates SKILL.md'
check "Swift creates a non-root development user" \
  grep -q '"dockerfile": "Swift.Dockerfile"' templates/swift.jsonc
check "Swift Dockerfile defines the vscode user" \
  grep -Eq '^ARG USERNAME=vscode[[:space:]]*$' templates/Swift.Dockerfile
check "Python install command is selected during generation" \
  grep -q '<install-command>' templates/python.jsonc
check "Node install command is selected during generation" \
  grep -q '<install-command>' templates/node.jsonc
check "Go initialization does not modify go.mod" \
  grep -q '"postCreateCommand": "go mod download"' templates/go.jsonc
check "Deno install command does not assume an entrypoint" \
  grep -q '"postCreateCommand": "deno install"' templates/deno.jsonc
check "Deno uses an existing Feature" \
  grep -q 'ghcr.io/devcontainers-extra/features/deno:1' templates/deno.jsonc
check "Scala uses an existing sbt Feature" \
  grep -q 'ghcr.io/devcontainers-extra/features/sbt-sdkman:2' templates/scala.jsonc
check "Scala does not pass unsupported Java Feature options" \
  sh -c '! grep -q "installSbt" templates/scala.jsonc'
check "Generated CI uses an existing devcontainers/ci tag" \
  grep -q 'uses: devcontainers/ci@v0.3' templates/ci/devcontainer-ci.yml
check "Generated CI does not assume npm" \
  sh -c '! grep -Eq "npm (ci|test|run)" templates/ci/devcontainer-ci.yml'
check "Java install command is selected during generation" \
  grep -q '<install-command>' templates/java.jsonc
check "Kotlin install command is selected during generation" \
  grep -q '<install-command>' templates/kotlin.jsonc
check "Swift install command is selected during generation" \
  grep -q '<install-command>' templates/swift.jsonc
check "Every documented language has a template" \
  sh -c 'test "$(find templates -maxdepth 1 -name "*.jsonc" | wc -l | tr -d " ")" = 13'

for template in templates/*.jsonc; do
  check "$template is valid JSONC" node tests/parse-jsonc.mjs "$template"
done

# remoteUser has to name a user that exists in the image, or the container
# refuses to start: "unable to find user vscode: no matching entries in
# passwd file". typescript-node/javascript-node ship "node", universal ships
# "codespace", every other devcontainers image ships "vscode".
for template in templates/*.jsonc; do
  check "$template sets the remoteUser its image actually ships" \
    node tests/check-template-user.mjs "$template"
done

if (( failures > 0 )); then
  printf '\n%d validation(s) failed.\n' "$failures"
  exit 1
fi

printf '\nAll template validations passed.\n'
