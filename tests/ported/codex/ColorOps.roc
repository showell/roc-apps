# ColorOps -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

ColorOps :: [].{

	rgba_pack : I64, I64, I64, I64 -> I64
	rgba_pack = |r, g, b, a| I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(a, I64.to_u8_wrap(24)), I64.shl_wrap(r, I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(g, I64.to_u8_wrap(8)), b))

	rgba_r : I64 -> I64
	rgba_r = |c| I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(16)), 255)

	rgba_g : I64 -> I64
	rgba_g = |c| I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(8)), 255)

	rgba_b : I64 -> I64
	rgba_b = |c| I64.bitwise_and(c, 255)

	rgba_a : I64 -> I64
	rgba_a = |c| I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(24)), 255)

	rgba_blend : I64, I64 -> I64
	rgba_blend = |fg, bg| ({
		a : I64
		a = I64.bitwise_and(I64.shr_zf_wrap(fg, I64.to_u8_wrap(24)), 255)
		inv_a : I64
		inv_a = (255 - a)
		fr : I64
		fr = I64.bitwise_and(I64.shr_zf_wrap(fg, I64.to_u8_wrap(16)), 255)
		fg2 : I64
		fg2 = I64.bitwise_and(I64.shr_zf_wrap(fg, I64.to_u8_wrap(8)), 255)
		fb : I64
		fb = I64.bitwise_and(fg, 255)
		br : I64
		br = I64.bitwise_and(I64.shr_zf_wrap(bg, I64.to_u8_wrap(16)), 255)
		bg2 : I64
		bg2 = I64.bitwise_and(I64.shr_zf_wrap(bg, I64.to_u8_wrap(8)), 255)
		bb : I64
		bb = I64.bitwise_and(bg, 255)
		o_r : I64
		o_r = I64.div_trunc_by(((fr * a) + (br * inv_a)), 255)
		og : I64
		og = I64.div_trunc_by(((fg2 * a) + (bg2 * inv_a)), 255)
		ob : I64
		ob = I64.div_trunc_by(((fb * a) + (bb * inv_a)), 255)
		I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(255, I64.to_u8_wrap(24)), I64.shl_wrap(o_r, I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(og, I64.to_u8_wrap(8)), ob))
	})

	rgb_luminance_packed : I64 -> I64
	rgb_luminance_packed = |c| ({
		r : I64
		r = I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(16)), 255)
		g : I64
		g = I64.bitwise_and(I64.shr_zf_wrap(c, I64.to_u8_wrap(8)), 255)
		b : I64
		b = I64.bitwise_and(c, 255)
		I64.div_trunc_by((((r * 77) + (g * 150)) + (b * 29)), 256)
	})

	rgb_lerp_packed : I64, I64, I64 -> I64
	rgb_lerp_packed = |c1, c2, t| ({
		inv : I64
		inv = (255 - t)
		r : I64
		r = ((I64.bitwise_and(I64.shr_zf_wrap(c1, I64.to_u8_wrap(16)), 255) * inv) + (I64.bitwise_and(I64.shr_zf_wrap(c2, I64.to_u8_wrap(16)), 255) * t))
		g : I64
		g = ((I64.bitwise_and(I64.shr_zf_wrap(c1, I64.to_u8_wrap(8)), 255) * inv) + (I64.bitwise_and(I64.shr_zf_wrap(c2, I64.to_u8_wrap(8)), 255) * t))
		b : I64
		b = ((I64.bitwise_and(c1, 255) * inv) + (I64.bitwise_and(c2, 255) * t))
		a : I64
		a = ((I64.bitwise_and(I64.shr_zf_wrap(c1, I64.to_u8_wrap(24)), 255) * inv) + (I64.bitwise_and(I64.shr_zf_wrap(c2, I64.to_u8_wrap(24)), 255) * t))
		I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(I64.div_trunc_by(a, 255), I64.to_u8_wrap(24)), I64.shl_wrap(I64.div_trunc_by(r, 255), I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(I64.div_trunc_by(g, 255), I64.to_u8_wrap(8)), I64.div_trunc_by(b, 255)))
	})
}
