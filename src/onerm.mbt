///|
/// 1RM（一次最大重量）估算公式。
///
/// 每种公式都是对"重量—次数"关系的经验拟合，适用区间与误差不同。
/// 本模块同时提供单一公式与多公式加权共识两种结果。
pub(all) enum OneRmFormula {
  /// Epley: 1RM = w * (1 + r / 30)
  Epley
  /// Brzycki: 1RM = w * 36 / (37 - r)
  Brzycki
  /// O'Conner: 1RM = w * (1 + r / 40)
  OConner
  /// Lander: 1RM = 100 * w / (101.3 - 2.67123 * r)
  Lander
} derive(Eq, Debug)

///|
/// 判断某公式在给定次数下是否处于有效定义域内。
pub fn formula_valid_at(formula : OneRmFormula, reps : Int) -> Bool {
  match formula {
    Epley => reps > 0
    OConner => reps > 0
    Brzycki => reps > 0 && reps < 37
    Lander => reps > 0 && reps < 38
  }
}

///|
/// 公式的可读名称，用于结果展示。
///
/// 之所以提供本函数而非让公式实现 Debug/Show：在当前 moon 工具链
/// （0.1.20260904）下，对类型派生 Debug 会使其在跨包场景下变为只读类型，
/// 使用方将无法构造该类型的任何值。为保证公开类型始终可构造，
/// 本库统一以显式函数提供展示能力。
pub fn formula_name(formula : OneRmFormula) -> String {
  match formula {
    Epley => "Epley"
    Brzycki => "Brzycki"
    OConner => "O'Conner"
    Lander => "Lander"
  }
}

///|
/// 计算某个公式在给定重量与次数下的 1RM 估计值。
///
/// weight 单位为公斤且必须为正；reps 必须为正整数且落在公式定义域内。
pub fn estimate_1rm(
  formula : OneRmFormula,
  weight : Double,
  reps : Int,
) -> Double raise InvalidInput {
  if weight <= 0.0 {
    raise InvalidInput::NonPositiveWeight(weight)
  }
  if !formula_valid_at(formula, reps) {
    raise InvalidInput::InvalidReps(reps)
  }
  let r = reps.to_double()
  match formula {
    Epley => weight * (1.0 + r / 30.0)
    Brzycki => weight * 36.0 / (37.0 - r)
    OConner => weight * (1.0 + r / 40.0)
    Lander => 100.0 * weight / (101.3 - 2.67123 * r)
  }
}

///|
/// 返回全部可用公式的估算结果，顺序为 Epley、Brzycki、O'Conner、Lander。
pub fn estimate_1rm_all(
  weight : Double,
  reps : Int,
) -> Array[(OneRmFormula, Double)] raise InvalidInput {
  if weight <= 0.0 {
    raise InvalidInput::NonPositiveWeight(weight)
  }
  if reps <= 0 {
    raise InvalidInput::InvalidReps(reps)
  }
  let formulas = [Epley, Brzycki, OConner, Lander]
  let out : Array[(OneRmFormula, Double)] = []
  for i = 0; i < formulas.length(); i = i + 1 {
    let f = formulas[i]
    if formula_valid_at(f, reps) {
      out.push((f, estimate_1rm(f, weight, reps)))
    }
  }
  out
}

///|
/// 单个公式在特定次数下的相对可信度权重（0..1）。
///
/// 依据：低次数（<=5）时各公式分歧小；中等次数（6-10）Epley / Brzycki
/// 拟合较好；高次数（>10）误差普遍放大，其中 O'Conner 衰减较慢。
pub fn formula_weight(formula : OneRmFormula, reps : Int) -> Double {
  if reps <= 0 {
    return 0.0
  }
  let low = reps <= 5
  let mid = reps <= 10
  match formula {
    Epley => if low || mid { 1.0 } else { 0.6 }
    Brzycki => if low { 1.0 } else if mid { 0.9 } else { 0.5 }
    OConner => if low { 0.8 } else if mid { 0.85 } else { 0.9 }
    Lander => if low { 0.9 } else if mid { 0.8 } else { 0.7 }
  }
}

///|
/// 多公式加权共识 1RM。
///
/// 比单一公式稳健：以可信度权重加权平均，抑制任一公式的系统性偏差。
pub fn consensus_1rm(weight : Double, reps : Int) -> Double raise InvalidInput {
  let all = estimate_1rm_all(weight, reps)
  if all.length() == 0 {
    raise InvalidInput::InvalidReps(reps)
  }
  let mut num = 0.0
  let mut den = 0.0
  for i = 0; i < all.length(); i = i + 1 {
    let f = all[i].0
    let v = all[i].1
    let w = formula_weight(f, reps)
    num = num + w * v
    den = den + w
  }
  if den == 0.0 {
    raise InvalidInput::InvalidReps(reps)
  }
  num / den
}

///|
/// 估算结果的整体置信度（0..1），随次数升高而下降。
///
/// 1 次为直接测得，置信度最高；超过 10 次后衰减明显。
pub fn estimate_confidence(reps : Int) -> Double {
  if reps <= 0 {
    return 0.0
  }
  if reps == 1 {
    return 1.0
  }
  if reps <= 5 {
    return 0.9
  }
  if reps <= 10 {
    return 0.75
  }
  if reps <= 20 {
    return 0.5
  }
  0.3
}

///|
/// 已知 1RM，反推在目标次数下应使用的重量（公式的逆运算）。
pub fn weight_for_reps(
  formula : OneRmFormula,
  one_rm : Double,
  reps : Int,
) -> Double raise InvalidInput {
  if one_rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(one_rm)
  }
  if !formula_valid_at(formula, reps) {
    raise InvalidInput::InvalidReps(reps)
  }
  let r = reps.to_double()
  match formula {
    Epley => one_rm / (1.0 + r / 30.0)
    Brzycki => one_rm * (37.0 - r) / 36.0
    OConner => one_rm / (1.0 + r / 40.0)
    Lander => one_rm * (101.3 - 2.67123 * r) / 100.0
  }
}

///|
/// 计算某个重量占 1RM 的百分比（返回 0..1 的小数）。
pub fn percent_of_1rm(
  weight : Double,
  one_rm : Double,
) -> Double raise InvalidInput {
  if one_rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(one_rm)
  }
  if weight < 0.0 {
    raise InvalidInput::NonPositiveWeight(weight)
  }
  weight / one_rm
}

///|
/// 由 1RM 推算训练最大值（Training Max）。
///
/// 百分比训练法（如 5/3/1）通常不以真实 1RM 为基准，而取其 85%~90%，
/// 为状态波动留出余量。
pub fn training_max(
  one_rm : Double,
  percent : Double,
) -> Double raise InvalidInput {
  if one_rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(one_rm)
  }
  if percent <= 0.0 || percent > 1.0 {
    raise InvalidInput::InvalidPercentage(percent)
  }
  one_rm * percent
}
