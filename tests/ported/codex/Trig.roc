# Trig -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Trig :: [].{

	trig_normalize : I64 -> I64
	trig_normalize = |mdeg| ({
		m = (mdeg - (I64.div_trunc_by(mdeg, 360000) * 360000))
		(if (m < 0) { (m + 360000) } else { m })
	})

	fast_sin : I64 -> I64
	fast_sin = |mdeg| ({
		a = trig_normalize(mdeg)
		flip = (a >= 180000)
		b = (if flip { (a - 180000) } else { a })
		num = ((4 * b) * (180000 - b))
		den = (40500000000 - (b * (180000 - b)))
		r = I64.div_trunc_by((num * 10000), den)
		(if flip { (0 - r) } else { r })
	})

	fast_cos : I64 -> I64
	fast_cos = |mdeg| fast_sin((mdeg + 90000))

	fast_sin_cos_sum : I64 -> I64
	fast_sin_cos_sum = |mdeg| (fast_sin(mdeg) + fast_cos(mdeg))

	deg_to_mrad : I64 -> I64
	deg_to_mrad = |mdeg| I64.div_trunc_by((mdeg * 1745), 100000)

	mrad_to_deg : I64 -> I64
	mrad_to_deg = |mrad| I64.div_trunc_by((mrad * 100000), 1745)
}
