# 第三方来源说明

本文件如实记录本项目实现过程中参考或借鉴的外部来源。**本项目不包含任何从其他
开源项目复制而来的源代码**，以下均为公开领域的公式、常数与方法学参考，实现由本项目
作者独立编写。

## 一、引用的经验公式与常数（公开知识，非代码复制）

| 公式 / 模型 | 用途 | 公开来源 |
| --- | --- | --- |
| Epley 1RM：`1RM = w × (1 + r/30)` | 1RM 估算 | 公开的力量训练文献， widely published |
| Brzycki 1RM：`1RM = w × 36 / (37 − r)` | 1RM 估算 | 同上，定义域 `r < 37` |
| O'Conner 1RM：`1RM = w × (1 + r/40)` | 1RM 估算 | 同上 |
| Lander 1RM：`1RM = 100w / (101.3 − 2.67123r)` | 1RM 估算 | 同上，定义域 `r < 38` |
| RPE ↔ RIR 换算表 | 主观强度量化 | 基于 RPE（Borg CR10 变体）在力量训练中的通行用法 |
| INOL = 组数 × 次数 / (100 − 强度%) | 疲劳量化 | 力量训练社区通行的 Intensity × Number Of Lifts 指标 |
| Mifflin-St Jeor | BMR | Mifflin et al., 1990，公开学术公式 |
| Harris-Benedict | BMR | Harris & Benedict, 1919，公开学术公式 |
| Katch-McArdle | BMR（需体脂率） | Katch & McArdle，公开学术公式 |
| Deurenberg 体脂率 | 由 BMI 估算体脂 | Deurenberg et al., 1991，公开学术公式 |
| FFMI 归一化 | 瘦体重指数 | 公开的力量训练文献 |

上述公式为教科书与行业通行的公开知识，本项目依据公开出版物独立实现，未复制任何
软件的源代码。

## 二、训练方法学参考

- **5/3/1**（Jim Wendler）：百分比周期化训练体系，公开展示于其出版物与公开文章。
  本项目仅实现其公开可查的百分比处方结构（第 1/2/3 周的主项组次与 AMRAP 组）。
- **StrongLifts 5×5**：公开的线性加重入门计划结构。
- **DUP（Daily Undulating Periodization）**：公开的每日波动周期化思路。

以上均为方法学层面的参考，未使用任何项目的代码。

## 三、依赖

### 运行时依赖

无。本项目除 MoonBit 标准库（`moonbitlang/core`）外不依赖任何第三方包，
以保证跨后端（wasm / wasm-gc / js / native）行为一致且结果可复现。

### 构建与开发环境

| 工具 | 版本 | 用途 |
| --- | --- | --- |
| moon | 0.1.20260904 (94521db 2026-09-04) | 构建、检查、测试、格式化、接口生成 |
| MoonBit 标准库 `moonbitlang/core` | 随工具链分发 | `Debug` 等基础 trait |
| git | 2.55.0.windows.3 | 版本管理（`moon fmt` 的 diff 输出依赖 git） |

## 四、工具链已知问题（本项目已规避）

在 moon 0.1.20260904 上实测发现：对类型使用 `pub` 声明时，该类型在其他包中
**只能解构、不能构造**（编译器报 `4036 Cannot create values of the read-only type`）。
需使用 `pub(all)` 才能获得完整的跨包构造能力。本项目全部公开类型均已使用 `pub(all)`，
并在 `examples/quickstart` 中以跨包构造的方式进行了验证。
