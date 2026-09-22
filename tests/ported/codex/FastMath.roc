# FastMath -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BitOps
import IntOps

FastMath :: [].{

	lerp : I64, I64, I64, I64 -> I64
	lerp = |a, b, num, den| (a + I64.div_trunc_by(((b - a) * num), den))

	inverse_lerp : I64, I64, I64, I64 -> I64
	inverse_lerp = |a, b, v, scale| (if (b == a) { 0 } else { I64.div_trunc_by(((v - a) * scale), (b - a)) })

	remap : I64, I64, I64, I64, I64 -> I64
	remap = |in_lo, in_hi, out_lo, out_hi, v| ({
		t = I64.div_trunc_by(((v - in_lo) * 1000), (in_hi - in_lo))
		(out_lo + I64.div_trunc_by(((out_hi - out_lo) * t), 1000))
	})

	smoothstep : I64, I64, I64, I64 -> I64
	smoothstep = |edge0, edge1, x, scale| (if (x <= edge0) { 0 } else { (if (x >= edge1) { scale } else { ({
		t = I64.div_trunc_by(((x - edge0) * scale), (edge1 - edge0))
		I64.div_trunc_by(((t * t) * ((3 * scale) - (2 * t))), (scale * scale))
	}) }) })

	step : I64, I64 -> I64
	step = |edge, x| (if (x < edge) { 0 } else { 1 })

	int_sqrt : I64 -> I64
	int_sqrt = |n| (if (n <= 0) { 0 } else { (if (n == 1) { 1 } else { ({
		g0 = I64.shr_zf_wrap(n, I64.to_u8_wrap(1))
		g1 = I64.shr_zf_wrap((g0 + I64.div_trunc_by(n, g0)), I64.to_u8_wrap(1))
		g2 = I64.shr_zf_wrap((g1 + I64.div_trunc_by(n, g1)), I64.to_u8_wrap(1))
		g3 = I64.shr_zf_wrap((g2 + I64.div_trunc_by(n, g2)), I64.to_u8_wrap(1))
		g4 = I64.shr_zf_wrap((g3 + I64.div_trunc_by(n, g3)), I64.to_u8_wrap(1))
		g5 = I64.shr_zf_wrap((g4 + I64.div_trunc_by(n, g4)), I64.to_u8_wrap(1))
		g6 = I64.shr_zf_wrap((g5 + I64.div_trunc_by(n, g5)), I64.to_u8_wrap(1))
		g7 = I64.shr_zf_wrap((g6 + I64.div_trunc_by(n, g6)), I64.to_u8_wrap(1))
		IntOps.int_min(g7, I64.div_trunc_by(n, g7))
	}) }) })

	int_pow : I64, I64 -> I64
	int_pow = |base, exp| (if (exp <= 0) { 1 } else { (if (exp == 1) { base } else { (if (exp == 2) { (base * base) } else { (if (exp == 3) { ((base * base) * base) } else { (if (exp == 4) { ({
		b2 = (base * base)
		(b2 * b2)
	}) } else { (if (exp == 5) { ({
		b2 = (base * base)
		((b2 * b2) * base)
	}) } else { (if (exp == 6) { ({
		b2 = (base * base)
		((b2 * b2) * b2)
	}) } else { (if (exp == 7) { ({
		b2 = (base * base)
		(((b2 * b2) * b2) * base)
	}) } else { (if (exp == 8) { ({
		b2 = (base * base)
		b4 = (b2 * b2)
		(b4 * b4)
	}) } else { (if (exp == 9) { ({
		b2 = (base * base)
		b4 = (b2 * b2)
		((b4 * b4) * base)
	}) } else { (if (exp == 10) { ({
		b2 = (base * base)
		b4 = (b2 * b2)
		((b4 * b4) * b2)
	}) } else { ({
		b2 = (base * base)
		b4 = (b2 * b2)
		b8 = (b4 * b4)
		(if (exp == 11) { ((b8 * b2) * base) } else { (if (exp == 12) { (b8 * b4) } else { (if (exp == 13) { ((b8 * b4) * base) } else { (if (exp == 14) { ((b8 * b4) * b2) } else { (if (exp == 15) { (((b8 * b4) * b2) * base) } else { (if (exp == 16) { (b8 * b8) } else { (if (exp == 17) { ((b8 * b8) * base) } else { (if (exp == 18) { ((b8 * b8) * b2) } else { (if (exp == 19) { (((b8 * b8) * b2) * base) } else { (if (exp == 20) { ((b8 * b8) * b4) } else { 0 }) }) }) }) }) }) }) }) }) })
	}) }) }) }) }) }) }) }) }) }) }) })

	int_log2 : I64 -> I64
	int_log2 = |x| (if (x <= 0) { (0 - 1) } else { (63 - BitOps.bit_clz(x)) })
}
