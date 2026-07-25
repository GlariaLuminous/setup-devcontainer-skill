# Changelog

## [v1.1.1] - 2026-07-24

### Fixed
- Swift 模板：官方 `swift:6.0` 镜像缺少 `vscode` 用户，增加配套 `Swift.Dockerfile` 创建用户
- Docker Compose 模板：删除了服务名中的变量插值 `${WITH_REDIS:-redis}`
- Deno 模板：`postCreateCommand` 从 `deno cache main.ts` 改为 `deno install`
- CI 模板：移除嵌死的 `npm ci / npm run build / npm test` 命令，改为 ` <ci-command>` 占位符
- SKILL.md：`devcontainers/ci` 从 `@v1` 修正为 `@v0.3`

### Added
- 模板静态验证脚本，自动检查模板语法和已知反模式
- GitHub Actions 工作流，每次推送自动运行验证

### Changed
- README：增加 Kotlin、Scala、Swift、Deno 四种语言到支持矩阵
- README：增加安装和升级说明

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
