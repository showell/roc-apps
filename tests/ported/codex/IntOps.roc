# IntOps -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

IntOps :: [].{

	int_abs : I64 -> I64
	int_abs = |n| (if (n < 0) { (0 - n) } else { n })

	int_sign : I64 -> I64
	int_sign = |n| (if (n < 0) { (0 - 1) } else { (if (n > 0) { 1 } else { 0 }) })

	int_min : I64, I64 -> I64
	int_min = |a, b| (if (a < b) { a } else { b })

	int_max : I64, I64 -> I64
	int_max = |a, b| (if (a > b) { a } else { b })

	int_clamp : I64, I64, I64 -> I64
	int_clamp = |lo, hi, v| (if (v < lo) { lo } else { (if (v > hi) { hi } else { v }) })

	is_even : I64 -> Bool
	is_even = |n| (I64.bitwise_and(n, 1) == 0)

	is_odd : I64 -> Bool
	is_odd = |n| (I64.bitwise_and(n, 1) == 1)

	is_positive : I64 -> Bool
	is_positive = |n| (n > 0)

	is_negative : I64 -> Bool
	is_negative = |n| (n < 0)

	is_zero : I64 -> Bool
	is_zero = |n| (n == 0)
}
