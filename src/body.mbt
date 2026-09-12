///| 身体成分与能量代谢计算。
///
/// 全部为公开发表的经验公式，结果用于训练与饮食规划参考，
/// 不构成医疗建议；个体差异与测量误差可能显著影响实际值。

///|
/// 日常活动水平，决定 TDEE 的活动系数。
pub(all) enum ActivityLevel {
  /// 久坐：几乎不运动，系数 1.2
  Sedentary
  /// 轻度：每周 1-3 次训练，系数 1.375
  Light
  /// 中度：每周 3-5 次训练，系数 1.55
  Moderate
  /// 高度：每周 6-7 次训练，系数 1.725
  Active
  /// 极高：体力工作或每日双练，系数 1.9
  VeryActive
} derive(Eq, Debug)

///|
/// BMR（基础代谢率）估算公式。
pub(all) enum BmrFormula {
  /// Mifflin-St Jeor：目前公认误差较小的通用公式
  MifflinStJeor
  /// Katch-McArdle：需要已知体脂率，对低体脂人群更准
  KatchMcArdle
  /// 修订版 Harris-Benedict：经典公式
  HarrisBenedict
} derive(Eq, Debug)

///|
/// 活动系数。
pub fn activity_factor(level : ActivityLevel) -> Double {
  match level {
    Sedentary => 1.2
    Light => 1.375
    Moderate => 1.55
    Active => 1.725
    VeryActive => 1.9
  }
}

///|
/// 校验身体参数是否落在合理范围内。
fn check_body(
  weight_kg : Double,
  height_cm : Double,
  age : Int,
) -> Unit raise InvalidInput {
  if weight_kg <= 0.0 || weight_kg > 400.0 {
    raise InvalidInput::InvalidBodyMetric("weight_kg 应在 (0, 400]")
  }
  if height_cm <= 0.0 || height_cm > 260.0 {
    raise InvalidInput::InvalidBodyMetric("height_cm 应在 (0, 260]")
  }
  if age <= 0 || age > 120 {
    raise InvalidInput::InvalidBodyMetric("age 应在 (0, 120]")
  }
}

///|
/// 计算 BMR（千卡/天）。
///
/// Katch-McArdle 需要 body_fat_pct（0..1 小数）；其余公式忽略该参数。
pub fn bmr(
  formula : BmrFormula,
  sex : Sex,
  weight_kg : Double,
  height_cm : Double,
  age : Int,
  body_fat_pct : Double,
) -> Double raise InvalidInput {
  check_body(weight_kg, height_cm, age)
  match formula {
    MifflinStJeor => {
      let base = 10.0 * weight_kg + 6.25 * height_cm - 5.0 * age.to_double()
      match sex {
        Male => base + 5.0
        Female => base - 161.0
      }
    }
    HarrisBenedict =>
      match sex {
        Male =>
          88.362 +
          13.397 * weight_kg +
          4.799 * height_cm -
          5.677 * age.to_double()
        Female =>
          447.593 +
          9.247 * weight_kg +
          3.098 * height_cm -
          4.330 * age.to_double()
      }
    KatchMcArdle => {
      if body_fat_pct < 0.0 || body_fat_pct >= 1.0 {
        raise InvalidInput::InvalidBodyMetric("body_fat_pct 应在 [0, 1)")
      }
      let lbm = weight_kg * (1.0 - body_fat_pct)
      370.0 + 21.6 * lbm
    }
  }
}

///|
/// 计算 TDEE（每日总能量消耗，千卡/天）。
pub fn tdee(
  formula : BmrFormula,
  sex : Sex,
  weight_kg : Double,
  height_cm : Double,
  age : Int,
  body_fat_pct : Double,
  activity : ActivityLevel,
) -> Double raise InvalidInput {
  let b = bmr(formula, sex, weight_kg, height_cm, age, body_fat_pct)
  b * activity_factor(activity)
}

///|
/// 宏量营养素分配结果（克/天）。
pub(all) struct MacroPlan {
  /// 目标总热量（千卡/天）
  calories : Double
  /// 蛋白质（克）
  protein_g : Double
  /// 脂肪（克）
  fat_g : Double
  /// 碳水（克）
  carb_g : Double
} derive(Eq, Debug)

///|
/// 依据目标给出宏量营养素分配。
///
/// 蛋白质按体重设定：增肌 1.8 g/kg、减脂 2.2 g/kg、维持 1.8 g/kg。
/// 脂肪按总热量占比设定：增肌 25%、减脂 22%、维持 27%。
/// 碳水填补剩余热量（蛋白与碳水 4 kcal/g，脂肪 9 kcal/g）。
pub fn macro_plan(
  goal : Goal,
  weight_kg : Double,
  maintenance_calories : Double,
) -> MacroPlan raise InvalidInput {
  if weight_kg <= 0.0 || weight_kg > 400.0 {
    raise InvalidInput::InvalidBodyMetric("weight_kg 应在 (0, 400]")
  }
  if maintenance_calories <= 0.0 {
    raise InvalidInput::InvalidBodyMetric("maintenance_calories 必须为正")
  }
  let calories = match goal {
    Hypertrophy => maintenance_calories + 400.0
    FatLoss => maintenance_calories - 500.0
    Maintenance => maintenance_calories
  }
  let protein_per_kg = match goal {
    Hypertrophy => 1.8
    FatLoss => 2.2
    Maintenance => 1.8
  }
  let fat_ratio = match goal {
    Hypertrophy => 0.25
    FatLoss => 0.22
    Maintenance => 0.27
  }
  let target = if calories < 1200.0 { 1200.0 } else { calories }
  let protein_g = weight_kg * protein_per_kg
  let fat_g = target * fat_ratio / 9.0
  let remaining = target - protein_g * 4.0 - fat_g * 9.0
  let carb_g = if remaining > 0.0 { remaining / 4.0 } else { 0.0 }
  { calories: target, protein_g, fat_g, carb_g, }
}

///|
/// BMI（身体质量指数）= 体重(kg) / 身高(m)^2。
pub fn bmi(weight_kg : Double, height_cm : Double) -> Double raise InvalidInput {
  if weight_kg <= 0.0 || weight_kg > 400.0 {
    raise InvalidInput::InvalidBodyMetric("weight_kg 应在 (0, 400]")
  }
  if height_cm <= 0.0 || height_cm > 260.0 {
    raise InvalidInput::InvalidBodyMetric("height_cm 应在 (0, 260]")
  }
  let h_m = height_cm / 100.0
  weight_kg / (h_m * h_m)
}

///|
/// 去脂体重指数 FFMI。
///
/// FFMI = 去脂体重(kg) / 身高(m)^2。
/// 归一化 FFMI 额外修正身高带来的偏差：+ 6.1 * (1.8 - 身高m)。
pub fn ffmi(
  weight_kg : Double,
  height_cm : Double,
  body_fat_pct : Double,
  normalized : Bool,
) -> Double raise InvalidInput {
  if weight_kg <= 0.0 || weight_kg > 400.0 {
    raise InvalidInput::InvalidBodyMetric("weight_kg 应在 (0, 400]")
  }
  if height_cm <= 0.0 || height_cm > 260.0 {
    raise InvalidInput::InvalidBodyMetric("height_cm 应在 (0, 260]")
  }
  if body_fat_pct < 0.0 || body_fat_pct >= 1.0 {
    raise InvalidInput::InvalidBodyMetric("body_fat_pct 应在 [0, 1)")
  }
  let h_m = height_cm / 100.0
  let lbm = weight_kg * (1.0 - body_fat_pct)
  let raw = lbm / (h_m * h_m)
  if normalized {
    raw + 6.1 * (1.8 - h_m)
  } else {
    raw
  }
}

///|
/// Deurenberg 公式估算体脂率，返回 0..1 的小数。
///
/// BF% = 1.20 * BMI + 0.23 * 年龄 - 10.8 * 性别系数 - 5.4
/// （性别系数：男 1，女 0）
///
/// 说明：美国海军围度法精度更高，但需要以 10 为底的对数；为了让核心
/// 计算保持零依赖且在所有后端（wasm-gc / js / native）结果完全一致，
/// 这里选用不含超越函数的 Deurenberg 公式。对同一输入，本函数在任何
/// 平台返回完全相同的双精度结果。
pub fn body_fat_deurenberg(
  sex : Sex,
  weight_kg : Double,
  height_cm : Double,
  age : Int,
) -> Double raise InvalidInput {
  let b = bmi(weight_kg, height_cm)
  if age <= 0 || age > 120 {
    raise InvalidInput::InvalidBodyMetric("age 应在 (0, 120]")
  }
  let sex_factor = match sex {
    Male => 1.0
    Female => 0.0
  }
  let pct = 1.20 * b + 0.23 * age.to_double() - 10.8 * sex_factor - 5.4
  let clamped = if pct < 2.0 { 2.0 } else if pct > 70.0 { 70.0 } else { pct }
  clamped / 100.0
}

///|
/// 相对力量系数 = 1RM / 体重。用于跨体重比较力量水平。
pub fn relative_strength(
  one_rm : Double,
  body_weight : Double,
) -> Double raise InvalidInput {
  if one_rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(one_rm)
  }
  if body_weight <= 0.0 {
    raise InvalidInput::NonPositiveWeight(body_weight)
  }
  one_rm / body_weight
}
