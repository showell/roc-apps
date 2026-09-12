# Wrap64 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Wrap64 :: [].{

	w64_mul : I64, I64 -> I64
	w64_mul = |a, b| I64.times_wrap(a, b)

	w64_add : I64, I64 -> I64
	w64_add = |a, b| I64.plus_wrap(a, b)

	w64_sub : I64, I64 -> I64
	w64_sub = |a, b| I64.minus_wrap(a, b)
}
