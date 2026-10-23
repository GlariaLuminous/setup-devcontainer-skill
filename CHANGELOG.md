# Changelog

## [Unreleased]

### Added
- `tests/fixtures/` 四个能被真 build 的最小项目：`python-pip`、`node-npm`、`go-mod`（Strategy A）与 `node-postgres`（Strategy C）
- `tests/validate-fixtures.sh`：不需要 Docker 的 fixture 静态校验，25 条断言，覆盖非 root、无悬空 build 引用、不挂宿主机 `.ssh`
- `tests/check-fixture-refs.mjs`：静态解析 compose 的 build 引用并逐个 `stat`，拦下「Strategy C 忘了 Dockerfile」这类只有 build 时才暴露的错误
- `tests/ci-run-fixture.sh`：`devcontainer up` → `devcontainer exec verify.sh` 的真实 build 入口
- CI 新增 `build-fixtures` job，用 matrix 并发跑四个 fixture 的真 build
- 仓库自身的 `.devcontainer/`（dogfood）：容器起来先跑 `bash tests/validate-templates.sh`，生成的配置坏了会立刻暴露
- `tests/parse-jsonc.mjs`：带注释的 JSONC 解析器，模板里的说明注释不再让 JSON 校验失败
- `tests/image-user.mjs`：记录各 `devcontainers/*` 镜像实际自带的非 root 用户，供模板与 fixture 两处校验共用
- `tests/check-template-user.mjs`：13 个模板的 `remoteUser` 必须与该镜像真实用户一致

### Fixed
- `templates/node.jsonc`、`templates/deno.jsonc` 的 `remoteUser` 从 `vscode` 改为 `node`——`typescript-node` 镜像里没有 `vscode` 用户，容器会在启动阶段直接失败：`unable to find user vscode: no matching entries in passwd file`
- `tests/fixtures/node-npm`、`tests/fixtures/node-postgres` 同样改为 `remoteUser: node`，并给两个 fixture 加上真实依赖 `ms`，让 `npm ci` 真的产出 `node_modules`（此前零依赖项目跑 `npm ci` 什么都不装，校验形同虚设）
- `tests/fixtures/go-mod` 的 `go.mod` 从 `go 1.26` 降为 `go 1.23`，避免本地没有 1.26 时触发工具链下载；容器内的 1.26 由 `verify.sh` 单独断言
- CI 的 build 步骤设置 `BUILDX_BAKE_ENTITLEMENTS_FS=0`，绕开 devcontainers/cli#1320（Compose ≥ v2.39 默认走 bake，Buildx ≥ v0.37.2 拒绝 context 之外的 Dockerfile）
- `templates/docker-compose.yml` 补上 `command: sleep infinity`，否则 app 服务进程结束后容器立即退出
- SKILL.md Strategy C 段落明确要求同时生成 `.devcontainer/Dockerfile`——compose 的 `app` 服务从它 build，缺了 `docker compose build` 直接失败

### Changed
- README 重写：痛点表、架构图、三策略决策图、三层质量保障说明
- CONTRIBUTING 补充 fixture 的编写与注册方式
- SKILL.md 增加 `remoteUser` 与镜像的对应表、Strategy C 的 bake 报错排查行；Step 3 的示例不再硬编码 `vscode`

## [v1.2.1] - 2026-07-25

### Fixed
- Deno 模板改用实际存在的 `devcontainers-extra/features/deno:1`，并通过 `deno install` 安装项目依赖
- Scala 模板改用 `devcontainers-extra/features/sbt-sdkman:2`，不再传递 Java Feature 不支持的 `installSbt` 选项
- Dev Container CI 模板改用实际存在的 `devcontainers/ci@v0.3`，并移除固定的 npm 命令
- Java、Kotlin 和 Swift 模板改为在生成时选择安装命令，不再假设项目使用特定构建工具
- Shell 验证脚本固定使用 LF 换行，可在 Windows 工作区的 Bash 中执行

### Added
- 回归检查覆盖 Deno、sbt Feature、CI Action 版本和语言安装命令占位符
- CI 使用 `docker compose config` 验证三个 Compose 模板
- README 增加手动安装和更新步骤

## [v1.2.0] - 2026-07-25

### Fixed
- 修正 Docker Compose 路径和条件依赖写法
- Swift 模板增加非 root 开发用户
- 移除默认 SSH 私钥目录挂载

### Added
- C/C++ 模板
- 模板静态验证脚本和 GitHub Actions 工作流

### Changed
- README 支持矩阵更新为 13 种语言

## [v1.1.1] - 2026-07-24

此版本与 v1.1.0 指向同一提交，用于补发 GitHub Release，不包含代码变化。

## [v1.1.0] - 2026-07-24

### Added
- 四种新语言模板：Kotlin、Scala、Swift、Deno
- 两种数据库 Compose 模板：MySQL 8.4、MongoDB 8
- CI 集成：devcontainer-ci.yml 工作流模板

## [v1.0.0] - 2026-07-24

### Added
- 初始版本，支持 9 种语言
- docker-compose 模板（PostgreSQL + Redis）
- 三种策略：Image-only / Custom Dockerfile / Docker Compose
