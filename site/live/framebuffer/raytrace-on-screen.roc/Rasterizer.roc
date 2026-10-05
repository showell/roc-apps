# Rasterizer -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Rasterizer :: [].{
	Framebuf := { fb_width : I64, fb_height : I64, fb_pixels : List(I64) }.{
		is_eq : Rasterizer.Framebuf, Rasterizer.Framebuf -> Bool
		is_eq = |a, b| eq_Framebuf(a, b)
	}
	TriSorted := { ts_ax : I64, ts_ay : I64, ts_bx : I64, ts_by : I64, ts_cx : I64, ts_cy : I64 }.{
		is_eq : Rasterizer.TriSorted, Rasterizer.TriSorted -> Bool
		is_eq = |a, b| eq_TriSorted(a, b)
	}

	fb_new : I64, I64, I64 -> Rasterizer.Framebuf
	fb_new = |w, h, bg| Rasterizer.Framebuf.{ fb_width: w, fb_height: h, fb_pixels: fb_fill((w * h), bg) }

	fb_fill : I64, I64 -> List(I64)
	fb_fill = |n, val| fb_fill_loop(n, val, [])

	fb_fill_loop : I64, I64, List(I64) -> List(I64)
	fb_fill_loop = |n, val, acc| (if (n <= 0) { acc } else { fb_fill_loop((n - 1), val, List.append(acc, val)) })

	fb_set : Rasterizer.Framebuf, I64, I64, I64 -> Rasterizer.Framebuf
	fb_set = |fb, x, y, color| (if (x < 0) { fb } else { (if (y < 0) { fb } else { (if (x >= fb.fb_width) { fb } else { (if (y >= fb.fb_height) { fb } else { Rasterizer.Framebuf.{ fb_width: fb.fb_width, fb_height: fb.fb_height, fb_pixels: (List.set(fb.fb_pixels, I64.to_u64_wrap(((y * fb.fb_width) + x)), color) ?? crash("list-set-at past the end")) } }) }) }) })

	fb_get : Rasterizer.Framebuf, I64, I64 -> I64
	fb_get = |fb, x, y| (if (x < 0) { 0 } else { (if (y < 0) { 0 } else { (if (x >= fb.fb_width) { 0 } else { (if (y >= fb.fb_height) { 0 } else { (List.get(fb.fb_pixels, I64.to_u64_wrap(((y * fb.fb_width) + x))) ?? crash("list-at out of range")) }) }) }) })

	eq_Framebuf : Rasterizer.Framebuf, Rasterizer.Framebuf -> Bool
	eq_Framebuf = |ex, ey| (((ex.fb_width == ey.fb_width) and (ex.fb_height == ey.fb_height)) and (ex.fb_pixels == ey.fb_pixels))

	eq_TriSorted : Rasterizer.TriSorted, Rasterizer.TriSorted -> Bool
	eq_TriSorted = |ex, ey| ((((((ex.ts_ax == ey.ts_ax) and (ex.ts_ay == ey.ts_ay)) and (ex.ts_bx == ey.ts_bx)) and (ex.ts_by == ey.ts_by)) and (ex.ts_cx == ey.ts_cx)) and (ex.ts_cy == ey.ts_cy))
}
