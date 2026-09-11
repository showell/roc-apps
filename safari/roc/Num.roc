# Num -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Num :: [].{

	round_real : F64 -> F64
	round_real = |x| ({
		t = I64.to_f64(F64.to_i64_wrap(x))
		f = (x - t)
		(if (f >= 0.5) { (t + 1.0) } else { (if (f <= (0.0 - 0.5)) { (t - 1.0) } else { t }) })
	})

	floor_real : F64 -> F64
	floor_real = |x| ({
		t = I64.to_f64(F64.to_i64_wrap(x))
		(if (t > x) { (t - 1.0) } else { t })
	})

	mod_real : F64, F64 -> F64
	mod_real = |x, m| (x - (m * floor_real((x / m))))

	ln2 : F64
	ln2 = 0.6931471805599453

	exp_poly : F64 -> F64
	exp_poly = |r| ({
		t1 = r
		t2 = ((t1 * r) / 2.0)
		t3 = ((t2 * r) / 3.0)
		t4 = ((t3 * r) / 4.0)
		t5 = ((t4 * r) / 5.0)
		t6 = ((t5 * r) / 6.0)
		t7 = ((t6 * r) / 7.0)
		t8 = ((t7 * r) / 8.0)
		t9 = ((t8 * r) / 9.0)
		t10 = ((t9 * r) / 10.0)
		t11 = ((t10 * r) / 11.0)
		t12 = ((t11 * r) / 12.0)
		((((((((((((1.0 + t1) + t2) + t3) + t4) + t5) + t6) + t7) + t8) + t9) + t10) + t11) + t12)
	})

	pow2_up : I64, F64 -> F64
	pow2_up = |k, acc| (if (k <= 0) { acc } else { pow2_up((k - 1), (acc * 2.0)) })

	pow2_down : I64, F64 -> F64
	pow2_down = |k, acc| (if (k >= 0) { acc } else { pow2_down((k + 1), (acc * 0.5)) })

	pow2_int : I64 -> F64
	pow2_int = |k| (if (k >= 0) { pow2_up(k, 1.0) } else { pow2_down(k, 1.0) })

	exp_real : F64 -> F64
	exp_real = |x| ({
		k = F64.to_i64_wrap(round_real((x / ln2)))
		(exp_poly((x - (I64.to_f64(k) * ln2))) * pow2_int(k))
	})

	ceil_real : F64 -> F64
	ceil_real = |x| (0.0 - floor_real((0.0 - x)))
}
