## 贡献指南

PR 和 issue 都欢迎。

### 报告问题

开 issue 前先搜一下有没有人报过。写清楚：
- 你用了什么语言/框架
- 生成的配置文件内容（贴关键部分）
- 实际发生了什么 vs 你期望什么

### 提交 PR

1. fork 这个仓库
2. 建一个分支：`git checkout -b fix/xxx` 或 `feat/xxx`
3. 改完后提交 PR
4. PR 描述里写清楚改了什么、为什么改

### 本地测试

提交前运行前两层，都不需要 Docker：

```bash
bash tests/validate-templates.sh   # 46 条模板断言
bash tests/validate-fixtures.sh    # 4 个 fixture × 6 条 + 1
```

第三层需要 Docker 和 Dev Container CLI，跑的是真 build：

```bash
npm install -g @devcontainers/cli
bash tests/ci-run-fixture.sh tests/fixtures/python-pip
```

CI 会把四个 fixture 全跑一遍，本地只跑你改动相关的那一个就够。

### 新增语言模板

1. 在 `templates/` 下加 `<lang>.jsonc`
2. 同步 README 的「支持的语言与数据库」表
3. 确保模板使用非 root 用户、没有默认挂载宿主机 SSH 私钥、不残留 `<install-command>` 这类占位符
4. `remoteUser` 必须是该镜像里真实存在的用户：大多数 `devcontainers/*` 镜像是 `vscode`，但 `typescript-node`/`javascript-node` 是 `node`、`universal` 是 `codespace`。写错的话容器起不来，报 `unable to find user ...`。表在 `tests/image-user.mjs`
5. 如果这个语言有独有的坑（比如 Swift 官方镜像没有 `vscode` 用户），在 README 的「内置的坑位清单」里补一条

### 新增 fixture

fixture 是「一个能被真 build 起来的最小项目」，用来证明某个模板组合真的能工作。加一个：

1. 建 `tests/fixtures/<name>/`，放一个能独立跑起来的最小项目
2. 写 `.devcontainer/devcontainer.json`（compose 策略的话连同 Dockerfile 和 docker-compose.yml 一起）
3. 写 `verify.sh`——**在容器内运行**，检查这个配置该有的效果：版本对不对、依赖装没装、服务连不连得上、是不是非 root。用仓库统一的 `check()` 写法，失败时 exit 1
4. 把 fixture 名字加进 `.github/workflows/validate.yml` 的 `build-fixtures` matrix

`bash tests/validate-fixtures.sh` 会自动发现新目录，不需要注册。
