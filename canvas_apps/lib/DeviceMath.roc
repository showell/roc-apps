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

}
