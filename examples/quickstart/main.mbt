///|
/// 快速开始示例：一次完整训练 + 营养规划。
///
/// 运行：moon run examples/quickstart
///
/// 本示例演示如何用 moonstrong 回答两个实际问题：
///   1. 这次训练的量够不够、累不累？
///   2. 按当前身体数据和目标，每天该吃多少？
///
/// 注意：库中所有重量单位统一为公斤，百分比统一为 0..1 的小数；
/// 展示层负责换算成人类可读的形式（百分比、可上杠的重量）。

///|
/// 把公斤数取整到可用的杠铃片精度（默认 2.5kg）。
fn plate(w : Double) -> Double raise {
  @src.round_to_plate(w, 2.5)
}

///|
/// 把 0..1 的小数显示为百分比，保留 1 位小数。
fn pct(x : Double) -> String {
  let v = (x * 1000.0 + 0.5).floor() / 10.0
  "\{v}%"
}

///|

///|
/// 保留 1 位小数，用于展示非百分比数值。
fn r1(x : Double) -> String {
  let v = (x * 10.0 + 0.5).floor() / 10.0
  "\{v}"
}

///|
fn main raise {
  println("== 示例：一次训练的量化和一份饮食规划 ==")
  println("")

  // ---- 第 1 部分：量化这次训练 ----
  // 某天深蹲训练：100kg 5 次 x3 组（留 2 次余量），最后一组 100kg 做到力竭完成 8 次
  let sets = [
    @src.make_set(100.0, 5, 2),
    @src.make_set(100.0, 5, 2),
    @src.make_set(100.0, 8, 0),
  ]
  let one_rm = @src.consensus_1rm(100.0, 8)

  println("[训练] 深蹲 100kg：5 次 x2 组 + 8 次力竭 x1 组")
  println(
    "   反推 1RM：\{plate(one_rm)}kg（估算置信度：\{@src.estimate_confidence(8)}）",
  )
  println("   总容量负荷：\{@src.total_volume(sets)}kg")
  println("   有效次数：\{@src.total_stimulating_reps(sets)} 次")
  println("   平均强度：\{pct(@src.average_intensity(sets, one_rm))} 1RM")
  println(
    "   总 INOL（疲劳指标，>2 较难恢复）：\{r1(@src.total_inol(sets, one_rm))}",
  )

  // ---- 第 2 部分：营养规划 ----
  let body_weight = 80.0
  let height = 180.0
  let age = 30
  let tdee = @src.tdee(
    @src.BmrFormula::MifflinStJeor,
    @src.Sex::Male,
    body_weight,
    height,
    age,
    0.0,
    @src.ActivityLevel::Moderate,
  )

  println("")
  println(
    "[身体] 男 \{body_weight}kg / \{height}cm / \{age} 岁，每周训练 3-5 次",
  )
  println("   BMI：\{r1(@src.bmi(body_weight, height))}")
  let bf = @src.body_fat_deurenberg(@src.Sex::Male, body_weight, height, age)
  println("   估算体脂率：\{pct(bf)}")
  println(
    "   FFMI（归一化）：\{r1(@src.ffmi(body_weight, height, bf, true))}",
  )
  println("   TDEE：\{tdee} kcal/天")

  let plan = @src.macro_plan(@src.Goal::Hypertrophy, body_weight, tdee)
  println("")
  println(
    "[营养] 增肌目标（热量盈余 \{plan.calories - tdee} kcal）",
  )
  println("   目标热量：\{plan.calories} kcal")
  println("   蛋白质：\{plan.protein_g} g")
  println("   脂肪：\{plan.fat_g} g")
  println("   碳水：\{r1(plan.carb_g)} g")

  // ---- 第 3 部分：下次训练怎么调 ----
  println("")
  println("[下一步] 依据本次表现给出建议")
  let status = @src.performance_status(one_rm, one_rm)
  println("   容量调整系数：\{@src.volume_adjustment(status)}")
  let next = @src.weight_at_rir(one_rm, 5, 2)
  println("   目标 5 次 RPE 8（留 2 次余量）：\{plate(next)}kg")
  println("   按 RIR 反推该组相当于：RPE \{@src.rpe_from_rir(2)}")
}
