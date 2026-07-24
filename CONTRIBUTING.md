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

提交前运行：

```bash
bash tests/validate-templates.sh
```

新增语言模板时，还要同步 README 的支持列表，并确保模板使用非 root 用户、没有默认挂载宿主机 SSH 私钥。
