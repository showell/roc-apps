# Saturate -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Saturate :: [].{

	sat_add : I64, I64, I64, I64 -> I64
	sat_add = |lo, hi, a, b| ({
		r : I64
		r = (a + b)
		(if (r < lo) { lo } else { (if (r > hi) { hi } else { r }) })
	})

	sat_sub : I64, I64, I64, I64 -> I64
	sat_sub = |lo, hi, a, b| ({
		r : I64
		r = (a - b)
		(if (r < lo) { lo } else { (if (r > hi) { hi } else { r }) })
	})

	sat_mul : I64, I64, I64, I64 -> I64
	sat_mul = |lo, hi, a, b| ({
		r : I64
		r = (a * b)
		(if (r < lo) { lo } else { (if (r > hi) { hi } else { r }) })
	})

	sat_add_u8 : I64, I64 -> I64
	sat_add_u8 = |a, b| ({
		r : I64
		r = (a + b)
		(if (r > 255) { 255 } else { (if (r < 0) { 0 } else { r }) })
	})

	sat_sub_u8 : I64, I64 -> I64
	sat_sub_u8 = |a, b| ({
		r : I64
		r = (a - b)
		(if (r < 0) { 0 } else { r })
	})

	sat_add_u16 : I64, I64 -> I64
	sat_add_u16 = |a, b| ({
		r : I64
		r = (a + b)
		(if (r > 65535) { 65535 } else { (if (r < 0) { 0 } else { r }) })
	})

	sat_sub_u16 : I64, I64 -> I64
	sat_sub_u16 = |a, b| ({
		r : I64
		r = (a - b)
		(if (r < 0) { 0 } else { r })
	})
}
