///| 周期化训练模板。
///
/// 提供三种在实践中使用最广、且完全由百分比与次数定义的经典方案，
/// 便于程序生成可执行的训练处方，而不是只给出笼统建议。

///|
/// 一个被处方出来的训练组。
pub(all) struct PrescribedSet {
  /// 该组重量（公斤），由基准值 × 百分比算出
  weight : Double
  /// 占基准重量的百分比（0..1）
  percent : Double
  /// 处方次数
  reps : Int
  /// 是否为 AMRAP（尽可能多次）组
  amrap : Bool
} derive(Eq, Debug)

///|
/// 波动周期化（DUP）中的一天类型。
pub(all) enum DupDay {
  /// 大重量日：低次数高强度，发展最大力量
  Heavy
  /// 中量日：中等次数与强度
  Medium
  /// 小量日：高次数低强度，发展肌肉量与动作熟练度
  Light
} derive(Eq, Debug)

///|
/// 按基准重量与百分比生成一组处方。
fn prescribe(
  base : Double,
  percent : Double,
  reps : Int,
  amrap : Bool,
) -> PrescribedSet {
  { weight: base * percent, percent, reps, amrap, }
}

///|
/// 5/3/1（Wendler）某一周的主项处方。
///
/// 第 1 周 65/75/85% × 5/5/5+，第 2 周 70/80/90% × 3/3/3+，
/// 第 3 周 75/85/95% × 5/3/1+，第 4 周为减载周 40/50/60% × 5/5/5。
/// week 取 1..4。
pub fn five_three_one_sets(
  tm : Double,
  week : Int,
) -> Array[PrescribedSet] raise InvalidInput {
  if tm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(tm)
  }
  match week {
    1 =>
      [
        prescribe(tm, 0.65, 5, false),
        prescribe(tm, 0.75, 5, false),
        prescribe(tm, 0.85, 5, true),
      ]
    2 =>
      [
        prescribe(tm, 0.70, 3, false),
        prescribe(tm, 0.80, 3, false),
        prescribe(tm, 0.90, 3, true),
      ]
    3 =>
      [
        prescribe(tm, 0.75, 5, false),
        prescribe(tm, 0.85, 3, false),
        prescribe(tm, 0.95, 1, true),
      ]
    4 =>
      [
        prescribe(tm, 0.40, 5, false),
        prescribe(tm, 0.50, 5, false),
        prescribe(tm, 0.60, 5, false),
      ]
    _ => raise InvalidInput::InvalidSets(week)
  }
}

///|
/// 生成若干个 5/3/1 周期（每周期 4 周）的完整处方。
///
/// 返回 (周期内的周序号, 该周处方) 的序列，长度 = cycles * 4。
pub fn five_three_one_cycle(
  tm : Double,
  cycles : Int,
) -> Array[(Int, Array[PrescribedSet])] raise InvalidInput {
  if cycles <= 0 {
    raise InvalidInput::InvalidSets(cycles)
  }
  let out : Array[(Int, Array[PrescribedSet])] = []
  for c = 0; c < cycles; c = c + 1 {
    for w = 1; w <= 4; w = w + 1 {
      out.push((w, five_three_one_sets(tm, w)))
    }
  }
  out
}

///|
/// StrongLifts 5×5：5 组 × 5 次，同重量，线性加重。
///
/// start_weight 为起始重量，session_index 为第几次训练（从 0 开始），
/// increment 为每次训练增加的总重量（默认上肢 2.5kg、下肢 5kg）。
pub fn stronglifts_5x5(
  start_weight : Double,
  session_index : Int,
  increment : Double,
) -> Array[PrescribedSet] raise InvalidInput {
  if start_weight <= 0.0 {
    raise InvalidInput::NonPositiveWeight(start_weight)
  }
  if session_index < 0 {
    raise InvalidInput::InvalidSets(session_index)
  }
  if increment < 0.0 {
    raise InvalidInput::NonPositiveWeight(increment)
  }
  let w = start_weight + increment * session_index.to_double()
  let out : Array[PrescribedSet] = []
  for i = 0; i < 5; i = i + 1 {
    out.push({ weight: w, percent: 0.0, reps: 5, amrap: false, })
  }
  out
}

///|
/// 波动周期化（DUP）某一天的处方。
///
/// 大重量日 3×3 @ 90%，中量日 4×5 @ 77%，小量日 3×8 @ 65%。
pub fn dup_session(
  tm : Double,
  day : DupDay,
) -> Array[PrescribedSet] raise InvalidInput {
  if tm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(tm)
  }
  match day {
    Heavy => {
      let out : Array[PrescribedSet] = []
      for i = 0; i < 3; i = i + 1 {
        out.push(prescribe(tm, 0.90, 3, false))
      }
      out
    }
    Medium => {
      let out : Array[PrescribedSet] = []
      for i = 0; i < 4; i = i + 1 {
        out.push(prescribe(tm, 0.77, 5, false))
      }
      out
    }
    Light => {
      let out : Array[PrescribedSet] = []
      for i = 0; i < 3; i = i + 1 {
        out.push(prescribe(tm, 0.65, 8, false))
      }
      out
    }
  }
}

///|
/// 把处方重量按可用的最小配重向下取整（例如 2.5kg 一片）。
///
/// 避免程序给出 87.3kg 这种杠铃上无法实现的重量。
pub fn round_to_plate(
  weight : Double,
  increment : Double,
) -> Double raise InvalidInput {
  if weight <= 0.0 {
    raise InvalidInput::NonPositiveWeight(weight)
  }
  if increment <= 0.0 {
    raise InvalidInput::NonPositiveWeight(increment)
  }
  let steps = (weight / increment).floor()
  steps * increment
}
