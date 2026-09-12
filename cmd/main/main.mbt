///|
/// moonstrong 命令行演示入口。
///
/// 展示一条完整的"从一次训练记录到下一次处方"的链路：
/// 估算 1RM -> 生成 5/3/1 处方 -> 按 RPE 给出重量 -> 给出减载建议。
///
/// 运行：moon run cmd/main
fn status_text(s : @strong.TrainingStatus) -> String {
  match s {
    @strong.Fresh => "状态新鲜，可加大刺激"
    @strong.Normal => "与基线持平，按计划推进"
    @strong.Fatigued => "疲劳累积，考虑减量"
    @strong.Overreached => "明显下滑，建议减载"
  }
}

///|
fn main raise {
  println("== moonstrong：力量训练智能编程引擎 ==")
  println("")

  // 1. 由一组实际训练记录估算 1RM
  let weight = 100.0
  let reps = 5
  let e1rm = @strong.consensus_1rm(weight, reps)
  println("[1] 1RM 估算")
  println("    输入：\{weight}kg x \{reps} 次")
  println("    共识 1RM：\{e1rm}kg")
  println("    置信度：\{@strong.estimate_confidence(reps)}")
  let tm = @strong.training_max(e1rm, 0.9)
  println("    训练最大值 TM(90%)：\{tm}kg")

  // 2. 基于 TM 生成 5/3/1 第 1 周处方
  println("")
  println("[2] 5/3/1 第 1 周主项处方（基于 TM）")
  let sets = @strong.five_three_one_sets(tm, 1)
  for i = 0; i < sets.length(); i = i + 1 {
    let s = sets[i]
    let tag = if s.amrap { "（AMRAP）" } else { "" }
    let w = @strong.round_to_plate(s.weight, 2.5)
    println("    第 \{i + 1} 组：\{w}kg x \{s.reps} 次\{tag}")
  }

  // 3. 按 RPE 处方下一次训练重量
  println("")
  println("[3] RPE 处方：完成 5 次且保留 1 次余量（RPE 9）")
  println("    建议重量：\{@strong.weight_at_rir(tm, 5, 1)}kg")

  // 4. 自适应建议
  println("")
  println("[4] 自适应建议")
  let status = @strong.performance_status(e1rm, e1rm)
  println("    训练状态：\{status_text(status)}")
  let advice = @strong.suggest_deload(5, 0.80, false, 10)
  if advice.needed {
    println("    减载：需要 —— \{advice.reason}")
    println(
      "    容量系数 \{advice.volume_multiplier}，强度系数 \{advice.intensity_multiplier}",
    )
  } else {
    println("    减载：\{advice.reason}")
  }

  // 5. 若这次 AMRAP 完成了 7 次，下一周期的 TM
  println("")
  println("[5] 若 AMRAP 完成 7 次，下一周期训练最大值")
  println("    新 TM：\{@strong.next_training_max(tm, tm * 0.95, 7, true)}kg")
}
