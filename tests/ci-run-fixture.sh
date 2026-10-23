#!/usr/bin/env bash
# Builds a fixture's devcontainer and runs its checks inside the container.
#
# Requires Docker and the Dev Container CLI. CI installs the CLI before
# calling this script; locally you can do the same with
#   npm install -g @devcontainers/cli
#
# Usage: tests/ci-run-fixture.sh <workspace-folder> [command]
set -euo pipefail

workspace="${1:?usage: ci-run-fixture.sh <workspace-folder> [command]}"
command="${2:-bash verify.sh}"

if ! command -v devcontainer >/dev/null 2>&1; then
  echo "devcontainer CLI not found. Install it with: npm install -g @devcontainers/cli" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not available; this script only runs in CI or on a machine with Docker." >&2
  exit 1
fi

echo "==> Building devcontainer for $workspace"
up_output=$(devcontainer up --workspace-folder "$workspace")
printf '%s\n' "$up_output"

# The CLI prints a JSON result on the last line. A build that fails to reach
# the container still exits 0 in some versions, so check the outcome itself.
outcome=$(printf '%s\n' "$up_output" | tail -n 1 | node -e '
  let raw = "";
  process.stdin.on("data", (c) => (raw += c));
  process.stdin.on("end", () => {
    try {
      process.stdout.write(String(JSON.parse(raw).outcome ?? "unknown"));
    } catch {
      process.stdout.write("unparseable");
    }
  });
')

if [ "$outcome" != "success" ]; then
  echo "devcontainer up reported outcome=$outcome" >&2
  exit 1
fi

echo "==> Running inside the container: $command"
devcontainer exec --workspace-folder "$workspace" bash -lc "$command"
