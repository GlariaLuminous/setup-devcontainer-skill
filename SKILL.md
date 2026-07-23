---
name: setup-devcontainer
description: Generates a complete DevContainer configuration for any project. Use when the user wants to set up a development container, configure a reproducible dev environment, add devcontainer.json, create a Docker-based development setup, or make their project ready for GitHub Codespaces.
---

# Setup DevContainer

## Overview

Generates `devcontainer.json` + optional `Dockerfile` + optional `docker-compose.yml` for any project. The result is a reproducible, portable development environment that works locally (VS Code Remote, JetBrains), in GitHub Codespaces, and in CI.

The skill auto-detects the project's language, framework, package manager, and service dependencies, then generates optimal configuration.

## When to Use

- User says "set up a dev container for this project"
- User says "make this run in GitHub Codespaces"
- User says "I want a reproducible dev environment"
- Project has no `.devcontainer/` directory
- Onboarding takes more than 3 steps in README
- User says "it works on my machine" about a project

## When NOT to Use

- Project already has a working `.devcontainer/` — ask before overwriting
- Project uses Nix/Devbox as its primary dev environment — those are alternatives, not compatible

## Process

### Step 1: Detect the project stack

Scan the project root for these files in order:

| File | Language | Package Manager | Test Runner | Linter/Formatter |
|------|----------|-----------------|-------------|------------------|
| `package.json` | Node.js / TypeScript | npm / pnpm / yarn / bun | jest / vitest / mocha / ava | eslint / prettier / biome |
| `requirements.txt` or `pyproject.toml` | Python | pip / poetry / pdm / uv | pytest / unittest / tox | ruff / black / flake8 |
| `Cargo.toml` | Rust | cargo | cargo test | rustfmt / clippy |
| `go.mod` | Go | go mod | go test | golangci-lint |
| `build.gradle` or `pom.xml` | Java | gradle / maven | junit | checkstyle / spotless |
| `*.csproj` or `*.sln` | .NET / C# | dotnet / nuget | dotnet test | dotnet format |
| `Gemfile` | Ruby | bundler | rspec / minitest | rubocop |
| `composer.json` | PHP | composer | phpunit | php-cs-fixer |
| `CMakeLists.txt` or `Makefile` | C / C++ | cmake / make | ctest | clang-format |
| `build.sbt` | Scala | sbt | sbt test | scalafmt |
| `*.gradle.kts` or `*.gradle` | Kotlin | gradle | gradle test | ktlint / detekt |
| `Package.swift` | Swift | swift | swift test | swift-format |
| `deno.json` or `deno.jsonc` | Deno | deno | deno test | deno lint / deno fmt |

**Completion criterion**: language, package manager, test runner, and linter are identified. If detection is ambiguous, ask the user.

### Step 2: Determine the strategy

Choose based on project complexity:

```
Strategy decision tree:
├── Project needs only runtime + package manager
│   └── Use IMAGE strategy (pre-built image, no Dockerfile)
├── Project needs system dependencies (C libraries, native extensions)
│   └── Use DOCKERFILE strategy (custom Dockerfile + devcontainer.json)
└── Project needs services (database, cache, queue)
    └── Use COMPOSE strategy (docker-compose.yml + devcontainer.json)
```

Detect service needs by scanning:
- PostgreSQL: `psycopg2`, `pg`, `pgvector`, `postgres` in dependencies
- MySQL: `mysql-connector`, `mysql2`, `prisma mysql`
- Redis: `redis`, `ioredis`, `redis-py`, `sidekiq`
- MongoDB: `mongoose`, `mongodb`, `pymongo`

**Completion criterion**: strategy is selected and user has confirmed it.

### Step 3: Generate `.devcontainer/devcontainer.json`

Create `.devcontainer/` directory and write `devcontainer.json`.

#### Strategy A: Image-only

Pick the base image from this table:

| Language | Image | Tags |
|----------|-------|------|
| Python | `mcr.microsoft.com/devcontainers/python` | `3.14`, `3.13`, `3.12`, `3.11` |
| Node.js | `mcr.microsoft.com/devcontainers/typescript-node` | `24`, `22`, `20` |
| Rust | `mcr.microsoft.com/devcontainers/rust` | `1` |
| Go | `mcr.microsoft.com/devcontainers/go` | `1.26`, `1.25` |
| Java | `mcr.microsoft.com/devcontainers/java` | `21`, `17`, `11` |
| .NET | `mcr.microsoft.com/devcontainers/dotnet` | `10.0`, `9.0`, `8.0` |
| Ruby | `mcr.microsoft.com/devcontainers/ruby` | `3.4`, `3.3`, `3.2` |
| PHP | `mcr.microsoft.com/devcontainers/php` | `8.4`, `8.3` |
| C/C++ | `mcr.microsoft.com/devcontainers/cpp` | `bookworm`, `noble` |
| Kotlin | `mcr.microsoft.com/devcontainers/java` | `21`, `17` |
| Scala | `mcr.microsoft.com/devcontainers/java` | `21`, `17` |
| Swift | `swift` (Docker Hub) | `6.0`, `5.10` |
| Deno | `mcr.microsoft.com/devcontainers/typescript-node` + Deno feature | `22`, `20` |
| Universal | `mcr.microsoft.com/devcontainers/universal` | `2` |

Use the latest stable tag unless the project pins an older version.

```jsonc
{
  "name": "<Project Name>",
  "image": "mcr.microsoft.com/devcontainers/<language>:<tag>",
  "forwardPorts": [],
  "postCreateCommand": "<install command>",
  "customizations": {
    "vscode": {
      "extensions": [],
      "settings": {}
    }
  },
  "remoteUser": "vscode",
  "mounts": [
    "source=${localEnv:HOME}${localEnv:USERPROFILE}/.ssh,target=/home/vscode/.ssh,type=bind,readonly"
  ]
}
```

#### Strategy B: Custom Dockerfile

Create a `Dockerfile` in `.devcontainer/`:

```dockerfile
ARG VARIANT=<version>
FROM mcr.microsoft.com/devcontainers/<base-image>:${VARIANT}

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
       <system-dependencies> \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*
```

Then in `devcontainer.json`:

```jsonc
{
  "name": "<Project Name>",
  "build": {
    "dockerfile": "Dockerfile",
    "context": "..",
    "args": {
      "VARIANT": "<version>"
    }
  },
  "forwardPorts": [],
  "postCreateCommand": "<install command>",
  "customizations": {
    "vscode": {
      "extensions": [],
      "settings": {}
    }
  },
  "remoteUser": "vscode"
}
```

#### Strategy C: Docker Compose

Create `docker-compose.yml` in the project root (or `.devcontainer/`), and reference it from `devcontainer.json`.

`devcontainer.json`:

```jsonc
{
  "name": "<Project Name>",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "forwardPorts": [],
  "customizations": {
    "vscode": {
      "extensions": [],
      "settings": {}
    }
  },
  "remoteUser": "vscode"
}
```

Common `docker-compose.yml` services are in `templates/compose/` — pick the right services and merge them.

**Post-create command by language**:

| Language | Command |
|----------|---------|
| Python (pip) | `pip install -r requirements.txt` |
| Python (poetry) | `poetry install` |
| Node.js (npm) | `npm install` |
| Node.js (pnpm) | `pnpm install` |
| Node.js (yarn) | `yarn install` |
| Rust | `cargo build` |
| Go | `go mod download` |
| Java (maven) | `mvn dependency:resolve` |
| Java (gradle) | `gradle dependencies` |
| .NET | `dotnet restore` |
| Ruby | `bundle install` |
| PHP | `composer install` |
| Scala (sbt) | `sbt update` |
| Kotlin (gradle) | `./gradlew dependencies` |
| Swift | `swift package resolve` |
| Deno | `deno cache main.ts` |

**Forward ports by framework**:

| Framework | Default Port |
|-----------|-------------|
| React / Vite / Next.js | 3000 |
| FastAPI / Django | 8000 |
| Flask | 5000 |
| Go web | 8080 |
| Rust Actix | 8080 |
| Spring Boot | 8080 |
| .NET | 5000 |
| Ruby Rails | 3000 |
| PHP Laravel | 8000 |
| Kotlin (Spring Boot) | 8080 |
| Scala (Play) | 9000 |
| Swift (Vapor) | 8080 |
| Deno (Oak) | 8000 |

**Completion criterion**: `.devcontainer/devcontainer.json` exists with correct image/build config, extensions, and post-create command.

### Step 4: Add VS Code extensions

Look at project dependencies and add matching extensions:

| Detected tool | Extension |
|---------------|-----------|
| Python | `ms-python.python`, `ms-python.vscode-pylance` |
| TypeScript | `dbaeumer.vscode-eslint`, `esbenp.prettier-vscode` |
| Rust | `rust-lang.rust-analyzer`, `vadimcn.vscode-lldb` |
| Go | `golang.Go` |
| Java | `vscjava.vscode-java-pack` |
| .NET | `ms-dotnettools.csharp`, `ms-dotnettools.csdevkit` |
| Ruby | `rebornix.Ruby` |
| PHP | `bmewburn.vscode-intelephense-client` |
| Docker | `ms-azuretools.vscode-docker` |
| GitHub | `github.vscode-github-actions`, `github.vscode-pull-request-github` |
| Jupyter | `ms-toolsai.jupyter` |
| Tailwind CSS | `bradlc.vscode-tailwindcss` |
| Biome | `biomejs.biome` |
| Kotlin | `fwcd.kotlin`, `vscjava.vscode-gradle` |
| Scala | `scala-lang.scala`, `scalameta.metals` |
| Swift | `sswg.swift-lang`, `vadimcn.vscode-lldb` |
| Deno | `denoland.vscode-deno` |

Add `github.copilot` and `github.copilot-chat` if user consents.

**Completion criterion**: VS Code extensions list populated in devcontainer.json.

### Step 5: Add lifecycle hooks

Configure lifecycle hooks appropriately:

```jsonc
{
  "initializeCommand": "<host-side setup, e.g. git config>",
  "onCreateCommand": "pip install --upgrade pip || true",
  "postCreateCommand": "<install dependencies>",
  "postStartCommand": "<start dev server, optional>",
  "postAttachCommand": "echo 'Ready! Run npm run dev to start'"
}
```

Lifecycle script order:
1. `initializeCommand` — runs on the **host** before container creation
2. `onCreateCommand` — runs after container is created (no user secrets, good for caching)
3. `postCreateCommand` — runs after onCreate (has user secrets, good for `pip install` / `npm install`)
4. `postStartCommand` — runs every time the container starts
5. `postAttachCommand` — runs every time VS Code attaches

Use only the hooks the project needs. Most projects only need `postCreateCommand`.

**Completion criterion**: Lifecycle hooks set with correct commands.

### Step 6: Generate supporting files

#### `.dockerignore`

Write `.dockerignore` to the project root:

```dockerignore
.git
.gitignore
node_modules
vendor
.venv
venv
__pycache__
*.pyc
dist
build
.next
.env
.env.local
.env.*.local
.idea
.vscode
.DS_Store
*.log
coverage
.nyc_output
.pytest_cache
README.md
LICENSE
```

If one already exists, skip this step.

#### `.devcontainer/devcontainer-lock.json`

Run this command if features are used, to pin versions:

```bash
npx -y @devcontainers/cli upgrade --workspace-folder .
```

**Completion criterion**: `.dockerignore` exists (or was already there). Lockfile generated if features are used.

### Step 7: Security baseline

Verify these properties are set correctly:

- `remoteUser` is `vscode` (not root)
- Container runs without `privileged: true` unless Docker-in-Docker is required
- SSH keys are mounted read-only: `readonly` in mount options
- `.env` files are in `.dockerignore`
- No secrets baked into Dockerfile or devcontainer.json
- `capAdd` only includes what's needed (e.g., `SYS_PTRACE` for Rust/LLDB)

For Rust projects specifically, add these for debugger support:

```jsonc
"capAdd": ["SYS_PTRACE"],
"securityOpt": ["seccomp=unconfined"]
```

**Completion criterion**: Security checklist passed.

### Step 8: Generate CI workflow (optional)

If the project has a CI pipeline (GitHub Actions, GitLab CI, etc.), add a CI workflow that uses the devcontainer:

#### GitHub Actions

Create `.github/workflows/ci.yml` using the template at `templates/ci/devcontainer-ci.yml`:

```yaml
name: CI in DevContainer

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and run dev container
        uses: devcontainers/ci@v1
        with:
          runCmd: |
            <install-command>
            <build-command>
            <test-command>
```

Replace placeholders with the correct commands for the detected language.

**Benefits**: This ensures CI runs in exactly the same environment as local development, eliminating "works on my machine" gaps.

**Completion criterion**: CI workflow exists if the project has a CI pipeline. Otherwise, skip.

### Step 9: Verify

- [ ] `.devcontainer/devcontainer.json` is valid JSONC
- [ ] Dockerfile path (if used) is correct relative to context
- [ ] docker-compose.yml service name matches `"service"` in devcontainer.json
- [ ] `workspaceFolder` matches container path
- [ ] `postCreateCommand` won't fail (command exists in the image)
- [ ] All referenced VS Code extensions exist in marketplace
- [ ] Forward ports don't conflict
- [ ] `remoteUser` is non-root
- [ ] `.dockerignore` exists and covers build context
- [ ] Image tag exists on MCR (check format: `mcr.microsoft.com/devcontainers/<name>:<tag>`)
- [ ] Features use pinned versions (not `latest`)

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| `node_modules` from host overwrites container | Module not found errors | Add `"mounts": ["source=project-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume"]` or ensure `.dockerignore` excludes it |
| Container exits immediately | VS Code shows "Container started" then disconnects | Set `"overrideCommand": true` or `"shutdownAction": "none"` |
| Git auth fails inside container | `Permission denied (publickey)` | Mount SSH keys: `source=${localEnv:HOME}${localEnv:USERPROFILE}/.ssh,target=/home/vscode/.ssh,type=bind,readonly` |
| Bind mount permissions on Linux | Can't write files from container | Set `"remoteUser": "vscode"` and `"updateRemoteUserUID": true` |
| Port not accessible | Can't open localhost:3000 | Check `"forwardPorts"` includes the port, and app binds to `0.0.0.0` not `127.0.0.1` |
| Image not found | Build fails with manifest unknown | Verify image name and tag at `mcr.microsoft.com/devcontainers/<name>:<tag>` |
| Alpine image has glibc errors | Python/Node/.NET runtime errors | Use `-bookworm` or `-trixie` variant (Debian-based), not Alpine |
| Dockerfile changes not picked up | Old config still in use | Run "Dev Containers: Rebuild Container" — reopening is not enough |
| Docker Compose service name mismatch | Container can't find service | Ensure `"service"` in devcontainer.json matches a service name in docker-compose.yml |
| Features not installing | Feature options ignored | Feature changes require rebuild; pinned versions prevent surprise upgrades |

## Common Rationalizations

| Rationalization | Reality |
|----------------|---------|
| "I'll just write the Dockerfile manually" | You'll miss 5+ common gotchas this skill catches automatically. Takes 5 minutes with this skill vs 30+ minutes debugging manually. |
| "My project is too simple for a dev container" | Dev containers prevent "works on my machine" even for simple projects. A one-line image-only config takes 2 minutes. |
| "I'll add it later" | Later never comes. The first person who can't run your project will wish you had done it. |
| "Dev containers are just for VS Code" | They work with JetBrains, GitHub Codespaces, Gitpod, Coder, and the `devcontainer` CLI for CI. |
| "I don't need .dockerignore for dev" | Build context ships everything — node_modules, .git, env files. Can be 500MB+ instead of 2MB. |
| "The default image is fine" | The default (no config) Codespaces image is 2GB+ with everything installed. A language-specific image is faster and smaller. |

## Red Flags

- Using `latest` tag for base image (use specific version tag)
- Running as root (`containerUser: "root"` or no `remoteUser` set)
- No `.dockerignore` (bloated build context)
- Secrets baked into Dockerfile or devcontainer.json
- Privileged mode without Docker-in-Docker requirement
- Bind-mounting entire project without excluding `node_modules`/`.venv`
- No `postCreateCommand` set (dependencies won't be installed)
- Not detecting the correct package manager (npm vs pnpm vs yarn)
- `depends_on` without `condition: service_healthy` for databases
- Missing health checks on dependency services
- Forwarding port that the app doesn't actually listen on
- Using Alpine image without verifying glibc compatibility

## Verification

After configuration is generated:

- [ ] Project's README can be updated with "Open in Codespace" badge
- [ ] A fresh `git clone` + "Reopen in Container" works end-to-end
- [ ] `npm test` / `cargo test` / `go test` / equivalent passes inside the container
- [ ] All forward ports are accessible from host browser
- [ ] Database migrations run inside the container
- [ ] Hot reload works (file change triggers rebuild)
- [ ] `git push` works from inside the container (SSH auth)
- [ ] Container rebuilds successfully after `docker system prune`
