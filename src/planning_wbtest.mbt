///|
/// 按 2 位小数精度比较浮点数的测试辅助函数。
fn assert_near(actual : Double, expected : Double) -> Unit raise {
  // 四舍五入到 2 位小数，避免截断在边界值上产生假失败
  let a = (actual * 100.0 + 0.5).floor().to_int()
  let b = (expected * 100.0 + 0.5).floor().to_int()
  assert_eq(a, b)
}

///|
/// 断言表达式应当抛出错误；若未抛出则测试失败。
fn[T] expect_error(f : () -> T raise) -> Unit raise {
  try ignore(f()) catch {
    _ => ()
  } noraise {
    _ => assert_eq("应当报错", "但没有报错")
  }
}

// ---------- 容量与强度 ----------

///|
test "单组与总容量负荷" {
  assert_near(set_volume(100.0, 5), 500.0)
  let sets = [
    { weight: 100.0, reps: 5, rir: 2, },
    { weight: 90.0, reps: 8, rir: 1, },
  ]
  assert_near(total_volume(sets), 1220.0)
}

///|
test "有效次数只统计接近力竭的部分" {
  assert_eq(stimulating_reps(5, 0), 5)
  assert_eq(stimulating_reps(8, 1), 4)
  assert_eq(stimulating_reps(5, 3), 2)
  assert_eq(stimulating_reps(3, 2), 3)
  // 距离力竭 5 次以上不产生有效刺激
  assert_eq(stimulating_reps(10, 5), 0)
  assert_eq(stimulating_reps(10, 9), 0)
}

///|
test "多组有效次数求和" {
  let sets = [
    { weight: 100.0, reps: 5, rir: 0, },
    { weight: 90.0, reps: 8, rir: 3, },
  ]
  // 5 + min(8, 2) = 7
  assert_eq(total_stimulating_reps(sets), 7)
}

///|
test "INOL 疲劳指标" {
  // 5 次 @ 80% => 5 / (100 - 80) = 0.25
  assert_near(inol(5, 0.80), 0.25)
  // 强度越高疲劳成本上升越快：3 次 @ 95% => 3 / 5 = 0.6
  assert_near(inol(3, 0.95), 0.6)
}

///|
test "总 INOL 与平均强度" {
  let sets = [
    { weight: 80.0, reps: 5, rir: 2, },
    { weight: 90.0, reps: 3, rir: 1, },
  ]
  // 0.8 -> 5/20 = 0.25 ; 0.9 -> 3/10 = 0.3
  assert_near(total_inol(sets, 100.0), 0.55)
  assert_near(average_intensity(sets, 100.0), 0.85)
}

///|
test "训练密度反映平均每次的重量" {
  let sets = [
    { weight: 100.0, reps: 5, rir: 0, },
    { weight: 80.0, reps: 5, rir: 0, },
  ]
  // (500 + 400) / 10 = 90
  assert_near(training_density(sets), 90.0)
}

///|
test "容量相关错误路径" {
  expect_error(fn() raise { set_volume(-1.0, 5) })
  expect_error(fn() raise { set_volume(100.0, 0) })
  expect_error(fn() raise { inol(5, 1.2) })
  expect_error(fn() raise { inol(0, 0.8) })
  expect_error(fn() raise { stimulating_reps(5, -1) })
  let empty : Array[SetRecord] = []
  expect_error(fn() raise { total_inol(empty, 0.0) })
  expect_error(fn() raise { average_intensity(empty, 100.0) })
  expect_error(fn() raise { training_density(empty) })
}

// ---------- 身体与营养 ----------

///|
test "BMI 计算" {
  // 70 / 1.75^2 = 22.86
  assert_near(bmi(70.0, 175.0), 22.86)
}

///|
test "BMR 与 TDEE（Mifflin-St Jeor）" {
  // 男 80kg 180cm 30岁：800 + 1125 - 150 + 5 = 1780
  assert_near(bmr(MifflinStJeor, Male, 80.0, 180.0, 30, 0.0), 1780.0)
  // 女：800 + 1125 - 150 - 161 = 1614
  assert_near(bmr(MifflinStJeor, Female, 80.0, 180.0, 30, 0.0), 1614.0)
  // 中度活动系数 1.55
  assert_near(tdee(MifflinStJeor, Male, 80.0, 180.0, 30, 0.0, Moderate), 2759.0)
}

///|
test "Katch-McArdle 需要体脂率" {
  // 去脂体重 = 80 * (1 - 0.2) = 64；370 + 21.6 * 64 = 1752.4
  assert_near(bmr(KatchMcArdle, Male, 80.0, 180.0, 30, 0.20), 1752.4)
}

///|
test "活动系数与 BMR 公式全覆盖" {
  assert_near(activity_factor(Sedentary), 1.2)
  assert_near(activity_factor(Light), 1.375)
  assert_near(activity_factor(Moderate), 1.55)
  assert_near(activity_factor(Active), 1.725)
  assert_near(activity_factor(VeryActive), 1.9)
  // 三种 BMR 公式都应落在合理量级
  let a = bmr(MifflinStJeor, Male, 80.0, 180.0, 30, 0.0)
  let b = bmr(HarrisBenedict, Male, 80.0, 180.0, 30, 0.0)
  let c = bmr(KatchMcArdle, Male, 80.0, 180.0, 30, 0.20)
  assert_eq(a > 1000.0 && a < 3000.0, true)
  assert_eq(b > 1000.0 && b < 3000.0, true)
  assert_eq(c > 1000.0 && c < 3000.0, true)
}

///|
test "TDEE 覆盖全部活动水平" {
  let base = bmr(MifflinStJeor, Male, 80.0, 180.0, 30, 0.0)
  assert_near(
    tdee(MifflinStJeor, Male, 80.0, 180.0, 30, 0.0, Sedentary),
    base * 1.2,
  )
  assert_near(
    tdee(MifflinStJeor, Male, 80.0, 180.0, 30, 0.0, Light),
    base * 1.375,
  )
  assert_near(
    tdee(MifflinStJeor, Male, 80.0, 180.0, 30, 0.0, Active),
    base * 1.725,
  )
  assert_near(
    tdee(MifflinStJeor, Male, 80.0, 180.0, 30, 0.0, VeryActive),
    base * 1.9,
  )
}

///|
test "宏量营养素按目标分配" {
  let bulk = macro_plan(Hypertrophy, 80.0, 2500.0)
  // 热量 +400，蛋白 1.8 g/kg
  assert_near(bulk.calories, 2900.0)
  assert_near(bulk.protein_g, 144.0)
  let cut = macro_plan(FatLoss, 80.0, 2500.0)
  assert_near(cut.calories, 2000.0)
  assert_near(cut.protein_g, 176.0)
  let maint = macro_plan(Maintenance, 80.0, 2500.0)
  assert_near(maint.calories, 2500.0)
  // 三大宏量折算回热量应接近目标值
  let back = maint.protein_g * 4.0 + maint.fat_g * 9.0 + maint.carb_g * 4.0
  assert_near(back, 2500.0)
}

///|
test "极低热量时宏量计划有下限保护" {
  // 维持热量极低时不应算出负热量
  let p = macro_plan(FatLoss, 50.0, 1000.0)
  assert_eq(p.calories >= 1200.0, true)
  assert_eq(p.carb_g >= 0.0, true)
}

///|
test "体脂率与 FFMI" {
  let bf = body_fat_deurenberg(Male, 80.0, 180.0, 30)
  // BMI 24.691 => 1.2*24.691 + 6.9 - 10.8 - 5.4 = 20.33
  assert_near(bf, 0.2033)
  let f = ffmi(80.0, 180.0, bf, false)
  // 去脂 63.74 / 3.24 = 19.67
  assert_near(f, 19.67)
  // 身高 1.8m 时归一化修正为 0
  assert_near(ffmi(80.0, 180.0, bf, true), 19.67)
  // 身高低于 1.8m 时归一化 FFMI 高于原始值
  let short_raw = ffmi(80.0, 160.0, bf, false)
  let short_norm = ffmi(80.0, 160.0, bf, true)
  assert_eq(short_norm > short_raw, true)
}

///|
test "女性体脂率高于同 BMI 男性" {
  let m = body_fat_deurenberg(Male, 80.0, 180.0, 30)
  let f = body_fat_deurenberg(Female, 80.0, 180.0, 30)
  assert_eq(f > m, true)
}

///|
test "相对力量" {
  assert_near(relative_strength(150.0, 75.0), 2.0)
}

///|
test "身体参数错误路径" {
  expect_error(fn() raise { bmi(70.0, 0.0) })
  expect_error(fn() raise { bmi(0.0, 175.0) })
  expect_error(fn() raise { bmr(MifflinStJeor, Male, 80.0, 180.0, 0, 0.0) })
  expect_error(fn() raise { bmr(KatchMcArdle, Male, 80.0, 180.0, 30, 1.5) })
  expect_error(fn() raise { ffmi(80.0, 180.0, 1.5, false) })
  expect_error(fn() raise { macro_plan(Hypertrophy, 80.0, 0.0) })
  expect_error(fn() raise { relative_strength(0.0, 75.0) })
}

// ---------- 周期化模板 ----------

///|
test "5/3/1 第 1 周处方" {
  let s = five_three_one_sets(100.0, 1)
  assert_eq(s.length(), 3)
  assert_near(s[0].weight, 65.0)
  assert_near(s[1].weight, 75.0)
  assert_near(s[2].weight, 85.0)
  assert_eq(s[2].amrap, true)
  assert_eq(s[0].amrap, false)
}

///|
test "5/3/1 第 4 周为减载周" {
  let s = five_three_one_sets(100.0, 4)
  assert_near(s[0].weight, 40.0)
  assert_near(s[2].weight, 60.0)
  for i = 0; i < s.length(); i = i + 1 {
    assert_eq(s[i].amrap, false)
  }
}

///|
test "5/3/1 周期长度正确" {
  let c = five_three_one_cycle(100.0, 3)
  assert_eq(c.length(), 12)
  assert_eq(c[0].0, 1)
  assert_eq(c[4].0, 1)
}

///|
test "StrongLifts 5x5 线性加重" {
  let s0 = stronglifts_5x5(100.0, 0, 2.5)
  assert_eq(s0.length(), 5)
  assert_near(s0[0].weight, 100.0)
  let s2 = stronglifts_5x5(100.0, 2, 2.5)
  assert_near(s2[0].weight, 105.0)
}

///|
test "DUP 三种训练日" {
  assert_eq(dup_session(100.0, Heavy).length(), 3)
  assert_eq(dup_session(100.0, Medium).length(), 4)
  assert_eq(dup_session(100.0, Light).length(), 3)
  assert_near(dup_session(100.0, Heavy)[0].weight, 90.0)
  assert_near(dup_session(100.0, Medium)[0].weight, 77.0)
  assert_near(dup_session(100.0, Light)[0].weight, 65.0)
}

///|
test "配重取整" {
  // 87.3 向下取到 2.5 的倍数
  assert_near(round_to_plate(87.3, 2.5), 85.0)
  assert_near(round_to_plate(90.0, 2.5), 90.0)
}

///|
test "计划生成错误路径" {
  expect_error(fn() raise { five_three_one_sets(100.0, 5) })
  expect_error(fn() raise { five_three_one_sets(0.0, 1) })
  expect_error(fn() raise { five_three_one_cycle(100.0, 0) })
  expect_error(fn() raise { round_to_plate(100.0, 0.0) })
  expect_error(fn() raise { stronglifts_5x5(100.0, -1, 2.5) })
  expect_error(fn() raise { dup_session(-1.0, Heavy) })
}

// ---------- 自适应调整 ----------

///|
test "训练状态按表现判定" {
  assert_eq(performance_status(102.0, 100.0) == Fresh, true)
  assert_eq(performance_status(100.0, 100.0) == Normal, true)
  assert_eq(performance_status(95.0, 100.0) == Fatigued, true)
  assert_eq(performance_status(90.0, 100.0) == Overreached, true)
}

///|
test "下一个训练最大值由 AMRAP 表现校正" {
  // 95kg x5 力竭 => e1RM 110.83；候选 94.21，基线 102.5，取大后受 e1RM*0.9=99.75 限制
  assert_near(next_training_max(100.0, 95.0, 5, false), 99.75)
  // 只完成 1 次时 e1RM 仅 98.17，理论值 88.35，但受 10% 下降保护 => 90.0
  assert_near(next_training_max(100.0, 95.0, 1, true), 90.0)
  // 一次都没完成时保守推进
  assert_near(next_training_max(100.0, 95.0, 0, false), 101.25)
  // 表现远超预期（95kg x12）=> e1RM 133，候选 113.05 高于基线，取候选
  assert_near(next_training_max(100.0, 95.0, 12, false), 113.05)
}

///|
test "平台期检测" {
  assert_eq(detect_plateau([100.0, 100.0, 100.0, 100.0], 4, 0.02), true)
  assert_eq(detect_plateau([100.0, 105.0, 110.0, 115.0], 4, 0.02), false)
  // 历史不足一个窗口时不判定
  assert_eq(detect_plateau([100.0, 100.0], 4, 0.02), false)
}

///|
test "减载建议按规则触发" {
  assert_eq(suggest_deload(6, 0.70, false, 10).needed, true)
  assert_eq(suggest_deload(3, 0.70, true, 10).needed, true)
  assert_eq(suggest_deload(4, 0.90, false, 10).needed, true)
  assert_eq(suggest_deload(1, 0.70, false, 10).needed, false)
  // 平台但刚减载过不久，不重复触发
  assert_eq(suggest_deload(2, 0.70, true, 10).needed, false)
  let d = suggest_deload(6, 0.70, false, 10)
  assert_near(d.volume_multiplier, 0.5)
  assert_near(d.intensity_multiplier, 0.7)
}

///|
test "自主调节按 RIR 差异调整负荷" {
  // 比目标轻松 1 次 => 加重 2.5%
  assert_near(autoregulate_load(100.0, 2, 3), 102.5)
  // 比目标吃力 2 次 => 减重 5%
  assert_near(autoregulate_load(100.0, 2, 0), 95.0)
  // 恰好达标 => 不变
  assert_near(autoregulate_load(100.0, 2, 2), 100.0)
}

///|
test "容量调整系数随状态变化" {
  assert_near(volume_adjustment(Fresh), 1.1)
  assert_near(volume_adjustment(Normal), 1.0)
  assert_near(volume_adjustment(Fatigued), 0.85)
  assert_near(volume_adjustment(Overreached), 0.6)
}

///|
test "自适应相关错误路径" {
  expect_error(fn() raise { performance_status(100.0, 0.0) })
  expect_error(fn() raise { performance_status(0.0, 100.0) })
  expect_error(fn() raise { detect_plateau([100.0, 100.0], 1, 0.02) })
  expect_error(fn() raise { detect_plateau([100.0, 100.0], 2, -1.0) })
  expect_error(fn() raise { autoregulate_load(100.0, -1, 2) })
  expect_error(fn() raise { autoregulate_load(0.0, 2, 2) })
  expect_error(fn() raise { next_training_max(100.0, -5.0, 5, false) })
  expect_error(fn() raise { next_training_max(0.0, 95.0, 5, false) })
  expect_error(fn() raise { suggest_deload(-1, 0.7, false, 10) })
  expect_error(fn() raise { suggest_deload(2, 2.0, false, 10) })
}
