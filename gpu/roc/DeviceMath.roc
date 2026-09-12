# DeviceMath -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

DeviceMath :: [].{

	real_min : F32, F32 -> F32
	real_min = |a, b| (if (a < b) { a } else { b })

	real_max : F32, F32 -> F32
	real_max = |a, b| (if (a > b) { a } else { b })

	real_abs : F32 -> F32
	real_abs = |x| (if (x < 0.0) { (0.0 - x) } else { x })

	real_sqrt : F32 -> F32
	real_sqrt = |x| (if (x <= 0.0) { 0.0 } else { dm_sqrt_scaled(x, 1.0, 700) })

	dm_sqrt_scaled : F32, F32, I32 -> F32
	dm_sqrt_scaled = |x, s, fuel| (if (fuel <= 0) { (s * dm_sqrt_core(x)) } else { (if (x >= 4.0) { dm_sqrt_scaled((x / 4.0), (s * 2.0), I32.minus_wrap(fuel, 1)) } else { (if (x < 0.25) { dm_sqrt_scaled((x * 4.0), (s * 0.5), I32.minus_wrap(fuel, 1)) } else { (s * dm_sqrt_core(x)) }) }) })

	dm_sqrt_core : F32 -> F32
	dm_sqrt_core = |r| ({
		g0 = ((r + 1.0) * 0.5)
		g1 = ((g0 + (r / g0)) * 0.5)
		g2 = ((g1 + (r / g1)) * 0.5)
		g3 = ((g2 + (r / g2)) * 0.5)
		g4 = ((g3 + (r / g3)) * 0.5)
		((g4 + (r / g4)) * 0.5)
	})

	dm_two_pi : F32
	dm_two_pi = 6.2831855

	dm_pi : F32
	dm_pi = 3.1415927

	dm_half_pi : F32
	dm_half_pi = 1.5707964

	dm_reduce : F32 -> F32
	dm_reduce = |x| ({
		k = I32.to_f32(F32.to_i32_wrap((x / dm_two_pi)))
		r = (x - (k * dm_two_pi))
		(if (r > dm_pi) { (r - dm_two_pi) } else { (if (r < (0.0 - dm_pi)) { (r + dm_two_pi) } else { r }) })
	})

	dm_quarter_pi : F32
	dm_quarter_pi = 0.7853982

	dm_three_quarter_pi : F32
	dm_three_quarter_pi = 2.3561945

	dm_sin_poly : F32 -> F32
	dm_sin_poly = |r| ({
		r2 = (r * r)
		r3 = (r2 * r)
		r5 = (r3 * r2)
		r7 = (r5 * r2)
		r9 = (r7 * r2)
		r11 = (r9 * r2)
		r13 = (r11 * r2)
		r15 = (r13 * r2)
		(((((((r - (r3 / 6.0)) + (r5 / 120.0)) - (r7 / 5040.0)) + (r9 / 362880.0)) - (r11 / 39916800.0)) + (r13 / 6227021000.0)) - (r15 / 1307674400000.0))
	})

	dm_cos_poly : F32 -> F32
	dm_cos_poly = |r| ({
		r2 = (r * r)
		r4 = (r2 * r2)
		r6 = (r4 * r2)
		r8 = (r6 * r2)
		r10 = (r8 * r2)
		r12 = (r10 * r2)
		r14 = (r12 * r2)
		r16 = (r14 * r2)
		((((((((1.0 - (r2 / 2.0)) + (r4 / 24.0)) - (r6 / 720.0)) + (r8 / 40320.0)) - (r10 / 3628800.0)) + (r12 / 479001600.0)) - (r14 / 87178290000.0)) + (r16 / 20922790000000.0))
	})

	dm_sin_octant : F32 -> F32
	dm_sin_octant = |a| (if (a <= dm_quarter_pi) { dm_sin_poly(a) } else { (if (a <= dm_three_quarter_pi) { dm_cos_poly((a - dm_half_pi)) } else { dm_sin_poly((dm_pi - a)) }) })

	dm_cos_octant : F32 -> F32
	dm_cos_octant = |a| (if (a <= dm_quarter_pi) { dm_cos_poly(a) } else { (if (a <= dm_three_quarter_pi) { dm_sin_poly((dm_half_pi - a)) } else { (0.0 - dm_cos_poly((dm_pi - a))) }) })

	real_sin : F32 -> F32
	real_sin = |x| ({
		r = dm_reduce(x)
		(if (r < 0.0) { (0.0 - dm_sin_octant((0.0 - r))) } else { dm_sin_octant(r) })
	})

	real_cos : F32 -> F32
	real_cos = |x| dm_cos_octant(real_abs(dm_reduce(x)))

	dm_atan_half_step : F32 -> F32
	dm_atan_half_step = |t| (t / (1.0 + real_sqrt((1.0 + (t * t)))))

	dm_atan_halve : F32, I32 -> F32
	dm_atan_halve = |t, n| (if (n <= 0) { t } else { dm_atan_halve(dm_atan_half_step(t), I32.minus_wrap(n, 1)) })

	dm_atan_series : F32 -> F32
	dm_atan_series = |u| ({
		u2 = (u * u)
		u3 = (u2 * u)
		u5 = (u3 * u2)
		u7 = (u5 * u2)
		u9 = (u7 * u2)
		u11 = (u9 * u2)
		(((((u - (u3 / 3.0)) + (u5 / 5.0)) - (u7 / 7.0)) + (u9 / 9.0)) - (u11 / 11.0))
	})

	dm_atan_core : F32 -> F32
	dm_atan_core = |t| (16.0 * dm_atan_series(dm_atan_halve(t, 4)))

	real_atan : F32 -> F32
	real_atan = |t| (if (t > 1.0) { (dm_half_pi - dm_atan_core((1.0 / t))) } else { (if (t < (0.0 - 1.0)) { ((0.0 - dm_half_pi) - dm_atan_core((1.0 / t))) } else { dm_atan_core(t) }) })

	real_atan2 : F32, F32 -> F32
	real_atan2 = |y, x| (if (x > 0.0) { real_atan((y / x)) } else { (if (x < 0.0) { (if (y >= 0.0) { (real_atan((y / x)) + dm_pi) } else { (real_atan((y / x)) - dm_pi) }) } else { (if (y > 0.0) { dm_half_pi } else { (if (y < 0.0) { (0.0 - dm_half_pi) } else { 0.0 }) }) }) })
}
