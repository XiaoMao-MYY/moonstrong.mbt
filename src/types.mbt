///|
/// 重量单位。内部计算统一使用公斤。
pub(all) enum WeightUnit {
  Kg
  Lb
} derive(Eq, Debug)

///|
/// 生理性别。仅用于 BMR 等存在性别差异的经验公式。
pub(all) enum Sex {
  Male
  Female
} derive(Eq, Debug)

///|
/// 主项动作。Other 用于自定义动作名。
pub(all) enum Lift {
  Squat
  Bench
  Deadlift
  OverheadPress
  Other(String)
} derive(Eq, Debug)

///|
/// 训练目标，决定宏量营养素分配策略。
pub(all) enum Goal {
  /// 增肌：热量盈余 + 高蛋白
  Hypertrophy
  /// 减脂：热量缺口 + 更高蛋白以保护瘦体重
  FatLoss
  /// 维持：热量平衡
  Maintenance
} derive(Eq, Debug)

///|
/// 输入非法值时抛出的错误。
pub(all) suberror InvalidInput {
  /// 重量必须为正数
  NonPositiveWeight(Double)
  /// 次数必须为正整数
  InvalidReps(Int)
  /// 百分比必须在 (0, 1] 区间
  InvalidPercentage(Double)
  /// 组数必须为正整数
  InvalidSets(Int)
  /// RPE 必须在 0..10 区间
  InvalidRpe(Double)
  /// RIR 必须为非负整数
  InvalidRir(Int)
  /// 身体参数（体重/身高/年龄）超出合理范围
  InvalidBodyMetric(String)
}

///|
/// 公斤与磅的换算常数。
pub const LB_PER_KG : Double = 2.20462262185

///|
/// 公斤转磅。
pub fn kg_to_lb(kg : Double) -> Double {
  kg * LB_PER_KG
}

///|
/// 磅转公斤。
pub fn lb_to_kg(lb : Double) -> Double {
  lb / LB_PER_KG
}

///|
/// 按单位把数值统一换算为公斤。
pub fn to_kg(value : Double, unit : WeightUnit) -> Double {
  match unit {
    Kg => value
    Lb => lb_to_kg(value)
  }
}

///|
/// 按单位把公斤换算为目标单位。
pub fn from_kg(kg : Double, unit : WeightUnit) -> Double {
  match unit {
    Kg => kg
    Lb => kg_to_lb(kg)
  }
}

///|
/// 把动作名渲染为中文。
pub fn lift_name(lift : Lift) -> String {
  match lift {
    Squat => "深蹲"
    Bench => "卧推"
    Deadlift => "硬拉"
    OverheadPress => "站姿推举"
    Other(name) => name
  }
}
