# Prelude -- what no chapter declares, written by rocemit. Do not edit.

Prelude :: [].{
	Maybe(a) : [None, Just(a)]

	int_mod : I64, I64 -> I64
	int_mod = |a, b| {
		m = I64.mod_by(a, b)
		if m < 0 { m + I64.abs(b) } else { m }
	}
}
