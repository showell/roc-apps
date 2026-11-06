# DeviceMath -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).

DeviceMath :: [].{

	real_sqrt : F64 -> F64
	real_sqrt = |x| (
		if x <= 0.0 {
			0.0
		} else {
			dm_sqrt_scaled(x, 1.0, 700)
		}
	)

	dm_sqrt_scaled : F64, F64, I64 -> F64
	dm_sqrt_scaled = |x, s, fuel| (
		if fuel <= 0 {
			(s * dm_sqrt_core(x))
		} else {
			(
				if x >= 4.0 {
					dm_sqrt_scaled((x / 4.0), (s * 2.0), (fuel - 1))
				} else {
					(
						if x < 0.25 {
							dm_sqrt_scaled((x * 4.0), (s * 0.5), (fuel - 1))
						} else {
							(s * dm_sqrt_core(x))
						}
					)
				}
			)
		}
	)

	dm_sqrt_core : F64 -> F64
	dm_sqrt_core = |r| (
		{
			g0 = ((r + 1.0) * 0.5)
			g1 = ((g0 + (r / g0)) * 0.5)
			g2 = ((g1 + (r / g1)) * 0.5)
			g3 = ((g2 + (r / g2)) * 0.5)
			g4 = ((g3 + (r / g3)) * 0.5)
			((g4 + (r / g4)) * 0.5)
		}
	)

	dm_half_pi : F64
	dm_half_pi = 1.570796326794897

	dm_atan_half_step : F64 -> F64
	dm_atan_half_step = |t| (t / (1.0 + real_sqrt((1.0 + (t * t)))))

	dm_atan_halve : F64, I64 -> F64
	dm_atan_halve = |t, n| (
		if n <= 0 {
			t
		} else {
			dm_atan_halve(dm_atan_half_step(t), (n - 1))
		}
	)

	dm_atan_series : F64 -> F64
	dm_atan_series = |u| (
		{
			u2 = (u * u)
			u3 = (u2 * u)
			u5 = (u3 * u2)
			u7 = (u5 * u2)
			u9 = (u7 * u2)
			u11 = (u9 * u2)
			(((((u - (u3 / 3.0)) + (u5 / 5.0)) - (u7 / 7.0)) + (u9 / 9.0)) - (u11 / 11.0))
		}
	)

	dm_atan_core : F64 -> F64
	dm_atan_core = |t| (16.0 * dm_atan_series(dm_atan_halve(t, 4)))

	real_atan : F64 -> F64
	real_atan = |t| (
		if t > 1.0 {
			(dm_half_pi - dm_atan_core((1.0 / t)))
		} else {
			(
				if t < (0.0 - 1.0) {
					((0.0 - dm_half_pi) - dm_atan_core((1.0 / t)))
				} else {
					dm_atan_core(t)
				}
			)
		}
	)

	real_atan2 : F64, F64 -> F64
	real_atan2 = |y, x| (
		if x > 0.0 {
			real_atan((y / x))
		} else {
			(
				if x < 0.0 {
					(
						if y >= 0.0 {
							(real_atan((y / x)) + F64.pi)
						} else {
							(real_atan((y / x)) - F64.pi)
						}
					)
				} else {
					(
						if y > 0.0 {
							dm_half_pi
						} else {
							(
								if y < 0.0 {
									(0.0 - dm_half_pi)
								} else {
									0.0
								}
							)
						}
					)
				}
			)
		}
	)
}
