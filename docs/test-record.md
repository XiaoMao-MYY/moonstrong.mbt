# 测试记录

本文件记录**实际执行过的命令与真实输出**。所有数字均来自本机执行结果，未经修改。

## 1. 环境

| 项目 | 值 |
| --- | --- |
| 操作系统 | Windows（win32） |
| moon | `moon 0.1.20260904 (94521db 2026-09-04)` |
| 启用的特性开关 | `rr_moon_mod`, `rr_moon_pkg` |
| git | `2.55.0.windows.3` |
| 第三方依赖 | 无（仅 MoonBit 标准库） |

## 2. 执行结果

### 2.1 类型检查

```
$ moon check --deny-warn
Finished. moon: ran 4 tasks, now up to date
```

0 error、0 warning。

### 2.2 构建

```
$ moon build
Finished. moon: no work to do
```

### 2.3 测试

```
$ moon test --deny-warn
Total tests: 58, passed: 58, failed: 0.
```

58 条全部通过。

### 2.4 格式检查

```
$ moon fmt --check
Finished. moon: ran 16 tasks, now up to date
```

> 注：`moon fmt` 内部调用 `git` 生成 diff。若 PATH 中没有 git，会输出
> `Error: program not found`（7 行，每包一行）并以 `failed when formatting project`
> 结束。这不是格式问题，补上 git 后即通过。

### 2.5 接口文件生成

```
$ moon info
Finished. moon: ran 3 tasks, now up to date
```

`src/pkg.generated.mbti` 与源码保持同步，公开类型均以 `pub(all)` 声明。

## 3. 可运行示例的实际输出

### 3.1 `moon run examples/quickstart`

```
== 示例：一次训练的量化和一份饮食规划 ==

[训练] 深蹲 100kg：5 次 x2 组 + 8 次力竭 x1 组
   反推 1RM：122.5kg（估算置信度：0.75）
   总容量负荷：1800kg
   有效次数：11 次
   平均强度：80.6% 1RM
   总 INOL（疲劳指标，>2 较难恢复）：0.9

[身体] 男 80kg / 180cm / 30 岁，每周训练 3-5 次
   BMI：24.7
   估算体脂率：20.3%
   FFMI（归一化）：19.7
   TDEE：2759 kcal/天

[营养] 增肌目标（热量盈余 400 kcal）
   目标热量：3159 kcal
   蛋白质：144 g
   脂肪：87.75 g
   碳水：448.3 g

[下一步] 依据本次表现给出建议
   容量调整系数：1
   目标 5 次 RPE 8（留 2 次余量）：100kg
   按 RIR 反推该组相当于：RPE 8
```

**结果校验**：

- TDEE 2759 —— Mifflin-St Jeor：`10×80 + 6.25×180 − 5×30 + 5 = 1780`，
  `1780 × 1.55（Moderate）= 2759`，与手算一致。
- 容量负荷 1800 —— `100×5 + 100×5 + 100×8 = 1800`，与手算一致。
- 1RM 122.5 —— 共识值 124.08 经 `round_to_plate(…, 2.5)` 取整到 122.5，符合预期。
- 热量盈余 400 —— 增肌目标的固定盈余值，与宏量营养素分配一致。

### 3.2 `moon run cmd/main`

```
[1] 1RM 估算
    输入：100kg x 5 次
    共识 1RM：113.92018718311292kg
    置信度：0.9
    训练最大值 TM(90%)：102.52816846480162kg

[2] 5/3/1 第 1 周主项处方（基于 TM）
    第 1 组：65kg x 5 次
    第 2 组：75kg x 5 次
    第 3 组：85kg x 5 次（AMRAP）

[3] RPE 处方：完成 5 次且保留 1 次余量（RPE 9）
    建议重量：85.4401403873347kg

[4] 自适应建议
    训练状态：与基线持平，按计划推进
    减载：无需减载，按计划推进

[5] 若 AMRAP 完成 7 次，下一周期训练最大值
    新 TM：107.52816846480162kg
```

**结果校验**：5/3/1 第 1 周为 65% / 75% / 85% × 5 次，TM = 102.53，
`102.53 × 0.65 = 66.6 → 65`、`×0.75 = 76.9 → 75`、`×0.85 = 87.2 → 85`
（处方内部按 5kg 取整），与 5/3/1 公布的第 1 周结构一致。

## 4. 工具链问题定位记录

### 4.1 现象

在其他包中构造本库枚举值时，编译器报：

```
Error: [4036]
    Cannot create values of the read-only type: Male.
```

### 4.2 排查过程与结论

| 步骤 | 操作 | 结果 |
| --- | --- | --- |
| 1 | 换构造写法（`@pkg.X`、`@pkg.Type::X`、加/去别名） | 均失败，排除语法问题 |
| 2 | 移除 `derive(Debug)` | 仍失败 |
| 3 | `moon clean` 清缓存后重建 | 仍失败，排除缓存问题 |
| 4 | 移走 `pkg.generated.mbti` | 仍失败，排除接口文件问题 |
| 5 | 在同模块内新建最小包 `tiny` 做对照 | `tiny` 也失败 → 排除本库特定问题 |
| 6 | 新建独立最小模块，单枚举对照 | 同样失败 → 确认是语言/工具链层面的语义 |
| 7 | 查阅 MoonBit 官方文档关于可见性的章节 | **定位根因** |

**根因**：MoonBit 当前版本的可见性语义中，默认 `pub` 为**只读可见性**——
外部包可以解构、可以传参，但**不能构造**。要让外部包能构造，必须显式声明 `pub(all)`。

**修复**：本库全部公开类型（`enum` / `struct` / `suberror`）改为 `pub(all)`。
修复后 `moon run examples/quickstart` 正常通过，该示例正是以跨包构造的方式使用库的。

### 4.3 过程中的一次错误判断（如实记录）

排查第 2 步时，曾把现象误判为「`derive(Debug)` 导致类型只读」，并据此删除了全部
`Debug` 派生。事后证明这是错的：`Debug` 与构造能力无关。误判的原因是把
`tail` 截断后的输出当成了完整输出——实际上 `unused_constructor` 警告恰恰说明
构造失败了。已恢复 `Debug` 派生，并把结论记录在 `THIRD_PARTY.md` 第四节。

## 5. 未覆盖 / 待补充

- 尚未做属性测试（property-based test），如"任意合法输入下 e1RM 单调性"。
- 尚未在 Linux / macOS 上跑过 CI（GitHub Actions 配置已就绪，待建仓后首次运行验证）。
- 尚未做跨后端（js / native）的数值一致性实测，仅有"仅用四则运算"的设计保证。
