# Perlin -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Wrap64

Perlin :: [].{

	perlin_scale : I64
	perlin_scale = 1000

	perlin_hash : I64 -> I64
	perlin_hash = |x| ({
		h : I64
		h = I64.bitwise_xor(I64.times_wrap(x, 2654435761), 1013904223)
		h2 : I64
		h2 = I64.bitwise_xor(h, I64.shr_zf_wrap(h, I64.to_u8_wrap(13)))
		h3 : I64
		h3 = I64.plus_wrap(Wrap64.w64_mul(h2, 1103515245), 12345)
		(if (h3 < 0) { I64.minus_wrap(0, h3) } else { h3 })
	})

	perlin_hash2 : I64, I64 -> I64
	perlin_hash2 = |x, y| perlin_hash((x + perlin_hash(y)))

	perlin_grad1 : I64, I64 -> I64
	perlin_grad1 = |hash, dx| (if (I64.bitwise_and(hash, 1) == 0) { dx } else { (-dx) })

	perlin_grad2 : I64, I64, I64 -> I64
	perlin_grad2 = |hash, dx, dy| ({
		h : I64
		h = I64.bitwise_and(hash, 3)
		(if (h == 0) { (dx + dy) } else { (if (h == 1) { (dx - dy) } else { (if (h == 2) { ((-dx) + dy) } else { ((-dx) - dy) }) }) })
	})

	perlin_fade : I64 -> I64
	perlin_fade = |t| ({
		t2 : I64
		t2 = I64.div_trunc_by((t * t), perlin_scale)
		t3 : I64
		t3 = I64.div_trunc_by((t2 * t), perlin_scale)
		I64.div_trunc_by((t3 * (I64.div_trunc_by((t * (I64.div_trunc_by((t * 6), perlin_scale) - 15)), perlin_scale) + 10)), perlin_scale)
	})

	perlin_lerp : I64, I64, I64 -> I64
	perlin_lerp = |a, b, t| (a + I64.div_trunc_by(((b - a) * t), perlin_scale))

	perlin_noise1 : I64 -> I64
	perlin_noise1 = |x_milli| ({
		xi : I64
		xi = I64.div_trunc_by(x_milli, perlin_scale)
		xf : I64
		xf = (x_milli - (xi * perlin_scale))
		u : I64
		u = perlin_fade(xf)
		g0 : I64
		g0 = perlin_grad1(perlin_hash(xi), xf)
		g1 : I64
		g1 = perlin_grad1(perlin_hash((xi + 1)), (xf - perlin_scale))
		perlin_lerp(g0, g1, u)
	})

	perlin_noise2 : I64, I64 -> I64
	perlin_noise2 = |x_milli, y_milli| ({
		xi : I64
		xi = I64.div_trunc_by(x_milli, perlin_scale)
		yi : I64
		yi = I64.div_trunc_by(y_milli, perlin_scale)
		xf : I64
		xf = (x_milli - (xi * perlin_scale))
		yf : I64
		yf = (y_milli - (yi * perlin_scale))
		u : I64
		u = perlin_fade(xf)
		v : I64
		v = perlin_fade(yf)
		g00 : I64
		g00 = perlin_grad2(perlin_hash2(xi, yi), xf, yf)
		g10 : I64
		g10 = perlin_grad2(perlin_hash2((xi + 1), yi), (xf - perlin_scale), yf)
		g01 : I64
		g01 = perlin_grad2(perlin_hash2(xi, (yi + 1)), xf, (yf - perlin_scale))
		g11 : I64
		g11 = perlin_grad2(perlin_hash2((xi + 1), (yi + 1)), (xf - perlin_scale), (yf - perlin_scale))
		x0 : I64
		x0 = perlin_lerp(g00, g10, u)
		x1 : I64
		x1 = perlin_lerp(g01, g11, u)
		perlin_lerp(x0, x1, v)
	})

	perlin_octaves1 : I64, I64, I64, I64 -> I64
	perlin_octaves1 = |x, num_octaves, persistence, lacunarity| perlin_oct1_loop(x, num_octaves, persistence, lacunarity, 0, perlin_scale, perlin_scale, 0)

	perlin_oct1_loop : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
	perlin_oct1_loop = |x, oct, persist, lac, i, amp, freq, total| (if (i >= oct) { total } else { ({
		val : I64
		val = I64.div_trunc_by((perlin_noise1(I64.div_trunc_by((x * freq), perlin_scale)) * amp), perlin_scale)
		perlin_oct1_loop(x, oct, persist, lac, (i + 1), I64.div_trunc_by((amp * persist), perlin_scale), I64.div_trunc_by((freq * lac), perlin_scale), (total + val))
	}) })

	perlin_octaves2 : I64, I64, I64, I64, I64 -> I64
	perlin_octaves2 = |x, y, num_octaves, persistence, lacunarity| perlin_oct2_loop(x, y, num_octaves, persistence, lacunarity, 0, perlin_scale, perlin_scale, 0)

	perlin_oct2_loop : I64, I64, I64, I64, I64, I64, I64, I64, I64 -> I64
	perlin_oct2_loop = |x, y, oct, persist, lac, i, amp, freq, total| (if (i >= oct) { total } else { ({
		val : I64
		val = I64.div_trunc_by((perlin_noise2(I64.div_trunc_by((x * freq), perlin_scale), I64.div_trunc_by((y * freq), perlin_scale)) * amp), perlin_scale)
		perlin_oct2_loop(x, y, oct, persist, lac, (i + 1), I64.div_trunc_by((amp * persist), perlin_scale), I64.div_trunc_by((freq * lac), perlin_scale), (total + val))
	}) })

	perlin_normalize : I64 -> I64
	perlin_normalize = |val| I64.div_trunc_by(((val + perlin_scale) * 500), perlin_scale)
}
