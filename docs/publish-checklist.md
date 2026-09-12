# 发布检查清单

## A. 发布前自检（本地，可自动化）

按顺序执行，全部通过才进入 B 部分。

```bash
moon check --deny-warn    # 期望：Finished，0 warning
moon build                # 期望：Finished
moon test --deny-warn     # 期望：Total tests: 58, passed: 58, failed: 0.
moon fmt --check          # 期望：Finished（需 PATH 中有 git）
moon info                 # 期望：Finished，且 *.mbti 无 diff
moon run examples/quickstart
moon run cmd/main
```

## B. 元数据核对（人工）

- [ ] `moon.mod` 的 `name` 与**真实 GitHub 用户名**一致（当前为占位值 `XiaoMao-MYY/moonstrong`）
- [ ] `moon.mod` 的 `repository` 指向真实且**公开**的仓库地址
- [ ] `moon.mod` 的 `version` 符合语义化版本，且与 `CHANGELOG.md` 一致
- [ ] `moon.mod` 的 `license` = `Apache-2.0`，与根目录 `LICENSE` 一致
- [ ] `moon.mod` 的 `readme` 指向存在的文件
- [ ] `description` / `keywords` 准确描述项目
- [ ] `README.md` 中的安装命令与模块名一致
- [ ] `src/pkg.generated.mbti` 已提交且与源码同步

## C. 合规与来源（人工）

- [ ] `LICENSE` 为完整 Apache-2.0 文本，版权行已填写
- [ ] `THIRD_PARTY.md` 已列出全部公式来源、方法学来源与依赖
- [ ] `AI_USAGE.md` 已如实说明 AI 参与范围与凭据归属
- [ ] 无任何来源不明的代码；移植代码（若有）已标注来源

## D. 仓库状态（人工）

- [ ] GitHub 仓库已创建且为 **public**
- [ ] 默认分支明确（建议 `main`）
- [ ] 默认分支上的最新提交包含全部交付内容
- [ ] 未改写历史；每个提交对应一个有意义的改动
- [ ] `.gitignore` 已排除 `_build/`
- [ ] CI 首次运行通过（含 `moon info` 一致性检查）

## E. 发布执行（维护者本人，需真实凭据）

```bash
moon login                 # 浏览器完成登录
moon package --list        # 可选：确认待发布内容
moon publish --frozen      # --frozen 确保发布内容与仓库一致
```

- [ ] `moon publish --frozen` 实际执行成功
- [ ] 记录真实的 mooncakes.io 页面链接（**未实际发布前不得声称已发布**）
- [ ] 发布后回填本清单与 README 的发布状态

## F. 报名材料（人工）

- [ ] 项目名称、仓库链接、一句话定位
- [ ] 赛道：新项目赛道
- [ ] 一页项目申报书（见 `docs/project-brief.md`）
- [ ] 推荐人字段按官方要求填写
- [ ] 在截止时间（9 月 24 日）前提交

## 当前状态

| 项 | 状态 |
| --- | --- |
| A 部分（本地自检） | ✅ 全部通过（详见 `docs/test-record.md`） |
| B 部分（元数据） | ✅ 模块名与仓库地址已确认为 `XiaoMao-MYY/moonstrong` |
| C 部分（合规） | ✅ 已完成 |
| D 部分（仓库） | ✅ 已完成：public 仓 `https://github.com/XiaoMao-MYY/moonstrong.mbt` 已建，`main` 已推送（15 次提交），CI 首次运行通过（Linux，58/58 测试） |
| E 部分（发布） | ⬜ 未开始（需 mooncakes.io 登录，由维护者本人执行） |
| F 部分（报名） | ⬜ 申报书已生成（`docs/项目申报书.md`，含联系方式，未推送公开仓库） |
