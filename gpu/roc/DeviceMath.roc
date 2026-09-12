# DeviceMath -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

DeviceMath :: [].{

	real_min : F64, F64 -> F64
	real_min = |a, b| (if (a < b) { a } else { b })

	real_max : F64, F64 -> F64
	real_max = |a, b| (if (a > b) { a } else { b })

	real_abs : F64 -> F64
	real_abs = |x| (if (x < 0.0) { (0.0 - x) } else { x })

	real_sqrt : F64 -> F64
	real_sqrt = |x| (if (x <= 0.0) { 0.0 } else { dm_sqrt_scaled(x, 1.0, 700) })

	dm_sqrt_scaled : F64, F64, I64 -> F64
	dm_sqrt_scaled = |x, s, fuel| (if (fuel <= 0) { (s * dm_sqrt_core(x)) } else { (if (x >= 4.0) { dm_sqrt_scaled((x / 4.0), (s * 2.0), (fuel - 1)) } else { (if (x < 0.25) { dm_sqrt_scaled((x * 4.0), (s * 0.5), (fuel - 1)) } else { (s * dm_sqrt_core(x)) }) }) })

	dm_sqrt_core : F64 -> F64
	dm_sqrt_core = |r| ({
		g0 = ((r + 1.0) * 0.5)
		g1 = ((g0 + (r / g0)) * 0.5)
		g2 = ((g1 + (r / g1)) * 0.5)
		g3 = ((g2 + (r / g2)) * 0.5)
		g4 = ((g3 + (r / g3)) * 0.5)
		((g4 + (r / g4)) * 0.5)
	})

	dm_two_pi : F64
	dm_two_pi = 6.283185307179586

	dm_pi : F64
	dm_pi = 3.141592653589793

	dm_half_pi : F64
	dm_half_pi = 1.570796326794897

	dm_reduce : F64 -> F64
	dm_reduce = |x| ({
		k = I64.to_f64(F64.to_i64_wrap((x / dm_two_pi)))
		r = (x - (k * dm_two_pi))
		(if (r > dm_pi) { (r - dm_two_pi) } else { (if (r < (0.0 - dm_pi)) { (r + dm_two_pi) } else { r }) })
	})

	dm_fold_quadrant : F64 -> F64
	dm_fold_quadrant = |r| (if (r > dm_half_pi) { (dm_pi - r) } else { (if (r < (0.0 - dm_half_pi)) { ((0.0 - dm_pi) - r) } else { r }) })

	dm_sin_poly : F64 -> F64
	dm_sin_poly = |r| ({
		r2 = (r * r)
		r3 = (r2 * r)
		r5 = (r3 * r2)
		r7 = (r5 * r2)
		r9 = (r7 * r2)
		r11 = (r9 * r2)
		(((((r - (r3 / 6.0)) + (r5 / 120.0)) - (r7 / 5040.0)) + (r9 / 362880.0)) - (r11 / 39916800.0))
	})

	real_sin : F64 -> F64
	real_sin = |x| dm_sin_poly(dm_fold_quadrant(dm_reduce(x)))

	real_cos : F64 -> F64
	real_cos = |x| dm_sin_poly(dm_fold_quadrant(dm_reduce((x + dm_half_pi))))
}
