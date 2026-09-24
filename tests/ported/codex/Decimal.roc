# Decimal -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText

Decimal :: [].{
	Decimal : { dec_mantissa : I64, dec_scale : I64 }

	dec_max_scale_digits : I64
	dec_max_scale_digits = 18

	dec_clamp_scale : I64 -> I64
	dec_clamp_scale = |n| (if (n < 0) { 0 } else { (if (n > dec_max_scale_digits) { dec_max_scale_digits } else { n }) })

	dec_new : I64, I64 -> Decimal.Decimal
	dec_new = |mantissa, scale| { dec_mantissa: mantissa, dec_scale: scale }

	dec_zero : Decimal.Decimal
	dec_zero = { dec_mantissa: 0, dec_scale: 2 }

	dec_one : I64 -> Decimal.Decimal
	dec_one = |scale| { dec_mantissa: dec_pow10(scale), dec_scale: scale }

	dec_from_int : I64, I64 -> Decimal.Decimal
	dec_from_int = |n, scale| { dec_mantissa: (n * dec_pow10(scale)), dec_scale: scale }

	dec_from_parts : I64, I64, I64 -> Decimal.Decimal
	dec_from_parts = |whole, frac, scale| { dec_mantissa: ((whole * dec_pow10(scale)) + frac), dec_scale: scale }

	dec_add : Decimal.Decimal, Decimal.Decimal -> Decimal.Decimal
	dec_add = |a, b| ({
		s = dec_max_scale(a, b)
		ma = dec_promote(a, s)
		mb = dec_promote(b, s)
		{ dec_mantissa: (ma + mb), dec_scale: s }
	})

	dec_sub : Decimal.Decimal, Decimal.Decimal -> Decimal.Decimal
	dec_sub = |a, b| ({
		s = dec_max_scale(a, b)
		ma = dec_promote(a, s)
		mb = dec_promote(b, s)
		{ dec_mantissa: (ma - mb), dec_scale: s }
	})

	dec_mul : Decimal.Decimal, Decimal.Decimal -> Decimal.Decimal
	dec_mul = |a, b| ({
		raw = (a.dec_mantissa * b.dec_mantissa)
		combined_scale = (a.dec_scale + b.dec_scale)
		kept = dec_clamp_scale(combined_scale)
		excess = (combined_scale - kept)
		{ dec_mantissa: (if (excess > dec_max_scale_digits) { 0 } else { I64.div_trunc_by(raw, dec_pow10(excess)) }), dec_scale: kept }
	})

	dec_div : Decimal.Decimal, Decimal.Decimal -> Decimal.Decimal
	dec_div = |a, b| (if (b.dec_mantissa == 0) { { dec_mantissa: 0, dec_scale: a.dec_scale } } else { ({
		s = dec_max_scale(a, b)
		ma = dec_promote(a, s)
		mb = dec_promote(b, s)
		{ dec_mantissa: I64.div_trunc_by((ma * dec_pow10(s)), mb), dec_scale: s }
	}) })

	dec_negate : Decimal.Decimal -> Decimal.Decimal
	dec_negate = |d| { dec_mantissa: (0 - d.dec_mantissa), dec_scale: d.dec_scale }

	dec_abs : Decimal.Decimal -> Decimal.Decimal
	dec_abs = |d| { dec_mantissa: (if (d.dec_mantissa < 0) { (0 - d.dec_mantissa) } else { d.dec_mantissa }), dec_scale: d.dec_scale }

	dec_compare : Decimal.Decimal, Decimal.Decimal -> I64
	dec_compare = |a, b| ({
		s = dec_max_scale(a, b)
		ma = dec_promote(a, s)
		mb = dec_promote(b, s)
		(if (ma < mb) { (0 - 1) } else { (if (ma > mb) { 1 } else { 0 }) })
	})

	dec_eq : Decimal.Decimal, Decimal.Decimal -> Bool
	dec_eq = |a, b| (dec_compare(a, b) == 0)

	dec_lt : Decimal.Decimal, Decimal.Decimal -> Bool
	dec_lt = |a, b| (dec_compare(a, b) < 0)

	dec_gt : Decimal.Decimal, Decimal.Decimal -> Bool
	dec_gt = |a, b| (dec_compare(a, b) > 0)

	dec_min : Decimal.Decimal, Decimal.Decimal -> Decimal.Decimal
	dec_min = |a, b| (if dec_lt(a, b) { a } else { b })

	dec_max : Decimal.Decimal, Decimal.Decimal -> Decimal.Decimal
	dec_max = |a, b| (if dec_gt(a, b) { a } else { b })

	dec_round : Decimal.Decimal, I64 -> Decimal.Decimal
	dec_round = |d, new_scale| (if (new_scale >= d.dec_scale) { d } else { ({
		factor = dec_pow10((d.dec_scale - new_scale))
		half = I64.div_trunc_by(factor, 2)
		adjusted = (if (d.dec_mantissa >= 0) { (d.dec_mantissa + half) } else { (d.dec_mantissa - half) })
		{ dec_mantissa: I64.div_trunc_by(adjusted, factor), dec_scale: new_scale }
	}) })

	dec_truncate : Decimal.Decimal, I64 -> Decimal.Decimal
	dec_truncate = |d, new_scale| (if (new_scale >= d.dec_scale) { d } else { ({
		factor = dec_pow10((d.dec_scale - new_scale))
		{ dec_mantissa: I64.div_trunc_by(d.dec_mantissa, factor), dec_scale: new_scale }
	}) })

	dec_floor : Decimal.Decimal -> Decimal.Decimal
	dec_floor = |d| dec_truncate(d, 0)

	dec_ceiling : Decimal.Decimal -> Decimal.Decimal
	dec_ceiling = |d| ({
		floored = dec_truncate(d, 0)
		(if (d.dec_mantissa > (floored.dec_mantissa * dec_pow10(d.dec_scale))) { { dec_mantissa: (floored.dec_mantissa + 1), dec_scale: 0 } } else { floored })
	})

	dec_to_text : Decimal.Decimal -> CceText
	dec_to_text = |d| (if (d.dec_scale == 0) { CceText.show_int(d.dec_mantissa) } else { ({
		abs_m = (if (d.dec_mantissa < 0) { (0 - d.dec_mantissa) } else { d.dec_mantissa })
		factor = dec_pow10(d.dec_scale)
		whole = I64.div_trunc_by(abs_m, factor)
		frac = (abs_m - (whole * factor))
		sign = (if (d.dec_mantissa < 0) { "-" } else { "" })
		CceText.concat(CceText.concat(CceText.concat(sign, CceText.show_int(whole)), "."), dec_pad_frac(frac, d.dec_scale))
	}) })

	dec_pad_frac : I64, I64 -> CceText
	dec_pad_frac = |frac, scale| ({
		raw = CceText.show_int(frac)
		padding = (scale - CceText.len(raw))
		(if (padding <= 0) { raw } else { CceText.concat(dec_repeat_zero(padding, ""), raw) })
	})

	dec_repeat_zero : I64, CceText -> CceText
	dec_repeat_zero = |n, acc| (if (n <= 0) { acc } else { dec_repeat_zero((n - 1), CceText.concat(acc, "0")) })

	dec_from_text : CceText, I64 -> Decimal.Decimal
	dec_from_text = |s, default_scale| ({
		dot = dec_find_dot(s, 0, CceText.len(s))
		(if (dot < 0) { { dec_mantissa: (CceText.to_integer(s) * dec_pow10(default_scale)), dec_scale: default_scale } } else { ({
			whole_str = CceText.substring(s, 0, dot)
			raw_frac = CceText.substring(s, (dot + 1), ((CceText.len(s) - dot) - 1))
			scale = dec_clamp_scale(CceText.len(raw_frac))
			frac_str = CceText.substring(raw_frac, 0, scale)
			whole = CceText.to_integer(whole_str)
			frac = CceText.to_integer(frac_str)
			sign = (if (whole < 0) { (0 - 1) } else { 1 })
			{ dec_mantissa: (sign * (((if (whole < 0) { (0 - whole) } else { whole }) * dec_pow10(scale)) + frac)), dec_scale: scale }
		}) })
	})

	dec_find_dot : CceText, I64, I64 -> I64
	dec_find_dot = |s, i, len| (if (i >= len) { (0 - 1) } else { (if (CceChar.code(CceText.char_at(s, i)) == 65) { i } else { dec_find_dot(s, (i + 1), len) }) })

	dec_whole_part : Decimal.Decimal -> I64
	dec_whole_part = |d| I64.div_trunc_by(d.dec_mantissa, dec_pow10(d.dec_scale))

	dec_frac_part : Decimal.Decimal -> I64
	dec_frac_part = |d| ({
		abs_m = (if (d.dec_mantissa < 0) { (0 - d.dec_mantissa) } else { d.dec_mantissa })
		(abs_m - (I64.div_trunc_by(abs_m, dec_pow10(d.dec_scale)) * dec_pow10(d.dec_scale)))
	})

	dec_is_zero : Decimal.Decimal -> Bool
	dec_is_zero = |d| (d.dec_mantissa == 0)

	dec_is_negative : Decimal.Decimal -> Bool
	dec_is_negative = |d| (d.dec_mantissa < 0)

	dec_pow10 : I64 -> I64
	dec_pow10 = |n| dec_pow10_loop(dec_clamp_scale(n), 1)

	dec_pow10_loop : I64, I64 -> I64
	dec_pow10_loop = |n, acc| (if (n <= 0) { acc } else { dec_pow10_loop((n - 1), (acc * 10)) })

	dec_max_scale : Decimal.Decimal, Decimal.Decimal -> I64
	dec_max_scale = |a, b| (if (a.dec_scale > b.dec_scale) { a.dec_scale } else { b.dec_scale })

	dec_promote : Decimal.Decimal, I64 -> I64
	dec_promote = |d, target_scale| (d.dec_mantissa * dec_pow10((target_scale - d.dec_scale)))
}
