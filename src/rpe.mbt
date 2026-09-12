///| RPE（主观用力程度）与 RIR（剩余次数）工具。
///
/// RPE 与 RIR 是同一信息的两种表达：RIR = 10 - RPE。
/// RPE 10 表示力竭（还剩 0 次），RPE 9 表示还剩 1 次。

///|
/// RPE 到 %1RM 的锚点表（依据 Tuchscherer / RTS 的常用换算）。
/// 表中为"该 RPE 下能完成的次数所对应的最大重量百分比"。
let rpe_table : Array[(Double, Double)] = [
  (5.0, 73.0),
  (6.0, 77.0),
  (6.5, 80.0),
  (7.0, 83.0),
  (7.5, 86.0),
  (8.0, 89.0),
  (8.5, 92.0),
  (9.0, 94.0),
  (9.5, 97.0),
  (10.0, 100.0),
]

///|
/// 由 RPE 换算为对应强度的 %1RM（返回 0..1 的小数）。
///
/// RPE 必须在 5..10 区间内，超出该区间的换算不可靠。
pub fn pct_from_rpe(rpe : Double) -> Double raise InvalidInput {
  if rpe < 5.0 || rpe > 10.0 {
    raise InvalidInput::InvalidRpe(rpe)
  }
  let n = rpe_table.length()
  // 先处理端点与精确命中
  if rpe <= rpe_table[0].0 {
    return rpe_table[0].1 / 100.0
  }
  if rpe >= rpe_table[n - 1].0 {
    return rpe_table[n - 1].1 / 100.0
  }
  let mut out = rpe_table[0].1
  for i = 0; i < n - 1; i = i + 1 {
    let x0 = rpe_table[i].0
    let y0 = rpe_table[i].1
    let x1 = rpe_table[i + 1].0
    let y1 = rpe_table[i + 1].1
    if rpe >= x0 && rpe <= x1 {
      let t = (rpe - x0) / (x1 - x0)
      out = y0 + t * (y1 - y0)
    }
  }
  out / 100.0
}

///|
/// 由 %1RM（0..1 小数）反推 RPE，使用同一张锚点表线性插值。
pub fn rpe_from_pct(pct : Double) -> Double raise InvalidInput {
  if pct <= 0.0 || pct > 1.0 {
    raise InvalidInput::InvalidPercentage(pct)
  }
  let target = pct * 100.0
  let n = rpe_table.length()
  if target <= rpe_table[0].1 {
    return rpe_table[0].0
  }
  if target >= rpe_table[n - 1].1 {
    return rpe_table[n - 1].0
  }
  let mut out = rpe_table[0].0
  for i = 0; i < n - 1; i = i + 1 {
    let y0 = rpe_table[i].1
    let y1 = rpe_table[i + 1].1
    if target >= y0 && target <= y1 {
      let t = (target - y0) / (y1 - y0)
      out = rpe_table[i].0 + t * (rpe_table[i + 1].0 - rpe_table[i].0)
    }
  }
  out
}

///|
/// RPE 转 RIR（剩余可完成次数）。
pub fn rir_from_rpe(rpe : Double) -> Int raise InvalidInput {
  if rpe < 0.0 || rpe > 10.0 {
    raise InvalidInput::InvalidRpe(rpe)
  }
  let r = 10.0 - rpe
  // 向最近整数取整，RPE 9.5 计为 1 次余量
  let t = (r + 0.5).floor()
  t.to_int()
}

///|
/// RIR 转 RPE。RIR 必须非负。
pub fn rpe_from_rir(rir : Int) -> Double raise InvalidInput {
  if rir < 0 {
    raise InvalidInput::InvalidRir(rir)
  }
  if rir > 10 {
    raise InvalidInput::InvalidRir(rir)
  }
  10.0 - rir.to_double()
}

///|
/// 已知 1RM，求"完成 reps 次且保留 rir 次余量"时应使用的重量。
///
/// 采用 RIR 修正的 Epley 关系：把余量次数加回到已完成次数上，
/// 即 e1RM = w * (1 + (reps + rir) / 30)，再反解 w。
/// 这是自主调节训练（autoregulation）中常用的处方方式。
pub fn weight_at_rir(
  one_rm : Double,
  reps : Int,
  rir : Int,
) -> Double raise InvalidInput {
  if one_rm <= 0.0 {
    raise InvalidInput::NonPositiveWeight(one_rm)
  }
  if reps <= 0 {
    raise InvalidInput::InvalidReps(reps)
  }
  if rir < 0 {
    raise InvalidInput::InvalidRir(rir)
  }
  let effective = (reps + rir).to_double()
  one_rm / (1.0 + effective / 30.0)
}

///|
/// 已知 1RM，求"完成 reps 次且达到目标 RPE"时应使用的重量。
pub fn weight_at_rpe(
  one_rm : Double,
  reps : Int,
  rpe : Double,
) -> Double raise InvalidInput {
  let rir = rir_from_rpe(rpe)
  weight_at_rir(one_rm, reps, rir)
}

///|
/// 由一次实际完成的组反推当日 e1RM（Estimated 1RM）。
///
/// 把余量次数计入 Epley 公式，比单纯按完成次数估算更贴近真实状态。
pub fn e1rm_from_set(
  weight : Double,
  reps : Int,
  rir : Int,
) -> Double raise InvalidInput {
  if weight <= 0.0 {
    raise InvalidInput::NonPositiveWeight(weight)
  }
  if reps <= 0 {
    raise InvalidInput::InvalidReps(reps)
  }
  if rir < 0 {
    raise InvalidInput::InvalidRir(rir)
  }
  let effective = (reps + rir).to_double()
  weight * (1.0 + effective / 30.0)
}
