[![MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

# setup-devcontainer-skill

你项目里缺个 `.devcontainer` 目录对吧。这个 skill 能帮你搞定。

它看你项目用什么语言、什么框架、用什么包管理器、用不用数据库，然后生成对应的配置文件。

## 好处

- 不用记 `mcr.microsoft.com/devcontainers/xxx` 那些镜像名
- 不用纠结 `postCreateCommand` 到底写什么
- 不会忘记加 `.dockerignore`（然后 build context 从 2MB 变成 500MB）
- 默认非 root 用户，不需要事后补安全措施
- node_modules 不会和宿主机打架

## 支持的语言

| 语言 | 镜像策略 | 需自定义 Dockerfile 的场景 |
|------|---------|---------------------------|
| Python | 预构建镜像 | 需要系统级 C 库、OpenCV、TensorFlow 等 |
| Node.js / TypeScript | 预构建镜像 | 需要 native 模块编译 |
| Rust | 预构建镜像 | 通常不需要，镜像自带 LLDB |
| Go | 预构建镜像 | 通常不需要 |
| Java | 预构建镜像 | 需要特定 JDK 版本以外的系统工具 |
| .NET / C# | 预构建镜像 | 通常不需要 |
| Ruby | 预构建镜像 | 需要系统级 gem 依赖 |
| PHP | 预构建镜像 | 需要额外扩展（exif、gd 等） |
| C/C++ | 预构建镜像 | 如果需要特定版本的编译工具链 |

检测到项目用了 PostgreSQL、MySQL、Redis 或 MongoDB 时，会自动生成 docker-compose.yml 带上这些服务。

## 用法

```bash
cd 你的项目目录
opencode
> 给我的项目配一个 dev container
```

skill 会自动检测项目结构，问你要不要加数据库，然后生成文件。

## 生成的文件

```
.devcontainer/
├── devcontainer.json     # 主要配置
├── Dockerfile            # 只有需要自定义镜像时才生成
└── docker-compose.yml    # 只有用到数据库时才生成
.dockerignore             # 防止构建上下文过大
```

参考模板在 `templates/` 目录下，每种语言一个独立的 jsonc 文件。

## 和 Docker / Microsoft 的关系

这个项目不是它们官方的。"DevContainer" 是 [containers.dev](https://containers.dev) 上的开放规范。

## License

MIT
