///| 训练容量与强度量化。
///
/// 容量（volume）与强度（intensity）是训练编程中两个最核心的可控变量：
/// 容量驱动肌肉增长，强度驱动神经适应与最大力量。

///|
/// 一次训练组的记录。
pub(all) struct SetRecord {
  /// 该组重量（公斤）
  weight : Double
  /// 该组完成次数
  reps : Int
  /// 该组结束时的剩余次数（RIR）；0 表示力竭
  rir : Int
} derive(Eq, Debug)

///|
/// 构造一组训练记录。
pub fn make_set(weight : Double, reps : Int, rir : Int) -> SetRecord {
  { weight, reps, rir, }
}

///|
/// 单组容量负荷（Volume Load）= 重量 × 次数。
pub fn set_volume(weight : Double, reps : Int) -> Double raise InvalidInput {
  if weight < 0.0 {
    raise InvalidInput::NonPositiveWeight(weight)
  }
  if reps <= 0 {
    raise InvalidInput::InvalidReps(reps)
  }
  weight * reps.to_double()
}

///|
/// 多组的总容量负荷。
pub fn total_volume(sets : Array[SetRecord]) -> Double raise InvalidInput {
  let mut sum = 0.0
  for i = 0; i < sets.length(); i = i + 1 {
    let s = sets[i]
    if s.weight < 0.0 {
      raise InvalidInput::NonPositiveWeight(s.weight)
    }
    if s.reps <= 0 {
      raise InvalidInput::InvalidReps(s.reps)
    }
    sum = sum + s.weight * s.reps.to_double()
  }
  sum
}

///|
/// 单组的有效次数（Stimulating Reps）。
///
/// 只有足够接近力竭的次数才产生明显的增肌刺激。经验规则是：
/// 距离力竭 5 次以内（RIR <= 4）的次数才计入，且越接近力竭权重越高。
/// 这里返回该组中"处于有效刺激区"的次数，用于比较不同训练方案的真实刺激量。
pub fn stimulating_reps(reps : Int, rir : Int) -> Int raise InvalidInput {
  if reps <= 0 {
    raise InvalidInput::InvalidReps(reps)
  }
  if rir < 0 {
    raise InvalidInput::InvalidRir(rir)
  }
  let budget = 5 - rir
  if budget <= 0 {
    return 0
  }
  if reps < budget {
    return reps
  }
  budget
}

///|
/// 多个组的有效次数之和。
pub fn total_stimulating_reps(
  sets : Array[SetRecord],
) -> Int raise InvalidInput {
  let mut sum = 0
  for i = 0; i < sets.length(); i = i + 1 {
    let s = sets[i]
    sum = sum + stimulating_reps(s.reps, s.rir)
  }
  sum
}

///|
/// INOL（Intensity × Number Of Lifts）——单组疲劳指标。
///
/// INOL = 次数 / (100 - 强度百分比)。强度越高（越接近 100%）分母越小，
/// 疲劳成本上升得越快。经验区间：单组 0.5~1.0；单次训练总量 <= 2.0 较易恢复。
pub fn inol(reps : Int, percent : Double) -> Double raise InvalidInput {
  if reps <= 0 {
    raise InvalidInput::InvalidReps(reps)
  }
  if percent <= 0.0 || percent >= 1.0 {
    raise InvalidInput::InvalidPercentage(percent)
  }
  reps.to_double() / (100.0 - percent * 100.0)
}

///|
/// 多个组的 INOL 之和。
pub fn total_inol(
  sets : Array[SetRecord],
  one_rm : Double,
) -> Double raise InvalidInput {
  if one_rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(one_rm)
  }
  let mut sum = 0.0
  for i = 0; i < sets.length(); i = i + 1 {
    let s = sets[i]
    let pct = percent_of_1rm(s.weight, one_rm)
    // 强度 >= 100% 时 INOL 无定义，跳过该组
    if pct > 0.0 && pct < 1.0 {
      sum = sum + inol(s.reps, pct)
    }
  }
  sum
}

///|
/// 平均相对强度：各组重量占 1RM 百分比的平均值。
pub fn average_intensity(
  sets : Array[SetRecord],
  one_rm : Double,
) -> Double raise InvalidInput {
  if one_rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(one_rm)
  }
  if sets.length() == 0 {
    raise InvalidInput::InvalidSets(0)
  }
  let mut sum = 0.0
  for i = 0; i < sets.length(); i = i + 1 {
    sum = sum + percent_of_1rm(sets[i].weight, one_rm)
  }
  sum / sets.length().to_double()
}

///|
/// 训练密度 = 总容量 / 总次数，即平均每公斤强度水平。
/// 用于比较"同样总容量下，是靠大重量低次数还是小重量高次数堆出来的"。
pub fn training_density(sets : Array[SetRecord]) -> Double raise InvalidInput {
  let vol = total_volume(sets)
  let mut reps = 0
  for i = 0; i < sets.length(); i = i + 1 {
    reps = reps + sets[i].reps
  }
  if reps == 0 {
    raise InvalidInput::InvalidReps(0)
  }
  vol / reps.to_double()
}
