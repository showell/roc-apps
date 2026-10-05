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

	eq_Framebuf : Rasterizer.Framebuf, Rasterizer.Framebuf -> Bool
	eq_Framebuf = |ex, ey| (((ex.fb_width == ey.fb_width) and (ex.fb_height == ey.fb_height)) and (ex.fb_pixels == ey.fb_pixels))

	eq_TriSorted : Rasterizer.TriSorted, Rasterizer.TriSorted -> Bool
	eq_TriSorted = |ex, ey| ((((((ex.ts_ax == ey.ts_ax) and (ex.ts_ay == ey.ts_ay)) and (ex.ts_bx == ey.ts_bx)) and (ex.ts_by == ey.ts_by)) and (ex.ts_cx == ey.ts_cx)) and (ex.ts_cy == ey.ts_cy))
}
