# Prelude -- what no chapter declares, written by rocemit. Do not edit.

Prelude :: [].{
	Maybe(a) : [None, Just(a)]

	# **`~=` IS FOUR ULPs APART, NOT A TOLERANCE.** Codex compares the
	# ORDINAL of the two doubles -- the bit pattern read as a signed
	# integer, with the negatives reflected so the order is monotone --
	# and answers True when they are within four steps of each other.
	# That is a distance in representable numbers, so it is as tight near
	# zero as it is near 1e300, which no epsilon is (interp.rs `ordinal`).
	# **A REAL PRINTS AS CODEX'S OWN PRINTER PRINTS IT**, which is not
	# Rust's Display and not the shortest round-trip: the integer part in
	# full from a truncation to i64, then a point, then the fraction
	# truncated to fifteen digits with trailing zeros dropped and at
	# least one kept. `4000.0`, `0.416666666666666`, `1.5`. The verdicts
	# in codex/test are what this is checked against; our Rust
	# interpreter prints Rust's way and disagrees with them, which is a
	# bug on that side and the reason this is written from the verdicts.
	real_to_str : F64 -> Str
	real_to_str = |f|
		if F64.is_nan(f) { "NaN" }
		else if F64.is_infinite(f) { if f < 0.0 { "-inf" } else { "inf" } }
		else {
			neg = f < 0.0
			a = F64.abs(f)
			ip = F64.to_i64_wrap(a)
			frac = a - I64.to_f64(ip)
			digits = Prelude.frac_digits(frac, 15, [])
			body = Str.concat(Str.concat(I64.to_str(ip), "."), Prelude.digits_str(Prelude.trim_zeros(digits)))
			if neg { Str.concat("-", body) } else { body }
		}

	# The fraction's digits, most significant first, by taking one at a
	# time; `n` bounds it at the width Codex's printer carries.
	frac_digits : F64, I64, List(I64) -> List(I64)
	frac_digits = |frac, n, acc|
		if n <= 0 { acc } else {
			scaled = frac * 10.0
			d = F64.to_i64_wrap(scaled)
			Prelude.frac_digits(scaled - I64.to_f64(d), n - 1, List.append(acc, d))
		}

	# Trailing zeros go, but a real always shows a fraction digit.
	trim_zeros : List(I64) -> List(I64)
	trim_zeros = |ds|
		match List.last(ds) {
			Ok(0) => if List.len(ds) <= 1 { ds } else { Prelude.trim_zeros(List.drop_last(ds, 1)) }
			_ => ds
		}

	digits_str : List(I64) -> Str
	digits_str = |ds| List.fold(ds, "", |acc, d| Str.concat(acc, I64.to_str(d)))

	ordinal : F64 -> I64
	ordinal = |f| {
		b = U64.to_i64_wrap(F64.to_bits(f))
		if b < 0 { I64.plus_wrap(I64.bitwise_xor(b, 9223372036854775807), 1) } else { b }
	}

	approx_eq : F64, F64 -> Bool
	approx_eq = |x, y| I64.abs(I64.minus_wrap(Prelude.ordinal(x), Prelude.ordinal(y))) <= 4

	# `ordinal` and `approx_eq` over an f32's bits: `~` on a `Real
	# approximate` counts f32 units.
	ordinal32 : F32 -> I64
	ordinal32 = |f| {
		b = I32.to_i64(U32.to_i32_wrap(F32.to_bits(f)))
		if b < 0 { I64.plus_wrap(I64.bitwise_xor(b, 2147483647), 1) } else { b }
	}

	approx_eq32 : F32, F32 -> Bool
	approx_eq32 = |x, y| I64.abs(I64.minus_wrap(Prelude.ordinal32(x), Prelude.ordinal32(y))) <= 4

	# A `saturating` Real answers the largest finite value for an infinity and
	# 0 for NaN; a `trapping` one traps on either (codex/test's
	# ops/real-saturating, real-approx-modes).
	sat_f64 : F64 -> F64
	sat_f64 = |x| if F64.is_nan(x) { 0.0 } else if F64.is_infinite(x) { if x > 0.0 { F64.from_bits(9218868437227405311) } else { F64.from_bits(18442240474082181119) } } else { x }

	sat_f32 : F32 -> F32
	sat_f32 = |x| if F32.is_nan(x) { F32.from_bits(0) } else if F32.is_infinite(x) { if x > F32.from_bits(0) { F32.from_bits(2139095039) } else { F32.from_bits(4286578687) } } else { x }

	trap_f64 : F64 -> F64
	trap_f64 = |x| if F64.is_finite(x) { x } else { crash("a trapping Real left the finite range") }

	trap_f32 : F32 -> F32
	trap_f32 = |x| if F32.is_finite(x) { x } else { crash("a trapping Real left the finite range") }

	# `a ^ b` with a negative exponent is 0, where Roc's pow crashes
	# (codex/test's ops/int-pow: `ipow 5 (0 - 2)` is 0).
	int_pow : I64, I64 -> I64
	int_pow = |a, b| if b < 0 { 0 } else { I64.pow(a, b) }

	# `base` with `pushed` appended last to first: the list a definition builds
	# by pushing onto its own recursive call, which rocemit writes as a loop
	# that gathers the pushed elements outermost first.
	push_backwards : List(a), List(a) -> List(a)
	push_backwards = |base, pushed| {
		var $out = base
		var $i = List.len(pushed)
		while $i > 0 {
			$i = $i - 1
			$out = List.append($out, List.get(pushed, $i) ?? crash("Prelude: an index outside a list"))
		}
		$out
	}

	# x86's abs negates with a wrapping neg: the most negative integer answers itself.
	int_abs : I64 -> I64
	int_abs = |a| if a < 0 { I64.minus_wrap(0, a) } else { a }

	int_mod : I64, I64 -> I64
	int_mod = |a, b| {
		m = I64.mod_by(a, b)
		if m < 0 { m + I64.abs(b) } else { m }
	}
}
