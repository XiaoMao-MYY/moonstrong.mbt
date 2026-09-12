///| 自适应调整（本项目的"智能"核心）。
///
/// 与基于生理信号（HRV、睡眠）的评估路线不同，这里完全依据
/// **训练者自己在杠铃上的表现**做判断：AMRAP 完成的次数、历史 e1RM
/// 轨迹、近期平均强度。输入可观测、结果可解释、无需任何可穿戴设备。

///|
/// 基于近期表现判断的训练状态。
pub(all) enum TrainingStatus {
  /// 状态高于基线，可以加大刺激
  Fresh
  /// 与基线持平，按计划执行
  Normal
  /// 低于基线，疲劳累积，考虑减量
  Fatigued
  /// 明显低于基线，可能过度训练，应减载
  Overreached
} derive(Eq, Debug)

///|
/// 减载建议。
pub(all) struct DeloadAdvice {
  /// 是否建议减载
  needed : Bool
  /// 触发原因（人可读）
  reason : String
  /// 建议的容量系数（0..1）
  volume_multiplier : Double
  /// 建议的强度系数（0..1）
  intensity_multiplier : Double
} derive(Eq, Debug)

///|
/// 由近期 e1RM 与基线 e1RM 的比值判断训练状态。
///
/// 比值 >= 1.02 视为状态新鲜；< 0.93 视为可能过度训练。
pub fn performance_status(
  recent_e1rm : Double,
  baseline_e1rm : Double,
) -> TrainingStatus raise InvalidInput {
  if recent_e1rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(recent_e1rm)
  }
  if baseline_e1rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(baseline_e1rm)
  }
  let ratio = recent_e1rm / baseline_e1rm
  if ratio >= 1.02 {
    Fresh
  } else if ratio >= 0.98 {
    Normal
  } else if ratio >= 0.93 {
    Fatigued
  } else {
    Overreached
  }
}

///|
/// 依据 AMRAP 表现推算下一个训练最大值（Training Max）。
///
/// 规则（5/3/1 惯例加表现校正）：
/// 1. 基线推进：上肢每周期 +2.5kg，下肢 +5kg；
/// 2. 表现校正：用 AMRAP 组反推 e1RM，取其 85% 作为候选；
/// 3. 取两者较大值，但不超过 e1RM 的 90%，防止一次性冲得太高；
/// 4. 下降保护：单次调整不得比当前 TM 低 10% 以上。
///
/// 第 4 条是必要的：某一次 AMRAP 受睡眠、进食、情绪影响而表现很差时，
/// 若直接按 e1RM 反推会让 TM 断崖式下跌，反而破坏渐进超负荷的连续性。
pub fn next_training_max(
  current_tm : Double,
  amrap_weight : Double,
  amrap_reps : Int,
  lower_body : Bool,
) -> Double raise InvalidInput {
  if current_tm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(current_tm)
  }
  if amrap_weight <= 0.0 {
    raise InvalidInput::NonPositiveWeight(amrap_weight)
  }
  if amrap_reps < 0 {
    raise InvalidInput::InvalidReps(amrap_reps)
  }
  let increment = if lower_body { 5.0 } else { 2.5 }
  let baseline = current_tm + increment
  // AMRAP 0 次说明该重量已无法完成，直接退回到基线的保守值并减半推进
  if amrap_reps == 0 {
    return current_tm + increment * 0.5
  }
  let e1rm = e1rm_from_set(amrap_weight, amrap_reps, 0)
  let candidate = e1rm * 0.85
  let cap = e1rm * 0.90
  let mut next = if baseline > candidate { baseline } else { candidate }
  if next > cap {
    next = cap
  }
  // 下降保护：单次跌幅不超过 10%
  let floor = current_tm * 0.90
  if next < floor {
    next = floor
  }
  next
}

///|
/// 平台期检测：最近 window 次 e1RM 估计的改善幅度是否低于阈值。
///
/// history 按时间顺序排列。返回 true 表示进入平台期。
pub fn detect_plateau(
  history : Array[Double],
  window : Int,
  threshold_ratio : Double,
) -> Bool raise InvalidInput {
  if window <= 1 {
    raise InvalidInput::InvalidSets(window)
  }
  if threshold_ratio < 0.0 {
    raise InvalidInput::InvalidPercentage(threshold_ratio)
  }
  if history.length() < window {
    return false
  }
  let n = history.length()
  let oldest = history[n - window]
  let newest = history[n - 1]
  if oldest <= 0.0 {
    raise InvalidInput::NonPositiveWeight(oldest)
  }
  let improvement = (newest - oldest) / oldest
  improvement < threshold_ratio
}

///|
/// 综合判断是否应减载，并给出容量与强度系数。
///
/// 触发规则（任一命中即建议减载）：
/// - 距上次减载已 >= 6 周；
/// - 已检测出平台期且距上次减载 >= 3 周；
/// - 近期平均强度 >= 85% 且距上次减载 >= 4 周。
pub fn suggest_deload(
  weeks_since_deload : Int,
  avg_intensity : Double,
  plateau : Bool,
  weeks_trained : Int,
) -> DeloadAdvice raise InvalidInput {
  if weeks_since_deload < 0 {
    raise InvalidInput::InvalidSets(weeks_since_deload)
  }
  if weeks_trained < 0 {
    raise InvalidInput::InvalidSets(weeks_trained)
  }
  if avg_intensity < 0.0 || avg_intensity > 1.5 {
    raise InvalidInput::InvalidPercentage(avg_intensity)
  }
  if weeks_since_deload >= 6 {
    return {
      needed: true,
      reason: "距上次减载已 \{weeks_since_deload} 周，疲劳累积需要释放",
      volume_multiplier: 0.5,
      intensity_multiplier: 0.7,
    }
  }
  if plateau && weeks_since_deload >= 3 {
    return {
      needed: true,
      reason: "已出现平台期且距上次减载 \{weeks_since_deload} 周",
      volume_multiplier: 0.6,
      intensity_multiplier: 0.7,
    }
  }
  if avg_intensity >= 0.85 && weeks_since_deload >= 4 {
    return {
      needed: true,
      reason: "近期平均强度 \{avg_intensity} 偏高且持续 \{weeks_since_deload} 周",
      volume_multiplier: 0.6,
      intensity_multiplier: 0.75,
    }
  }
  {
    needed: false,
    reason: "无需减载，按计划推进",
    volume_multiplier: 1.0,
    intensity_multiplier: 1.0,
  }
}

///|
/// 自主调节：依据上一组实际达成的 RIR 调整下一次负荷。
///
/// 若实际比目标轻松（达成 RIR 高于目标），下次加重；
/// 若比目标吃力（达成 RIR 低于目标），下次减重。
/// 每差 1 次 RIR 调整 1RM 的 2.5%。
pub fn autoregulate_load(
  one_rm : Double,
  target_rir : Int,
  achieved_rir : Int,
) -> Double raise InvalidInput {
  if one_rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(one_rm)
  }
  if target_rir < 0 {
    raise InvalidInput::InvalidRir(target_rir)
  }
  if achieved_rir < 0 {
    raise InvalidInput::InvalidRir(achieved_rir)
  }
  let delta = (achieved_rir - target_rir).to_double()
  one_rm * (1.0 + 0.025 * delta)
}

///|
/// 依据训练状态给出下一阶段的容量调整系数。
///
/// 状态好则加大容量，状态差则缩减，是"渐进超负荷"的量化实现。
pub fn volume_adjustment(status : TrainingStatus) -> Double {
  match status {
    Fresh => 1.1
    Normal => 1.0
    Fatigued => 0.85
    Overreached => 0.6
  }
}
