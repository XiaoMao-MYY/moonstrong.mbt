///|
/// 按 2 位小数精度比较浮点数的测试辅助函数。
fn expect_near(actual : Double, expected : Double) -> Unit raise {
  // 四舍五入到 2 位小数，避免截断在边界值上产生假失败
  let a = (actual * 100.0 + 0.5).floor().to_int()
  let b = (expected * 100.0 + 0.5).floor().to_int()
  assert_eq(a, b)
}

// ---------- 单位换算 ----------

///|
test "kg 与 lb 互转" {
  expect_near(kg_to_lb(100.0), 220.46)
  // 用往返换算验证一致性，避免对截断常数做过度精确的断言
  expect_near(lb_to_kg(kg_to_lb(100.0)), 100.0)
  expect_near(to_kg(100.0, Lb), 45.36)
  expect_near(from_kg(100.0, Lb), 220.46)
  expect_near(to_kg(100.0, Kg), 100.0)
  expect_near(from_kg(100.0, Kg), 100.0)
}

///|
test "动作中文名" {
  assert_eq(lift_name(Squat), "深蹲")
  assert_eq(lift_name(Bench), "卧推")
  assert_eq(lift_name(Deadlift), "硬拉")
  assert_eq(lift_name(OverheadPress), "站姿推举")
  assert_eq(lift_name(Other("划船")), "划船")
}

// ---------- 1RM 估算 ----------

///|
test "Epley 公式" {
  // 100kg × 10 次 => 100 * (1 + 10/30) = 133.33
  expect_near(estimate_1rm(Epley, 100.0, 10), 133.33)
  expect_near(estimate_1rm(Epley, 100.0, 1), 103.33)
}

///|
test "Brzycki 公式" {
  // 100 * 36 / (37 - 10) = 133.33
  expect_near(estimate_1rm(Brzycki, 100.0, 10), 133.33)
}

///|
test "OConner 公式" {
  // 100 * (1 + 10/40) = 125.00
  expect_near(estimate_1rm(OConner, 100.0, 10), 125.00)
}

///|
test "Lander 公式" {
  // 10000 / (101.3 - 26.7123) = 134.07
  expect_near(estimate_1rm(Lander, 100.0, 10), 134.07)
}

///|
test "公式定义域边界" {
  assert_eq(formula_valid_at(Brzycki, 36), true)
  assert_eq(formula_valid_at(Brzycki, 37), false)
  assert_eq(formula_valid_at(Lander, 37), true)
  assert_eq(formula_valid_at(Lander, 38), false)
  assert_eq(formula_valid_at(Epley, 1), true)
  assert_eq(formula_valid_at(OConner, 100), true)
  assert_eq(formula_valid_at(Epley, 0), false)
}

///|
test "estimate_1rm_all 在超界时只返回可用公式" {
  // 38 次时 Brzycki（<37）与 Lander（<38）均越界，只剩 Epley 与 OConner
  let all = estimate_1rm_all(100.0, 38)
  assert_eq(all.length(), 2)
  assert_eq(formula_name(all[0].0), "Epley")
  assert_eq(formula_name(all[1].0), "O'Conner")
  // 常规区间内四个公式全部可用
  assert_eq(estimate_1rm_all(100.0, 5).length(), 4)
}

///|
test "共识 1RM 落在各公式结果之间" {
  let lo = estimate_1rm(OConner, 100.0, 10)
  let hi = estimate_1rm(Lander, 100.0, 10)
  let c = consensus_1rm(100.0, 10)
  assert_eq(c >= lo && c <= hi, true)
}

///|
test "置信度随次数单调下降" {
  assert_eq(estimate_confidence(1), 1.0)
  assert_eq(estimate_confidence(5), 0.9)
  assert_eq(estimate_confidence(10), 0.75)
  assert_eq(estimate_confidence(20), 0.5)
  assert_eq(estimate_confidence(30), 0.3)
  assert_eq(estimate_confidence(0), 0.0)
}

///|
test "公式权重随次数区间变化" {
  assert_eq(formula_weight(Epley, 3), 1.0)
  assert_eq(formula_weight(Epley, 8), 1.0)
  assert_eq(formula_weight(Epley, 20), 0.6)
  assert_eq(formula_weight(Brzycki, 20), 0.5)
  assert_eq(formula_weight(OConner, 20), 0.9)
  assert_eq(formula_weight(Lander, 20), 0.7)
  assert_eq(formula_weight(Epley, 0), 0.0)
}

///|
test "weight_for_reps 与 estimate_1rm 互为逆运算" {
  let one_rm = 150.0
  for r = 2; r <= 10; r = r + 1 {
    let w = weight_for_reps(Epley, one_rm, r)
    expect_near(estimate_1rm(Epley, w, r), one_rm)
  }
}

///|
test "percent_of_1rm 与 training_max" {
  expect_near(percent_of_1rm(80.0, 100.0), 0.80)
  expect_near(training_max(100.0, 0.9), 90.0)
  expect_near(training_max(100.0, 0.85), 85.0)
}

// ---------- 错误路径 ----------

///|
test "重量非正数时报错" {
  try ignore(estimate_1rm(Epley, 0.0, 5)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
}

///|
test "次数非正数时报错" {
  try ignore(estimate_1rm(Epley, 100.0, 0)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
}

///|
test "次数超出公式定义域时报错" {
  try ignore(estimate_1rm(Brzycki, 100.0, 40)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
}

///|
test "training_max 百分比越界时报错" {
  try ignore(training_max(100.0, 1.5)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
}

///|
test "consensus_1rm 输入非法时报错" {
  try ignore(consensus_1rm(0.0, 5)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
}

// ---------- RPE / RIR ----------

///|
test "RPE 与 RIR 互转" {
  assert_eq(rir_from_rpe(10.0), 0)
  assert_eq(rir_from_rpe(9.0), 1)
  assert_eq(rir_from_rpe(8.0), 2)
  assert_eq(rpe_from_rir(0), 10.0)
  assert_eq(rpe_from_rir(3), 7.0)
}

///|
test "pct_from_rpe 命中锚点" {
  expect_near(pct_from_rpe(10.0), 1.00)
  expect_near(pct_from_rpe(9.0), 0.94)
  expect_near(pct_from_rpe(8.0), 0.89)
  expect_near(pct_from_rpe(7.0), 0.83)
  expect_near(pct_from_rpe(5.0), 0.73)
}

///|
test "pct_from_rpe 与 rpe_from_pct 互为逆运算" {
  let mut rpe = 5.0
  while rpe <= 10.0 {
    let p = pct_from_rpe(rpe)
    expect_near(rpe_from_pct(p), rpe)
    rpe = rpe + 0.5
  }
}

///|
test "weight_at_rir 随余量增大而降低" {
  let w0 = weight_at_rir(100.0, 5, 0)
  let w1 = weight_at_rir(100.0, 5, 1)
  let w3 = weight_at_rir(100.0, 5, 3)
  assert_eq(w0 > w1 && w1 > w3, true)
  expect_near(w0, 100.0 / (1.0 + 5.0 / 30.0))
}

///|
test "weight_at_rpe 与 weight_at_rir 一致" {
  expect_near(weight_at_rpe(100.0, 5, 8.0), weight_at_rir(100.0, 5, 2))
}

///|
test "e1rm_from_set 计入余量" {
  // 余量越大，说明当前重量越轻松，反推 e1RM 越高
  let a = e1rm_from_set(100.0, 5, 0)
  let b = e1rm_from_set(100.0, 5, 2)
  assert_eq(b > a, true)
  expect_near(a, 100.0 * (1.0 + 5.0 / 30.0))
  expect_near(b, 100.0 * (1.0 + 7.0 / 30.0))
}

///|
test "RPE 越界时报错" {
  try ignore(pct_from_rpe(11.0)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
  try ignore(rir_from_rpe(-1.0)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
  try ignore(rpe_from_rir(-1)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
}

///|
test "RIR 为负时报错" {
  try ignore(weight_at_rir(100.0, 5, -1)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
  try ignore(e1rm_from_set(100.0, 5, -2)) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
}
