# Cordic -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Cordic :: [].{
	CordicResult := { cos_val : I64, sin_val : I64 }.{
		is_eq : Cordic.CordicResult, Cordic.CordicResult -> Bool
		is_eq = |a, b| eq_CordicResult(a, b)
	}
	CordicVector := { angle : I64, magnitude : I64 }.{
		is_eq : Cordic.CordicVector, Cordic.CordicVector -> Bool
		is_eq = |a, b| eq_CordicVector(a, b)
	}

	cordic_scale : I64
	cordic_scale = 1000

	cordic_iterations : I64
	cordic_iterations = 16

	cordic_gain : I64
	cordic_gain = 607

	cordic_half_pi : I64
	cordic_half_pi = 1571

	cordic_pi : I64
	cordic_pi = 3142

	cordic_three_half_pi : I64
	cordic_three_half_pi = 4712

	cordic_two_pi : I64
	cordic_two_pi = 6283

	cordic_atan_table : List(I64)
	cordic_atan_table = [785, 463, 244, 124, 62, 31, 15, 7, 3, 1, 0, 0, 0, 0, 0, 0]

	cordic_sincos : I64 -> Cordic.CordicResult
	cordic_sincos = |angle_milli| ({
		a : I64
		a = cordic_normalize(angle_milli)
		(if (a <= cordic_half_pi) { cordic_rotate(a, cordic_scale, 0, 0) } else { (if (a <= cordic_pi) { ({
			q = cordic_rotate((cordic_pi - a), cordic_scale, 0, 0)
			Cordic.CordicResult.{ cos_val: (0 - q.cos_val), sin_val: q.sin_val }
		}) } else { (if (a <= cordic_three_half_pi) { ({
			q = cordic_rotate((a - cordic_pi), cordic_scale, 0, 0)
			Cordic.CordicResult.{ cos_val: (0 - q.cos_val), sin_val: (0 - q.sin_val) }
		}) } else { ({
			q = cordic_rotate((cordic_two_pi - a), cordic_scale, 0, 0)
			Cordic.CordicResult.{ cos_val: q.cos_val, sin_val: (0 - q.sin_val) }
		}) }) }) })
	})

	cordic_normalize : I64 -> I64
	cordic_normalize = |a| ({
		full : I64
		full = 6283
		a2 : I64
		a2 = (a - (I64.div_trunc_by(a, full) * full))
		(if (a2 < 0) { (a2 + full) } else { a2 })
	})

	cordic_rotate : I64, I64, I64, I64 -> Cordic.CordicResult
	cordic_rotate = |target, x, y, i| (if (i >= cordic_iterations) { Cordic.CordicResult.{ cos_val: I64.div_trunc_by((x * cordic_gain), cordic_scale), sin_val: I64.div_trunc_by((y * cordic_gain), cordic_scale) } } else { ({
		atan_i : I64
		atan_i = (List.get(cordic_atan_table, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (target > 0) { cordic_rotate((target - atan_i), (x - I64.div_trunc_by(y, I64.shl_wrap(1, I64.to_u8_wrap(i)))), (y + I64.div_trunc_by(x, I64.shl_wrap(1, I64.to_u8_wrap(i)))), (i + 1)) } else { cordic_rotate((target + atan_i), (x + I64.div_trunc_by(y, I64.shl_wrap(1, I64.to_u8_wrap(i)))), (y - I64.div_trunc_by(x, I64.shl_wrap(1, I64.to_u8_wrap(i)))), (i + 1)) })
	}) })

	cordic_sin : I64 -> I64
	cordic_sin = |angle| cordic_sincos(angle).sin_val

	eq_CordicResult : Cordic.CordicResult, Cordic.CordicResult -> Bool
	eq_CordicResult = |ex, ey| ((ex.cos_val == ey.cos_val) and (ex.sin_val == ey.sin_val))

	eq_CordicVector : Cordic.CordicVector, Cordic.CordicVector -> Bool
	eq_CordicVector = |ex, ey| ((ex.angle == ey.angle) and (ex.magnitude == ey.magnitude))
}
