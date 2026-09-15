# Texture -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Texture :: [].{
	EngineTexture : { etx_width : I64, etx_height : I64, etx_pixels : List(I64) }
	SampleMode : [NearestNeighbor, Bilinear]
	WrapMode : [WrapRepeat, WrapClamp, WrapMirror]

	etx_new : I64, I64, I64 -> Texture.EngineTexture
	etx_new = |w, h, fill| { etx_width: w, etx_height: h, etx_pixels: etx_fill((w * h), fill, []) }

	etx_fill : I64, I64, List(I64) -> List(I64)
	etx_fill = |n, val, acc| (if (n <= 0) { acc } else { etx_fill((n - 1), val, List.append(acc, val)) })

	etx_from_pixels : I64, I64, List(I64) -> Texture.EngineTexture
	etx_from_pixels = |w, h, pixels| { etx_width: w, etx_height: h, etx_pixels: pixels }

	etx_set : Texture.EngineTexture, I64, I64, I64 -> Texture.EngineTexture
	etx_set = |tex, x, y, color| (if (x < 0) { tex } else { (if (y < 0) { tex } else { (if (x >= tex.etx_width) { tex } else { (if (y >= tex.etx_height) { tex } else { { etx_width: tex.etx_width, etx_height: tex.etx_height, etx_pixels: (List.set(tex.etx_pixels, I64.to_u64_wrap(((y * tex.etx_width) + x)), color) ?? crash("list-set-at past the end")) } }) }) }) })

	etx_get : Texture.EngineTexture, I64, I64 -> I64
	etx_get = |tex, x, y| (if (x < 0) { 0 } else { (if (y < 0) { 0 } else { (if (x >= tex.etx_width) { 0 } else { (if (y >= tex.etx_height) { 0 } else { (List.get(tex.etx_pixels, I64.to_u64_wrap(((y * tex.etx_width) + x))) ?? crash("list-at out of range")) }) }) }) })

	etx_wrap_coord : I64, I64, Texture.WrapMode -> I64
	etx_wrap_coord = |uv, size, mode| (match mode {
		WrapRepeat => ({
			m = etx_imod(uv, size)
			(if (m < 0) { (m + size) } else { m })
		})
		WrapClamp => (if (uv < 0) { 0 } else { (if (uv >= size) { (size - 1) } else { uv }) })
		WrapMirror => ({
			period = (size * 2)
			m = etx_imod(uv, period)
			pos = (if (m < 0) { (m + period) } else { m })
			(if (pos >= size) { ((period - 1) - pos) } else { pos })
		})
	})

	etx_imod : I64, I64 -> I64
	etx_imod = |a, b| (if (b == 0) { 0 } else { (a - (I64.div_trunc_by(a, b) * b)) })

	etx_sample_nearest : Texture.EngineTexture, I64, I64, Texture.WrapMode -> I64
	etx_sample_nearest = |tex, u, v, wrap| ({
		px = I64.div_trunc_by((u * tex.etx_width), 1000)
		py = I64.div_trunc_by((v * tex.etx_height), 1000)
		wx = etx_wrap_coord(px, tex.etx_width, wrap)
		wy = etx_wrap_coord(py, tex.etx_height, wrap)
		etx_get(tex, wx, wy)
	})

	etx_sample_bilinear : Texture.EngineTexture, I64, I64, Texture.WrapMode -> I64
	etx_sample_bilinear = |tex, u, v, wrap| ({
		fx = (u * tex.etx_width)
		fy = (v * tex.etx_height)
		x0 = I64.div_trunc_by(fx, 1000)
		y0 = I64.div_trunc_by(fy, 1000)
		x1 = (x0 + 1)
		y1 = (y0 + 1)
		frac_x = (fx - (x0 * 1000))
		frac_y = (fy - (y0 * 1000))
		wx0 = etx_wrap_coord(x0, tex.etx_width, wrap)
		wy0 = etx_wrap_coord(y0, tex.etx_height, wrap)
		wx1 = etx_wrap_coord(x1, tex.etx_width, wrap)
		wy1 = etx_wrap_coord(y1, tex.etx_height, wrap)
		c00 = etx_get(tex, wx0, wy0)
		c10 = etx_get(tex, wx1, wy0)
		c01 = etx_get(tex, wx0, wy1)
		c11 = etx_get(tex, wx1, wy1)
		etx_bilerp(c00, c10, c01, c11, frac_x, frac_y)
	})

	etx_bilerp : I64, I64, I64, I64, I64, I64 -> I64
	etx_bilerp = |c00, c10, c01, c11, fx, fy| ({
		inv_fx = (1000 - fx)
		inv_fy = (1000 - fy)
		r00 = etx_chan_r(c00)
		g00 = etx_chan_g(c00)
		b00 = etx_chan_b(c00)
		r10 = etx_chan_r(c10)
		g10 = etx_chan_g(c10)
		b10 = etx_chan_b(c10)
		r01 = etx_chan_r(c01)
		g01 = etx_chan_g(c01)
		b01 = etx_chan_b(c01)
		r11 = etx_chan_r(c11)
		g11 = etx_chan_g(c11)
		b11 = etx_chan_b(c11)
		r = (I64.div_trunc_by((((r00 * inv_fx) + (r10 * fx)) * inv_fy), 1000) + I64.div_trunc_by((((r01 * inv_fx) + (r11 * fx)) * fy), 1000))
		g = (I64.div_trunc_by((((g00 * inv_fx) + (g10 * fx)) * inv_fy), 1000) + I64.div_trunc_by((((g01 * inv_fx) + (g11 * fx)) * fy), 1000))
		b = (I64.div_trunc_by((((b00 * inv_fx) + (b10 * fx)) * inv_fy), 1000) + I64.div_trunc_by((((b01 * inv_fx) + (b11 * fx)) * fy), 1000))
		etx_pack_rgb(I64.div_trunc_by(r, 1000), I64.div_trunc_by(g, 1000), I64.div_trunc_by(b, 1000))
	})

	etx_chan_r : I64 -> I64
	etx_chan_r = |packed| I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(16)), 255)

	etx_chan_g : I64 -> I64
	etx_chan_g = |packed| I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(8)), 255)

	etx_chan_b : I64 -> I64
	etx_chan_b = |packed| I64.bitwise_and(packed, 255)

	etx_pack_rgb : I64, I64, I64 -> I64
	etx_pack_rgb = |r, g, b| ({
		rc = (if (r > 255) { 255 } else { (if (r < 0) { 0 } else { r }) })
		gc = (if (g > 255) { 255 } else { (if (g < 0) { 0 } else { g }) })
		bc = (if (b > 255) { 255 } else { (if (b < 0) { 0 } else { b }) })
		I64.bitwise_or(I64.shl_wrap(rc, I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(gc, I64.to_u8_wrap(8)), bc))
	})

	etx_checkerboard : I64, I64, I64, I64, I64 -> Texture.EngineTexture
	etx_checkerboard = |w, h, tile_size, color_a, color_b| etx_checker_build(w, h, tile_size, color_a, color_b, 0, 0, [])

	etx_checker_build : I64, I64, I64, I64, I64, I64, I64, List(I64) -> Texture.EngineTexture
	etx_checker_build = |w, h, tile, ca, cb, x, y, acc| (if (y >= h) { { etx_width: w, etx_height: h, etx_pixels: acc } } else { (if (x >= w) { etx_checker_build(w, h, tile, ca, cb, 0, (y + 1), acc) } else { ({
		tx = I64.div_trunc_by(x, tile)
		ty = I64.div_trunc_by(y, tile)
		color = (if (etx_imod((tx + ty), 2) == 0) { ca } else { cb })
		etx_checker_build(w, h, tile, ca, cb, (x + 1), y, List.append(acc, color))
	}) }) })

	etx_gradient_h : I64, I64, I64, I64 -> Texture.EngineTexture
	etx_gradient_h = |w, h, color_left, color_right| etx_grad_build(w, h, color_left, color_right, 0, 0, [])

	etx_grad_build : I64, I64, I64, I64, I64, I64, List(I64) -> Texture.EngineTexture
	etx_grad_build = |w, h, cl, cr, x, y, acc| (if (y >= h) { { etx_width: w, etx_height: h, etx_pixels: acc } } else { (if (x >= w) { etx_grad_build(w, h, cl, cr, 0, (y + 1), acc) } else { ({
		t = I64.div_trunc_by((x * 1000), w)
		r = etx_lerp_chan(etx_chan_r(cl), etx_chan_r(cr), t)
		g = etx_lerp_chan(etx_chan_g(cl), etx_chan_g(cr), t)
		b = etx_lerp_chan(etx_chan_b(cl), etx_chan_b(cr), t)
		etx_grad_build(w, h, cl, cr, (x + 1), y, List.append(acc, etx_pack_rgb(r, g, b)))
	}) }) })

	etx_lerp_chan : I64, I64, I64 -> I64
	etx_lerp_chan = |a, b, t| (a + I64.div_trunc_by(((b - a) * t), 1000))

	format_texture : Texture.EngineTexture -> Str
	format_texture = |tex| Str.concat(Str.concat(Str.concat(Str.concat("Texture(", I64.to_str(tex.etx_width)), "x"), I64.to_str(tex.etx_height)), ")")

	eq_SampleMode : Texture.SampleMode, Texture.SampleMode -> Bool
	eq_SampleMode = |ex, ey| (match ex {
		NearestNeighbor => (match ey {
			NearestNeighbor => True
			_ => False
		})
		Bilinear => (match ey {
			Bilinear => True
			_ => False
		})
	})

	eq_WrapMode : Texture.WrapMode, Texture.WrapMode -> Bool
	eq_WrapMode = |ex, ey| (match ex {
		WrapRepeat => (match ey {
			WrapRepeat => True
			_ => False
		})
		WrapClamp => (match ey {
			WrapClamp => True
			_ => False
		})
		WrapMirror => (match ey {
			WrapMirror => True
			_ => False
		})
	})
}
