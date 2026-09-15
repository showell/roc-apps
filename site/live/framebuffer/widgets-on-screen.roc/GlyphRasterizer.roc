# GlyphRasterizer -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Prelude
import TrueType

GlyphRasterizer :: [].{
	ScaledPoint : { sp_x : I64, sp_y : I64, sp_on : I64 }
	Edge : { e_x0 : I64, e_y0 : I64, e_x1 : I64, e_y1 : I64 }
	RasterGlyph : { rg_code : I64, rg_width : I64, rg_height : I64, rg_advance : I64, rg_pixels : List(I64) }

	sp_new : I64, I64, I64 -> GlyphRasterizer.ScaledPoint
	sp_new = |x, y, on| { sp_x: x, sp_y: y, sp_on: on }

	gr_scale_contour : TrueType.TtfContour, I64, I64, I64, I64 -> List(GlyphRasterizer.ScaledPoint)
	gr_scale_contour = |contour, ppem, upem, x_off, y_off| gr_scale_pts(contour.tc_points, ppem, upem, x_off, y_off, 0, [])

	gr_scale_pts : List(TrueType.TtfPoint), I64, I64, I64, I64, I64, List(GlyphRasterizer.ScaledPoint) -> List(GlyphRasterizer.ScaledPoint)
	gr_scale_pts = |pts, ppem, upem, x_off, y_off, i, acc| (if (i >= U64.to_i64_wrap(List.len(pts))) { acc } else { ({
		p = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		sx = I64.div_trunc_by((((p.tp_x + x_off) * ppem) * 64), upem)
		sy = I64.div_trunc_by((((p.tp_y + y_off) * ppem) * 64), upem)
		gr_scale_pts(pts, ppem, upem, x_off, y_off, (i + 1), List.append(acc, sp_new(sx, sy, p.tp_on_curve)))
	}) })

	gr_expand_midpoints : List(GlyphRasterizer.ScaledPoint) -> List(GlyphRasterizer.ScaledPoint)
	gr_expand_midpoints = |pts| ({
		n = U64.to_i64_wrap(List.len(pts))
		(if (n < 2) { pts } else { gr_expand_loop(pts, n, 0, []) })
	})

	gr_expand_loop : List(GlyphRasterizer.ScaledPoint), I64, I64, List(GlyphRasterizer.ScaledPoint) -> List(GlyphRasterizer.ScaledPoint)
	gr_expand_loop = |pts, n, i, acc| (if (i >= n) { acc } else { ({
		curr = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		next = (List.get(pts, I64.to_u64_wrap(gr_wrap((i + 1), n))) ?? crash("list-at out of range"))
		(if (curr.sp_on == 0) { (if (next.sp_on == 0) { ({
			mid = sp_new(I64.div_trunc_by((curr.sp_x + next.sp_x), 2), I64.div_trunc_by((curr.sp_y + next.sp_y), 2), 1)
			gr_expand_loop(pts, n, (i + 1), List.append(List.append(acc, curr), mid))
		}) } else { gr_expand_loop(pts, n, (i + 1), List.append(acc, curr)) }) } else { gr_expand_loop(pts, n, (i + 1), List.append(acc, curr)) })
	}) })

	gr_wrap : I64, I64 -> I64
	gr_wrap = |i, n| (if (i >= n) { (i - n) } else { i })

	gr_flatten_contour : List(GlyphRasterizer.ScaledPoint) -> List(GlyphRasterizer.Edge)
	gr_flatten_contour = |pts| ({
		n = U64.to_i64_wrap(List.len(pts))
		(if (n < 2) { [] } else { gr_flatten_loop(pts, n, 0, []) })
	})

	gr_flatten_loop : List(GlyphRasterizer.ScaledPoint), I64, I64, List(GlyphRasterizer.Edge) -> List(GlyphRasterizer.Edge)
	gr_flatten_loop = |pts, n, i, acc| (if (i >= n) { acc } else { ({
		curr = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (curr.sp_on > 0) { ({
			j = gr_wrap((i + 1), n)
			next = (List.get(pts, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))
			(if (next.sp_on > 0) { ({
				edge = { e_x0: curr.sp_x, e_y0: curr.sp_y, e_x1: next.sp_x, e_y1: next.sp_y }
				gr_flatten_loop(pts, n, (i + 1), List.append(acc, edge))
			}) } else { ({
				k = gr_wrap((j + 1), n)
				after = (List.get(pts, I64.to_u64_wrap(k)) ?? crash("list-at out of range"))
				on_pt = (if (after.sp_on > 0) { after } else { sp_new(I64.div_trunc_by((next.sp_x + after.sp_x), 2), I64.div_trunc_by((next.sp_y + after.sp_y), 2), 1) })
				new_edges = gr_flatten_quad(curr, next, on_pt, 0, acc)
				gr_flatten_loop(pts, n, (i + 1), new_edges)
			}) })
		}) } else { gr_flatten_loop(pts, n, (i + 1), acc) })
	}) })

	gr_flatten_quad : GlyphRasterizer.ScaledPoint, GlyphRasterizer.ScaledPoint, GlyphRasterizer.ScaledPoint, I64, List(GlyphRasterizer.Edge) -> List(GlyphRasterizer.Edge)
	gr_flatten_quad = |p0, p1, p2, depth, acc| ({
		dx = (p1.sp_x - I64.div_trunc_by((p0.sp_x + p2.sp_x), 2))
		dy = (p1.sp_y - I64.div_trunc_by((p0.sp_y + p2.sp_y), 2))
		dist = (gr_abs(dx) + gr_abs(dy))
		(if (dist < 32) { List.append(acc, { e_x0: p0.sp_x, e_y0: p0.sp_y, e_x1: p2.sp_x, e_y1: p2.sp_y }) } else { (if (depth > 8) { List.append(acc, { e_x0: p0.sp_x, e_y0: p0.sp_y, e_x1: p2.sp_x, e_y1: p2.sp_y }) } else { ({
			m01 = sp_new(I64.div_trunc_by((p0.sp_x + p1.sp_x), 2), I64.div_trunc_by((p0.sp_y + p1.sp_y), 2), 0)
			m12 = sp_new(I64.div_trunc_by((p1.sp_x + p2.sp_x), 2), I64.div_trunc_by((p1.sp_y + p2.sp_y), 2), 0)
			mid = sp_new(I64.div_trunc_by((m01.sp_x + m12.sp_x), 2), I64.div_trunc_by((m01.sp_y + m12.sp_y), 2), 1)
			left = gr_flatten_quad(p0, m01, mid, (depth + 1), acc)
			gr_flatten_quad(mid, m12, p2, (depth + 1), left)
		}) }) })
	})

	gr_abs : I64 -> I64
	gr_abs = |x| (if (x < 0) { (-x) } else { x })

	gr_render_edges : List(GlyphRasterizer.Edge), I64, I64, I64, I64 -> List(I64)
	gr_render_edges = |edges, width, height, y_min, y_max| gr_scanline_loop(edges, width, height, y_min, y_max, y_min, gr_make_row((width * height), 0))

	# gr_make_row builds its list by pushing onto a recursive call; emitted as an accumulator loop, which needs no stack as deep as the list is long.
	gr_make_row : I64, I64 -> List(I64)
	gr_make_row = |n, val| gr_make_row_acc(n, val, [])

	gr_make_row_acc : I64, I64, List(I64) -> List(I64)
	gr_make_row_acc = |n, val, acc| (if (n <= 0) { Prelude.push_backwards([], acc) } else { gr_make_row_acc((n - 1), val, List.append(acc, val)) })

	gr_scanline_loop : List(GlyphRasterizer.Edge), I64, I64, I64, I64, I64, List(I64) -> List(I64)
	gr_scanline_loop = |edges, width, height, y_min, y_max, y, pixels| (if (y >= y_max) { pixels } else { ({
		scan_y = ((y * 64) + 32)
		hits = gr_find_intersections(edges, scan_y, 0, [])
		sorted = gr_sort_ints(hits)
		filled = gr_fill_scanline(sorted, width, (y - y_min), pixels, 0, 0)
		gr_scanline_loop(edges, width, height, y_min, y_max, (y + 1), filled)
	}) })

	gr_find_intersections : List(GlyphRasterizer.Edge), I64, I64, List(I64) -> List(I64)
	gr_find_intersections = |edges, y, i, acc| (if (i >= U64.to_i64_wrap(List.len(edges))) { acc } else { ({
		e = (List.get(edges, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		y0 = e.e_y0
		y1 = e.e_y1
		lo = (if (y0 < y1) { y0 } else { y1 })
		hi = (if (y0 > y1) { y0 } else { y1 })
		(if (y < lo) { gr_find_intersections(edges, y, (i + 1), acc) } else { (if (y >= hi) { gr_find_intersections(edges, y, (i + 1), acc) } else { ({
			dy = (y1 - y0)
			(if (dy == 0) { gr_find_intersections(edges, y, (i + 1), acc) } else { ({
				x = (e.e_x0 + I64.div_trunc_by(((y - y0) * (e.e_x1 - e.e_x0)), dy))
				gr_find_intersections(edges, y, (i + 1), List.append(acc, x))
			}) })
		}) }) })
	}) })

	gr_fill_scanline : List(I64), I64, I64, List(I64), I64, I64 -> List(I64)
	gr_fill_scanline = |hits, width, row, pixels, i, winding| (if (i >= U64.to_i64_wrap(List.len(hits))) { pixels } else { ({
		x_fixed = (List.get(hits, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		x_px = I64.div_trunc_by(x_fixed, 64)
		(if ((i + 1) >= U64.to_i64_wrap(List.len(hits))) { pixels } else { ({
			x2_fixed = (List.get(hits, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range"))
			x2_px = I64.div_trunc_by(x2_fixed, 64)
			new_winding = (winding + 1)
			(if (new_winding != 0) { ({
				filled = gr_fill_span(pixels, width, row, x_px, x2_px)
				gr_fill_scanline(hits, width, row, filled, (i + 2), 0)
			}) } else { gr_fill_scanline(hits, width, row, pixels, (i + 1), new_winding) })
		}) })
	}) })

	gr_fill_span : List(I64), I64, I64, I64, I64 -> List(I64)
	gr_fill_span = |pixels, width, row, x0, x1| ({
		lo = (if (x0 < 0) { 0 } else { x0 })
		hi = (if (x1 >= width) { (width - 1) } else { x1 })
		gr_fill_span_loop(pixels, width, row, lo, hi)
	})

	gr_fill_span_loop : List(I64), I64, I64, I64, I64 -> List(I64)
	gr_fill_span_loop = |pixels, width, row, x, x1| (if (x > x1) { pixels } else { gr_fill_span_loop((List.set(pixels, I64.to_u64_wrap(((row * width) + x)), 255) ?? crash("list-set-at past the end")), width, row, (x + 1), x1) })

	gr_sort_ints : List(I64) -> List(I64)
	gr_sort_ints = |xs| gr_sort_loop(xs, 1)

	gr_sort_loop : List(I64), I64 -> List(I64)
	gr_sort_loop = |xs, i| (if (i >= U64.to_i64_wrap(List.len(xs))) { xs } else { ({
		key = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		sorted = gr_insert(xs, i, key, (i - 1))
		gr_sort_loop(sorted, (i + 1))
	}) })

	gr_insert : List(I64), I64, I64, I64 -> List(I64)
	gr_insert = |xs, pos, key, j| (if (j < 0) { (List.set(xs, I64.to_u64_wrap(0), key) ?? crash("list-set-at past the end")) } else { (if ((List.get(xs, I64.to_u64_wrap(j)) ?? crash("list-at out of range")) > key) { ({
		shifted = (List.set(xs, I64.to_u64_wrap((j + 1)), (List.get(xs, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		gr_insert(shifted, pos, key, (j - 1))
	}) } else { (List.set(xs, I64.to_u64_wrap((j + 1)), key) ?? crash("list-set-at past the end")) }) })

	gr_dim_ceiling : I64 -> I64
	gr_dim_ceiling = |ppem| ({
		scaled = (ppem * 4)
		(if (scaled < 16) { 16 } else { (if (scaled > 1024) { 1024 } else { scaled }) })
	})

	gr_clamp_dim : I64, I64 -> I64
	gr_clamp_dim = |v, ppem| ({
		ceiling = gr_dim_ceiling(ppem)
		(if (v < 1) { 1 } else { (if (v > ceiling) { ceiling } else { v }) })
	})

	gr_upem_ok : TrueType.TtfFont -> Bool
	gr_upem_ok = |font| (font.tf_head.th_units_per_em > 0)

	gr_blank_glyph : I64 -> GlyphRasterizer.RasterGlyph
	gr_blank_glyph = |codepoint| { rg_code: codepoint, rg_width: 1, rg_height: 1, rg_advance: 0, rg_pixels: gr_make_row(1, 0) }

	gr_render_glyph : TrueType.TtfFont, I64, I64 -> GlyphRasterizer.RasterGlyph
	gr_render_glyph = |font, codepoint, ppem| (if (gr_upem_ok(font) == False) { gr_blank_glyph(codepoint) } else { ({
		g = TrueType.ttf_glyph_for_char(font, codepoint)
		upem = font.tf_head.th_units_per_em
		x_off = (-g.tg_x_min)
		y_off = (-g.tg_y_min)
		w = (I64.div_trunc_by(((g.tg_x_max - g.tg_x_min) * ppem), upem) + 1)
		h = (I64.div_trunc_by(((g.tg_y_max - g.tg_y_min) * ppem), upem) + 1)
		adv = I64.div_trunc_by((g.tg_advance * ppem), upem)
		gw = gr_clamp_dim(w, ppem)
		gh = gr_clamp_dim(h, ppem)
		(if (U64.to_i64_wrap(List.len(g.tg_contours)) == 0) { { rg_code: codepoint, rg_width: gw, rg_height: gh, rg_advance: adv, rg_pixels: gr_make_row((gw * gh), 0) } } else { ({
			edges = gr_all_contour_edges(g.tg_contours, ppem, upem, x_off, y_off, 0, [])
			y_min_px = 0
			pixels = gr_render_edges(edges, gw, gh, y_min_px, gh)
			flipped = gr_flip_y(pixels, gw, gh)
			{ rg_code: codepoint, rg_width: gw, rg_height: gh, rg_advance: adv, rg_pixels: flipped }
		}) })
	}) })

	gr_glyph_max : I64, I64 -> I64
	gr_glyph_max = |a, b| (if (a > b) { a } else { b })

	gr_all_contour_edges : List(TrueType.TtfContour), I64, I64, I64, I64, I64, List(GlyphRasterizer.Edge) -> List(GlyphRasterizer.Edge)
	gr_all_contour_edges = |contours, ppem, upem, x_off, y_off, i, acc| (if (i >= U64.to_i64_wrap(List.len(contours))) { acc } else { ({
		c = (List.get(contours, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		scaled = gr_scale_contour(c, ppem, upem, x_off, y_off)
		expanded = gr_expand_midpoints(scaled)
		edges = gr_flatten_contour(expanded)
		gr_all_contour_edges(contours, ppem, upem, x_off, y_off, (i + 1), List.concat(acc, edges))
	}) })

	gr_flip_y : List(I64), I64, I64 -> List(I64)
	gr_flip_y = |pixels, width, height| gr_flip_y_loop(pixels, width, height, 0, [])

	gr_flip_y_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	gr_flip_y_loop = |pixels, width, height, y, acc| (if (y >= height) { acc } else { ({
		src_y = ((height - 1) - y)
		row = gr_copy_row(pixels, (src_y * width), width, 0, [])
		gr_flip_y_loop(pixels, width, height, (y + 1), List.concat(acc, row))
	}) })

	gr_copy_row : List(I64), I64, I64, I64, List(I64) -> List(I64)
	gr_copy_row = |pixels, off, width, x, acc| (if (x >= width) { acc } else { gr_copy_row(pixels, off, width, (x + 1), List.append(acc, (List.get(pixels, I64.to_u64_wrap((off + x))) ?? crash("list-at out of range")))) })

	gr_render_range : TrueType.TtfFont, I64, I64, I64, List(GlyphRasterizer.RasterGlyph) -> List(GlyphRasterizer.RasterGlyph)
	gr_render_range = |font, ppem, from, to, acc| (if (from > to) { acc } else { ({
		g = gr_render_glyph(font, from, ppem)
		gr_render_range(font, ppem, (from + 1), to, List.append(acc, g))
	}) })

	gr_render_ascii : TrueType.TtfFont, I64 -> List(GlyphRasterizer.RasterGlyph)
	gr_render_ascii = |font, ppem| gr_render_range(font, ppem, 32, 127, [])

	gr_render_glyph_aa : TrueType.TtfFont, I64, I64 -> GlyphRasterizer.RasterGlyph
	gr_render_glyph_aa = |font, codepoint, ppem| (if (gr_upem_ok(font) == False) { gr_blank_glyph(codepoint) } else { ({
		g = TrueType.ttf_glyph_for_char(font, codepoint)
		upem = font.tf_head.th_units_per_em
		x_off = (-g.tg_x_min)
		y_off = (-g.tg_y_min)
		w = (I64.div_trunc_by(((g.tg_x_max - g.tg_x_min) * ppem), upem) + 1)
		h = (I64.div_trunc_by(((g.tg_y_max - g.tg_y_min) * ppem), upem) + 1)
		adv = I64.div_trunc_by((g.tg_advance * ppem), upem)
		gw = gr_clamp_dim(w, ppem)
		gh = gr_clamp_dim(h, ppem)
		(if (U64.to_i64_wrap(List.len(g.tg_contours)) == 0) { { rg_code: codepoint, rg_width: gw, rg_height: gh, rg_advance: adv, rg_pixels: gr_make_row((gw * gh), 0) } } else { ({
			edges = gr_all_contour_edges(g.tg_contours, (ppem * 4), upem, x_off, y_off, 0, [])
			super_w = (gw * 4)
			super_h = (gh * 4)
			super_pixels = gr_render_edges(edges, super_w, super_h, 0, super_h)
			downsampled = gr_downsample_4x(super_pixels, super_w, super_h, gw, gh)
			flipped = gr_flip_y(downsampled, gw, gh)
			{ rg_code: codepoint, rg_width: gw, rg_height: gh, rg_advance: adv, rg_pixels: flipped }
		}) })
	}) })

	gr_downsample_4x : List(I64), I64, I64, I64, I64 -> List(I64)
	gr_downsample_4x = |super, sw, _sh, w, h| gr_ds_row(super, sw, w, h, 0, [])

	gr_ds_row : List(I64), I64, I64, I64, I64, List(I64) -> List(I64)
	gr_ds_row = |super, sw, w, h, y, acc| (if (y >= h) { acc } else { ({
		row = gr_ds_cols(super, sw, w, y, 0, [])
		gr_ds_row(super, sw, w, h, (y + 1), List.concat(acc, row))
	}) })

	gr_ds_cols : List(I64), I64, I64, I64, I64, List(I64) -> List(I64)
	gr_ds_cols = |super, sw, w, y, x, acc| (if (x >= w) { acc } else { ({
		sum = gr_ds_sample(super, sw, x, y)
		alpha = I64.div_trunc_by((sum * 255), 16)
		gr_ds_cols(super, sw, w, y, (x + 1), List.append(acc, alpha))
	}) })

	gr_ds_sample : List(I64), I64, I64, I64 -> I64
	gr_ds_sample = |super, sw, px, py| ({
		sx = (px * 4)
		sy = (py * 4)
		r0 = (((gr_ds_pixel(super, sw, (sx + 0), (sy + 0)) + gr_ds_pixel(super, sw, (sx + 1), (sy + 0))) + gr_ds_pixel(super, sw, (sx + 2), (sy + 0))) + gr_ds_pixel(super, sw, (sx + 3), (sy + 0)))
		r1 = (((gr_ds_pixel(super, sw, (sx + 0), (sy + 1)) + gr_ds_pixel(super, sw, (sx + 1), (sy + 1))) + gr_ds_pixel(super, sw, (sx + 2), (sy + 1))) + gr_ds_pixel(super, sw, (sx + 3), (sy + 1)))
		r2 = (((gr_ds_pixel(super, sw, (sx + 0), (sy + 2)) + gr_ds_pixel(super, sw, (sx + 1), (sy + 2))) + gr_ds_pixel(super, sw, (sx + 2), (sy + 2))) + gr_ds_pixel(super, sw, (sx + 3), (sy + 2)))
		r3 = (((gr_ds_pixel(super, sw, (sx + 0), (sy + 3)) + gr_ds_pixel(super, sw, (sx + 1), (sy + 3))) + gr_ds_pixel(super, sw, (sx + 2), (sy + 3))) + gr_ds_pixel(super, sw, (sx + 3), (sy + 3)))
		(((r0 + r1) + r2) + r3)
	})

	gr_ds_pixel : List(I64), I64, I64, I64 -> I64
	gr_ds_pixel = |super, sw, x, y| ({
		idx = ((y * sw) + x)
		(if (idx < 0) { 0 } else { (if (idx >= U64.to_i64_wrap(List.len(super))) { 0 } else { ({
			v = (List.get(super, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
			(if (v > 0) { 1 } else { 0 })
		}) }) })
	})

	gr_render_range_aa : TrueType.TtfFont, I64, I64, I64, List(GlyphRasterizer.RasterGlyph) -> List(GlyphRasterizer.RasterGlyph)
	gr_render_range_aa = |font, ppem, from, to, acc| (if (from > to) { acc } else { ({
		g = gr_render_glyph_aa(font, from, ppem)
		gr_render_range_aa(font, ppem, (from + 1), to, List.append(acc, g))
	}) })

	gr_render_ascii_aa : TrueType.TtfFont, I64 -> List(GlyphRasterizer.RasterGlyph)
	gr_render_ascii_aa = |font, ppem| gr_render_range_aa(font, ppem, 32, 127, [])
}
