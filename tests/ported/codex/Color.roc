# Color -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

Color :: [].{
	Rgb : { cr : I64, cg : I64, cb : I64 }
	Hsl : { ch : I64, cs : I64, cl : I64 }
	RainbowPalette : [PalRainbow, PalWarm, PalCool, PalPastel, PalNeon, PalFire, PalOcean, PalForest, PalMiami, PalMatrix, PalSakura, PalAurora]

	rgb : I64, I64, I64 -> Color.Rgb
	rgb = |r, g, b| { cr: r, cg: g, cb: b }

	rgb_black : Color.Rgb
	rgb_black = { cr: 0, cg: 0, cb: 0 }

	rgb_white : Color.Rgb
	rgb_white = { cr: 255, cg: 255, cb: 255 }

	rgb_red : Color.Rgb
	rgb_red = { cr: 255, cg: 0, cb: 0 }

	rgb_green : Color.Rgb
	rgb_green = { cr: 0, cg: 255, cb: 0 }

	rgb_blue : Color.Rgb
	rgb_blue = { cr: 0, cg: 0, cb: 255 }

	rgb_from_packed : I64 -> Color.Rgb
	rgb_from_packed = |packed| { cr: I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(16)), 255), cg: I64.bitwise_and(I64.shr_zf_wrap(packed, I64.to_u8_wrap(8)), 255), cb: I64.bitwise_and(packed, 255) }

	rgb_to_packed : Color.Rgb -> I64
	rgb_to_packed = |c| I64.bitwise_or(I64.shl_wrap(c.cr, I64.to_u8_wrap(16)), I64.bitwise_or(I64.shl_wrap(c.cg, I64.to_u8_wrap(8)), c.cb))

	rgb_lerp : Color.Rgb, Color.Rgb, I64 -> Color.Rgb
	rgb_lerp = |a, b, t| ({
		inv = (1000 - t)
		{ cr: I64.div_trunc_by(((a.cr * inv) + (b.cr * t)), 1000), cg: I64.div_trunc_by(((a.cg * inv) + (b.cg * t)), 1000), cb: I64.div_trunc_by(((a.cb * inv) + (b.cb * t)), 1000) }
	})

	rgb_add : Color.Rgb, Color.Rgb -> Color.Rgb
	rgb_add = |a, b| { cr: col_clamp8((a.cr + b.cr)), cg: col_clamp8((a.cg + b.cg)), cb: col_clamp8((a.cb + b.cb)) }

	rgb_multiply : Color.Rgb, Color.Rgb -> Color.Rgb
	rgb_multiply = |a, b| { cr: I64.div_trunc_by((a.cr * b.cr), 255), cg: I64.div_trunc_by((a.cg * b.cg), 255), cb: I64.div_trunc_by((a.cb * b.cb), 255) }

	rgb_scale : Color.Rgb, I64 -> Color.Rgb
	rgb_scale = |c, s| { cr: col_clamp8(I64.div_trunc_by((c.cr * s), 1000)), cg: col_clamp8(I64.div_trunc_by((c.cg * s), 1000)), cb: col_clamp8(I64.div_trunc_by((c.cb * s), 1000)) }

	rgb_alpha_blend : Color.Rgb, Color.Rgb, I64 -> Color.Rgb
	rgb_alpha_blend = |fg, bg, alpha| rgb_lerp(bg, fg, alpha)

	rgb_brightness : Color.Rgb, I64 -> Color.Rgb
	rgb_brightness = |c, delta| { cr: col_clamp8((c.cr + delta)), cg: col_clamp8((c.cg + delta)), cb: col_clamp8((c.cb + delta)) }

	rgb_invert : Color.Rgb -> Color.Rgb
	rgb_invert = |c| { cr: (255 - c.cr), cg: (255 - c.cg), cb: (255 - c.cb) }

	rgb_grayscale : Color.Rgb -> Color.Rgb
	rgb_grayscale = |c| ({
		lum = I64.div_trunc_by((((c.cr * 299) + (c.cg * 587)) + (c.cb * 114)), 1000)
		{ cr: lum, cg: lum, cb: lum }
	})

	rgb_luminance : Color.Rgb -> I64
	rgb_luminance = |c| I64.div_trunc_by((((c.cr * 299) + (c.cg * 587)) + (c.cb * 114)), 1000)

	rgb_to_hsl : Color.Rgb -> Color.Hsl
	rgb_to_hsl = |c| ({
		r = I64.div_trunc_by((c.cr * 1000), 255)
		g = I64.div_trunc_by((c.cg * 1000), 255)
		b = I64.div_trunc_by((c.cb * 1000), 255)
		mx = col_max3(r, g, b)
		mn = col_min3(r, g, b)
		l = I64.div_trunc_by((mx + mn), 2)
		delta = (mx - mn)
		(if (delta == 0) { { ch: 0, cs: 0, cl: l } } else { ({
			s = (if (l > 500) { I64.div_trunc_by((delta * 1000), ((2000 - mx) - mn)) } else { I64.div_trunc_by((delta * 1000), (mx + mn)) })
			h = col_hue(r, g, b, mx, delta)
			{ ch: h, cs: s, cl: l }
		}) })
	})

	col_hue : I64, I64, I64, I64, I64 -> I64
	col_hue = |r, g, b, mx, delta| (if (mx == r) { ({
		raw = I64.div_trunc_by(((g - b) * 60), delta)
		(if (raw < 0) { (raw + 360) } else { raw })
	}) } else { (if (mx == g) { (I64.div_trunc_by(((b - r) * 60), delta) + 120) } else { (I64.div_trunc_by(((r - g) * 60), delta) + 240) }) })

	hsl_to_rgb : Color.Hsl -> Color.Rgb
	hsl_to_rgb = |c| (if (c.cs == 0) { ({
		v = I64.div_trunc_by((c.cl * 255), 1000)
		{ cr: v, cg: v, cb: v }
	}) } else { ({
		q = (if (c.cl < 500) { I64.div_trunc_by((c.cl * (1000 + c.cs)), 1000) } else { ((c.cl + c.cs) - I64.div_trunc_by((c.cl * c.cs), 1000)) })
		p = ((2 * c.cl) - q)
		h = c.ch
		{ cr: hsl_channel(p, q, (h + 120)), cg: hsl_channel(p, q, h), cb: hsl_channel(p, q, (h - 120)) }
	}) })

	hsl_channel : I64, I64, I64 -> I64
	hsl_channel = |p, q, h_raw| ({
		h = (if (h_raw < 0) { (h_raw + 360) } else { (if (h_raw >= 360) { (h_raw - 360) } else { h_raw }) })
		val = (if (h < 60) { (p + I64.div_trunc_by(((q - p) * h), 60)) } else { (if (h < 180) { q } else { (if (h < 240) { (p + I64.div_trunc_by(((q - p) * (240 - h)), 60)) } else { p }) }) })
		I64.div_trunc_by((val * 255), 1000)
	})

	palette_gradient : Color.Rgb, Color.Rgb, I64 -> List(Color.Rgb)
	palette_gradient = |start, stop, steps| pal_grad_loop(start, stop, steps, 0, [])

	pal_grad_loop : Color.Rgb, Color.Rgb, I64, I64, List(Color.Rgb) -> List(Color.Rgb)
	pal_grad_loop = |start, stop, steps, i, acc| (if (i >= steps) { acc } else { ({
		t = (if (steps <= 1) { 0 } else { I64.div_trunc_by((i * 1000), (steps - 1)) })
		pal_grad_loop(start, stop, steps, (i + 1), List.append(acc, rgb_lerp(start, stop, t)))
	}) })

	palette_rainbow : I64 -> List(Color.Rgb)
	palette_rainbow = |steps| pal_rainbow_loop(steps, 0, [])

	pal_rainbow_loop : I64, I64, List(Color.Rgb) -> List(Color.Rgb)
	pal_rainbow_loop = |steps, i, acc| (if (i >= steps) { acc } else { ({
		h = I64.div_trunc_by((i * 360), steps)
		pal_rainbow_loop(steps, (i + 1), List.append(acc, hsl_to_rgb({ ch: h, cs: 900, cl: 500 })))
	}) })

	col_clamp8 : I64 -> I64
	col_clamp8 = |v| (if (v < 0) { 0 } else { (if (v > 255) { 255 } else { v }) })

	col_max3 : I64, I64, I64 -> I64
	col_max3 = |a, b, c| ({
		ab = (if (a > b) { a } else { b })
		(if (ab > c) { ab } else { c })
	})

	col_min3 : I64, I64, I64 -> I64
	col_min3 = |a, b, c| ({
		ab = (if (a < b) { a } else { b })
		(if (ab < c) { ab } else { c })
	})

	lolcat_hue_mod : I64, I64 -> I64
	lolcat_hue_mod = |raw, range| (if (range <= 0) { 0 } else { ({
		m = (raw - (I64.div_trunc_by(raw, range) * range))
		(if (m < 0) { (m + range) } else { m })
	}) })

	lolcat_color : I64, I64, I64, I64, Color.RainbowPalette -> I64
	lolcat_color = |row, col, freq, seed, pal| ({
		idx = (seed + ((col + row) * freq))
		lolcat_apply(idx, pal)
	})

	lolcat_apply : I64, Color.RainbowPalette -> I64
	lolcat_apply = |idx, pal| (match pal {
		PalRainbow => lolcat_pal(idx, 0, 360, 1000, 500)
		PalWarm => lolcat_pal(idx, 0, 60, 1000, 500)
		PalCool => lolcat_pal(idx, 180, 90, 1000, 500)
		PalPastel => lolcat_pal(idx, 0, 360, 500, 700)
		PalNeon => lolcat_pal(idx, 0, 360, 1000, 400)
		PalFire => lolcat_pal(idx, 0, 40, 1000, 500)
		PalOcean => lolcat_pal(idx, 160, 80, 900, 450)
		PalForest => lolcat_pal(idx, 80, 80, 800, 400)
		PalMiami => lolcat_pal(idx, 270, 100, 800, 600)
		PalMatrix => lolcat_pal(idx, 120, 30, 1000, 400)
		PalSakura => lolcat_pal(idx, 300, 40, 700, 700)
		PalAurora => lolcat_pal(idx, 100, 180, 900, 450)
	})

	lolcat_pal : I64, I64, I64, I64, I64 -> I64
	lolcat_pal = |idx, hue_start, hue_range, sat, lit| ({
		offset = lolcat_hue_mod(idx, hue_range)
		hue = lolcat_hue_mod((hue_start + offset), 360)
		rgb_to_packed(hsl_to_rgb({ ch: hue, cs: sat, cl: lit }))
	})

	format_rgb : Color.Rgb -> Text
	format_rgb = |c| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("rgb(", Text.show_int(c.cr)), ","), Text.show_int(c.cg)), ","), Text.show_int(c.cb)), ")")

	format_hsl : Color.Hsl -> Text
	format_hsl = |c| Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("hsl(", Text.show_int(c.ch)), ","), Text.show_int(c.cs)), ","), Text.show_int(c.cl)), ")")

	format_hex_color : Color.Rgb -> Text
	format_hex_color = |c| Text.concat(Text.concat(Text.concat("#", col_hex2(c.cr)), col_hex2(c.cg)), col_hex2(c.cb))

	col_hex2 : I64 -> Text
	col_hex2 = |v| Text.concat(col_hex_digit(I64.div_trunc_by(v, 16)), col_hex_digit(I64.bitwise_and(v, 15)))

	col_hex_digit : I64 -> Text
	col_hex_digit = |d| (if (d == 0) { "0" } else { (if (d == 1) { "1" } else { (if (d == 2) { "2" } else { (if (d == 3) { "3" } else { (if (d == 4) { "4" } else { (if (d == 5) { "5" } else { (if (d == 6) { "6" } else { (if (d == 7) { "7" } else { (if (d == 8) { "8" } else { (if (d == 9) { "9" } else { (if (d == 10) { "a" } else { (if (d == 11) { "b" } else { (if (d == 12) { "c" } else { (if (d == 13) { "d" } else { (if (d == 14) { "e" } else { "f" }) }) }) }) }) }) }) }) }) }) }) }) }) }) })

	eq_RainbowPalette : Color.RainbowPalette, Color.RainbowPalette -> Bool
	eq_RainbowPalette = |ex, ey| (match ex {
		PalRainbow => (match ey {
			PalRainbow => True
			_ => False
		})
		PalWarm => (match ey {
			PalWarm => True
			_ => False
		})
		PalCool => (match ey {
			PalCool => True
			_ => False
		})
		PalPastel => (match ey {
			PalPastel => True
			_ => False
		})
		PalNeon => (match ey {
			PalNeon => True
			_ => False
		})
		PalFire => (match ey {
			PalFire => True
			_ => False
		})
		PalOcean => (match ey {
			PalOcean => True
			_ => False
		})
		PalForest => (match ey {
			PalForest => True
			_ => False
		})
		PalMiami => (match ey {
			PalMiami => True
			_ => False
		})
		PalMatrix => (match ey {
			PalMatrix => True
			_ => False
		})
		PalSakura => (match ey {
			PalSakura => True
			_ => False
		})
		PalAurora => (match ey {
			PalAurora => True
			_ => False
		})
	})
}
