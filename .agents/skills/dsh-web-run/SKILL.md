---
name: dsh-web-run
description: >
  把本仓库 DeepSeek Harness 源码网页跑起来：理解启动/重启/开浏览器意图，
  然后只执行 packages/creator/dsh-web.sh（先等端口就绪再打开浏览器）。
  触发：把这个网站运行起来、把网页跑起来、启动网页、启动 web、
  打开 dsh web、跑 web UI、重新启动网页、重启 3080、dsh-web-run。
  不适用于写教程、合上游、改 agent-loop、或只讨论 API Key 原理。
---

# 跑本仓网页

接到「把网站运行起来」时先读完本文，再跑脚本。意图细分见 [references/intent.md](references/intent.md)。

## 每次

1. **认意图**（只选一行，见 intent 表）：启动 / 重启 / 保留环境 Key / 换端口。未点名则：启动、unset Key、端口 3080。
2. **只跑这一份脚本**，工作目录是仓库根：

```sh
bash packages/creator/dsh-web.sh
```

需要时在同一条命令前加环境变量，例如：

```sh
DSH_WEB_RESTART=1 bash packages/creator/dsh-web.sh
DSH_WEB_KEEP_ENV_KEY=1 bash packages/creator/dsh-web.sh
DSH_WEB_PORT=3081 bash packages/creator/dsh-web.sh
```

3. **告诉用户地址** `http://127.0.0.1:<端口>`，以及脚本是「已在听只开浏览器」还是「新起了进程」。
4. 不要打印 API Key、不要读 `.bashrc` / `.credentials.yaml` 的值。

## 约束

- 不要手写 `pnpm dsh web`、不要另开一套启动命令。脚本负责 `--no-open`、等待、开浏览器。
- 未经用户点名不要跑 `pnpm run build` / `typecheck`。脚本若报 `frontend dist not built`，把原句转述并请用户点名再构建。
- 不要为了启动去改官方包或 `agent-loop`。
- 写教程走 `deepseek-harness-learner`，不要本技能落盘学堂课。
- 本技能只改 `.agents/skills/dsh-web-run/`；脚本只改 `packages/creator/dsh-web.sh`。

## 不做

- 把服务绑到 `0.0.0.0` 或公网。
- 在对话里粘贴密钥。
- 默认保留进程里的 `DEEPSEEK_API_KEY`（模型页会只读）；用户明确说要用环境钥匙时才设 `DSH_WEB_KEEP_ENV_KEY=1`。
