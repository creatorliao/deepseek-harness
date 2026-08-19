---
name: overlay-upstream-sync
description: >
  同步上游、吃官方更新、merge upstream、合官方、fork sync。
  在 deepseek-harness 上把 upstream/master 合进 dev-creator 叠加层时使用。漏一步会丢挂钩。
---

# 叠加层：同步上游

**指导，不是完整清单。** 未拍板「合跟踪枝 + L3」则先写方案，等人一句话再 `merge`。

## 必读

- 根 [AGENTS.md](../../../AGENTS.md)「创作者叠加」
- [20260820-03](../../../dev-docs/02-Areas/20260820-03-最佳实践_上游叠加与个性化隔离.md) 同步节
- [20260820-04](../../../dev-docs/02-Areas/20260820-04-参考_叠加层L2枢纽L3清单.md)

## 门闩

工作区干净。主题夹四件已归档。T0 三颗 hash 是**执行日**的：`dev-creator`、`upstream/master`、`merge-base`。

## T0～T5

1. T0：`git fetch upstream` 与 `origin`；记下三颗 hash。
2. T1：从干净 `dev-creator` 开 `feat/R{日期}-*-sync-upstream`；`git merge upstream/master`。搞砸了 `merge --abort`。不 rebase 本仓历史，不用 `reset --hard`。
3. T2：先清 lock / 生成物 / 版本。lock 用 pnpm 重生。
4. T3：枢纽以上游正文为底，按清单缝挂钩。L2 被删则 `git checkout --ours -- <path>`。根 `AGENTS.md` 缝回中文「创作者叠加」短节。禁止整文件 `--theirs`/`--ours`。
5. T4：`git merge-base --is-ancestor upstream/master HEAD`；清单回归；被对撞的官方窄门。不要默认全量。
6. T5：更新主题夹停点。未经「合回 dev-creator」不合回。未经「推 origin」不 push。绝不推官方仓。

## 禁止

cherry-pick 冒充对齐；枢纽整文件取一边；`git add -A`；冲突块里手编 lock。
