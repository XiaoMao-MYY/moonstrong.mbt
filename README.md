# moonstrong

**力量训练智能编程引擎** —— 用 MoonBit 写的、零依赖的力量训练处方计算库。

它解决的是一个很具体的问题：**把"今天练多重、练几组、该不该加重量、该不该减载"
这件目前靠教练经验和 Excel 表格完成的事，变成一组可调用、可测试、可复现的纯函数。**

---

## 它能干什么 / 不能干什么

### 能干

| 能力 | 说明 |
| --- | --- |
| 1RM 估算 | 4 种公式（Epley / Brzycki / O'Conner / Lander）+ 按次数加权的**共识值**，避免单一公式的系统偏差 |
| RPE / RIR 处方 | 主观强度 ↔ 百分比 ↔ 保留次数互转，支持"做 5 次留 2 次余量该用多重"这类真实问法 |
| 训练容量量化 | 容量负荷、有效次数（stimulating reps）、INOL 疲劳指数、平均强度 |
| 身体成分与能量 | BMI、体脂率（Deurenberg）、FFMI、BMR（3 种公式）、TDEE、宏量营养素分配 |
| 周期化计划生成 | 5/3/1 完整周期、StrongLifts 5×5、DUP（重/中/轻日） |
| 自适应调整 | 状态判定、平台期检测、减载建议、训练最大值（TM）推进 |

### 不能干（明确边界）

- **不做医疗/康复建议**。所有输出是训练学意义上的估算，不构成医学意见；伤病、慢病人群应遵医嘱。
- **不采集、不存储、不上传任何个人数据**。库是纯函数，输入输出都在调用方手里。
- **不做心率/HRV/伤病风险评估**。这是刻意划定的边界：生态中已有侧重健康监测的项目，本项目只做**训练处方计算**。
- **不做 UI / 不连设备**。它是库，不是 App。
- **不保证估算值与个体差异一致**。经验公式对个体有系统性误差，详见下方「已知局限」。

---

## 安装

```bash
moon add XiaoMao-MYY/moonstrong
```

在 `moon.pkg` 中引入：

```moonbit
import {
  "XiaoMao-MYY/moonstrong/src" @strong,
}
```

> 模块所有者为 XiaoMao-MYY。

---

## 快速开始

```moonbit
fn main raise {
  // 1) 100kg 做 8 次，反推 1RM（多公式加权共识）
  let one_rm = @strong.consensus_1rm(100.0, 8)

  // 2) 取 90% 作为训练最大值
  let tm = @strong.training_max(one_rm, 0.9)

  // 3) 生成 5/3/1 第 1 周主项处方
  for set in @strong.five_three_one_sets(tm, 1) {
    println("\{set.weight}kg x \{set.reps}")
  }

  // 4) 做 5 次且希望留 2 次余量（RPE 8），该用多重？
  println(@strong.weight_at_rir(one_rm, 5, 2))
}
```

完整可运行示例见 [`examples/quickstart`](./examples/quickstart)：

```bash
moon run examples/quickstart
```

命令行演示（完整链路：1RM → 5/3/1 → RPE → 自适应）：

```bash
moon run cmd/main
```

### 一个真实场景

> 我今天深蹲 100kg 做了 5 次 ×2 组、最后一组力竭做了 8 次。
> 这次训练量够不够？下次该加重量吗？我 80kg，想增肌，每天该吃多少？

这三问分别对应 `total_volume` / `total_stimulating_reps` / `total_inol`、
`next_training_max` + `detect_plateau`、`tdee` + `macro_plan`。
`examples/quickstart` 完整跑通了这个场景，实测输出见 `docs/test-record.md`。

---

## API 一览

完整签名以 `moon info` 生成的 `src/pkg.generated.mbti` 为准。按下述分组：

**1RM 与强度**
`estimate_1rm` · `estimate_1rm_all` · `consensus_1rm` · `formula_name` ·
`formula_valid_at` · `formula_weight` · `estimate_confidence` ·
`weight_for_reps` · `percent_of_1rm` · `training_max` · `relative_strength`

**RPE / RIR**
`pct_from_rpe` · `rpe_from_pct` · `rir_from_rpe` · `rpe_from_rir` ·
`weight_at_rir` · `weight_at_rpe` · `e1rm_from_set`

**容量量化**
`set_volume` · `total_volume` · `stimulating_reps` · `total_stimulating_reps` ·
`inol` · `total_inol` · `average_intensity` · `training_density`

**身体成分与营养**
`bmi` · `body_fat_deurenberg` · `ffmi` · `activity_factor` · `bmr` · `tdee` · `macro_plan`

**周期化处方**
`five_three_one_sets` · `five_three_one_cycle` · `stronglifts_5x5` · `dup_session` · `round_to_plate`

**自适应调整**
`performance_status` · `next_training_max` · `detect_plateau` · `suggest_deload` ·
`autoregulate_load` · `volume_adjustment`

**单位与目录**
`kg_to_lb` · `lb_to_kg` · `to_kg` · `from_kg` · `lift_name` · `make_set` · `custom_lift` ·
`all_*`（`all_lifts` / `all_sexes` / `all_goals` / `all_onerm_formulas` / …）

### 错误处理

所有会校验入参的函数均返回 `raise InvalidInput`，错误变体包括
`NonPositiveWeight` / `InvalidReps` / `InvalidPercentage` / `InvalidSets` /
`InvalidRpe` / `InvalidRir` / `InvalidBodyMetric`。

```moonbit
try {
  let x = @strong.estimate_1rm(@strong.Epley, -5.0, 5)
  ignore(x)
} catch {
  InvalidInput::NonPositiveWeight(w) => println("重量必须为正，收到 \{w}")
  _ => println("其他非法输入")
}
```

### 单位约定（重要）

- **重量一律为公斤（kg）**，用 `to_kg` / `from_kg` 做单位换算。
- **百分比一律为 0..1 的小数**，不是 0..100。`0.85` 表示 85% 1RM。
- 展示层负责把小数转成百分比、把公斤取整到可用杠铃片（见 `round_to_plate`）。

---

## 已知局限

1. **1RM 估算对高次数不可靠**：超过 10 次后各公式分歧显著放大，`estimate_confidence`
   会相应下调到 0.75 / 0.5 / 0.3，调用方应据此提示用户。
2. **Brzycki / Lander 有定义域**：分别在 `reps ≥ 37` 与 `reps ≥ 38` 时无意义，
   `estimate_1rm_all` 会自动剔除越界公式。
3. **RPE 是主观量表**：跨人不可比，同一人在不同疲劳状态下也会漂移。本库只做换算，
   不替代实际训练反馈。
4. **体脂率用 Deurenberg 公式（基于 BMI）**：对肌肉量显著高于常人的力量训练者
   **会高估体脂**，这是该公式的已知系统性偏差。有实测体脂时请直接传入。
5. **营养模块是估算起点**，不是饮食处方：个体差异大，需按体重变化回测调整。
6. **不含伤病与医学判断**，也不处理训练动作技术细节。

---

## 开发

```bash
moon check --deny-warn   # 类型检查，0 warning
moon build               # 构建
moon test --deny-warn    # 58 条测试
moon fmt --check         # 格式检查（依赖 git 生成 diff）
moon info                # 重新生成公开接口文件
```

`moon fmt` 依赖 `git` 生成 diff，PATH 中必须有 git，否则会报 `Error: program not found`。

### 目录结构

```
src/            核心库（零第三方依赖）
  types.mbt     公开类型与单位换算
  onerm.mbt     1RM 估算
  rpe.mbt       RPE / RIR
  volume.mbt    容量量化
  body.mbt      身体成分与营养
  program.mbt   周期化处方
  adapt.mbt     自适应调整
  catalog.mbt   枚举取值目录
  *_wbtest.mbt  白盒测试
cmd/main        命令行演示
examples/       可运行示例
docs/           技术设计、测试记录、发布清单、项目申报书
```

### 一个工具链注意事项

MoonBit 当前版本中，`pub` 声明的类型在其他包里**只能解构、不能构造**
（编译器报 `4036 Cannot create values of the read-only type`）。
要让使用方能构造枚举与结构体，必须写 `pub(all)`。本库全部公开类型均已使用 `pub(all)`，
并由 `examples/quickstart` 以跨包构造的方式验证。详见 `THIRD_PARTY.md` 第四节。

---

## CI

GitHub Actions 在每次 push / PR 上执行：
`moon check --deny-warn` → `moon build` → `moon test --deny-warn` →
`moon fmt --check` → `moon info`（并检查接口文件是否与提交内容一致）。

配置见 [`.github/workflows/ci.yml`](./.github/workflows/ci.yml)。

---

## 发布

发布到 mooncakes.io 需由维护者本人执行（不代持凭据）：

```bash
moon login
moon publish --frozen
```

**发布状态以实际执行结果为准**，未发布时本文件不会声称已发布。

---

## 许可

Apache-2.0，见 [LICENSE](./LICENSE)。
公式与方法学来源见 [THIRD_PARTY.md](./THIRD_PARTY.md)，AI 使用情况见 [AI_USAGE.md](./AI_USAGE.md)。
