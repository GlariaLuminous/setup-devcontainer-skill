# Changelog

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
