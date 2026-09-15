# MathLib -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

MathLib :: [].{

	int_widen : I64 -> I64
	int_widen = |n| n

	square : I64 -> I64
	square = |x| (x * x)

	cube : I64 -> I64
	cube = |x| ((x * x) * x)

	helper : I64 -> I64
	helper = |x| (x + 1)

	math_abs : I64 -> I64
	math_abs = |n| (if (n < 0) { (-n) } else { n })

	math_min : I64, I64 -> I64
	math_min = |a, b| (if (a < b) { a } else { b })

	math_max : I64, I64 -> I64
	math_max = |a, b| (if (a > b) { a } else { b })

	math_clamp : I64, I64, I64 -> I64
	math_clamp = |lo, hi, v| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	math_mod : I64, I64 -> I64
	math_mod = |a, b| (a - (I64.div_trunc_by(a, b) * b))

	math_isqrt : I64 -> I64
	math_isqrt = |n| (if (n <= 0) { 0 } else { math_isqrt_loop(n, (I64.div_trunc_by(n, 2) + 1)) })

	math_isqrt_loop : I64, I64 -> I64
	math_isqrt_loop = |n, guess| ({
		next = I64.div_trunc_by((guess + I64.div_trunc_by(n, guess)), 2)
		(if (next >= guess) { guess } else { math_isqrt_loop(n, next) })
	})
}
