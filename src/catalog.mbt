///| 枚举取值目录。
///
/// 为命令行工具、图形界面或文档生成提供"所有可选项"的完整列表，
/// 调用方不必在业务代码里硬编码枚举成员，也不会在新增取值时漏改。

///|
/// 所有重量单位。
pub fn all_weight_units() -> Array[WeightUnit] {
  [Kg, Lb]
}

///|
/// 所有性别取值。
pub fn all_sexes() -> Array[Sex] {
  [Male, Female]
}

///|
/// 所有内置动作。
pub fn all_lifts() -> Array[Lift] {
  [Squat, Bench, Deadlift, OverheadPress]
}

///|
/// 构造一个自定义动作（用于深蹲/卧推/硬拉/推举之外的动作）。
pub fn custom_lift(name : String) -> Lift {
  Other(name)
}

///|
/// 所有训练目标。
pub fn all_goals() -> Array[Goal] {
  [Hypertrophy, FatLoss, Maintenance]
}

///|
/// 所有活动水平。
pub fn all_activity_levels() -> Array[ActivityLevel] {
  [Sedentary, Light, Moderate, Active, VeryActive]
}

///|
/// 所有 BMR 公式。
pub fn all_bmr_formulas() -> Array[BmrFormula] {
  [MifflinStJeor, KatchMcArdle, HarrisBenedict]
}

///|
/// 所有 1RM 估算公式。
pub fn all_onerm_formulas() -> Array[OneRmFormula] {
  [Epley, Brzycki, OConner, Lander]
}

///|
/// 所有波动周期化训练日类型。
pub fn all_dup_days() -> Array[DupDay] {
  [Heavy, Medium, Light]
}

///|
/// 所有训练状态。
pub fn all_training_statuses() -> Array[TrainingStatus] {
  [Fresh, Normal, Fatigued, Overreached]
}
