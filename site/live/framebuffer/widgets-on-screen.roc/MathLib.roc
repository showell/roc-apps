# MathLib -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

MathLib :: [].{

	math_min : I64, I64 -> I64
	math_min = |a, b| (if (a < b) { a } else { b })

	math_max : I64, I64 -> I64
	math_max = |a, b| (if (a > b) { a } else { b })

	math_isqrt : I64 -> I64
	math_isqrt = |n| (if (n <= 0) { 0 } else { math_isqrt_loop(n, (I64.div_trunc_by(n, 2) + 1)) })

	math_isqrt_loop : I64, I64 -> I64
	math_isqrt_loop = |n, guess| ({
		next : I64
		next = I64.div_trunc_by((guess + I64.div_trunc_by(n, guess)), 2)
		(if (next >= guess) { guess } else { math_isqrt_loop(n, next) })
	})
}
