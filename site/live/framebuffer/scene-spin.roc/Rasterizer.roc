# Rasterizer -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Bresenham
import Geometry
import MathLib

Rasterizer :: [].{
	Framebuf : { fb_width : I64, fb_height : I64, fb_pixels : List(I64) }
	TriSorted : { ts_ax : I64, ts_ay : I64, ts_bx : I64, ts_by : I64, ts_cx : I64, ts_cy : I64 }

	fb_new : I64, I64, I64 -> Rasterizer.Framebuf
	fb_new = |w, h, bg| { fb_width: w, fb_height: h, fb_pixels: fb_fill((w * h), bg) }

	fb_fill : I64, I64 -> List(I64)
	fb_fill = |n, val| fb_fill_loop(n, val, [])

	fb_fill_loop : I64, I64, List(I64) -> List(I64)
	fb_fill_loop = |n, val, acc| (if (n <= 0) { acc } else { fb_fill_loop((n - 1), val, List.append(acc, val)) })

	fb_set : Rasterizer.Framebuf, I64, I64, I64 -> Rasterizer.Framebuf
	fb_set = |fb, x, y, color| (if (x < 0) { fb } else { (if (y < 0) { fb } else { (if (x >= fb.fb_width) { fb } else { (if (y >= fb.fb_height) { fb } else { { fb_width: fb.fb_width, fb_height: fb.fb_height, fb_pixels: (List.set(fb.fb_pixels, I64.to_u64_wrap(((y * fb.fb_width) + x)), color) ?? crash("list-set-at past the end")) } }) }) }) })

	fb_get : Rasterizer.Framebuf, I64, I64 -> I64
	fb_get = |fb, x, y| (if (x < 0) { 0 } else { (if (y < 0) { 0 } else { (if (x >= fb.fb_width) { 0 } else { (if (y >= fb.fb_height) { 0 } else { (List.get(fb.fb_pixels, I64.to_u64_wrap(((y * fb.fb_width) + x))) ?? crash("list-at out of range")) }) }) }) })

	fb_hline : Rasterizer.Framebuf, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_hline = |fb, x0, x1, y, color| (if (y < 0) { fb } else { (if (y >= fb.fb_height) { fb } else { ({
		lo = rast_max(x0, 0)
		hi = rast_min(x1, (fb.fb_width - 1))
		fb_hline_loop(fb, lo, hi, y, color)
	}) }) })

	fb_hline_loop : Rasterizer.Framebuf, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_hline_loop = |fb, x, x1, y, color| (if (x > x1) { fb } else { fb_hline_loop(fb_set(fb, x, y, color), (x + 1), x1, y, color) })

	fb_line : Rasterizer.Framebuf, I64, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_line = |fb, x0, y0, x1, y1, color| ({
		pts = Bresenham.bres_line(x0, y0, x1, y1)
		fb_plot_points(fb, pts, color, 0, U64.to_i64_wrap(List.len(pts)))
	})

	fb_plot_points : Rasterizer.Framebuf, List(Bresenham.BresPoint), I64, I64, I64 -> Rasterizer.Framebuf
	fb_plot_points = |fb, pts, color, i, n| (if (i >= n) { fb } else { ({
		p = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		fb_plot_points(fb_set(fb, p.bx, p.by, color), pts, color, (i + 1), n)
	}) })

	fb_circle : Rasterizer.Framebuf, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_circle = |fb, cx, cy, r, color| ({
		pts = Bresenham.bres_circle(cx, cy, r)
		fb_plot_points(fb, pts, color, 0, U64.to_i64_wrap(List.len(pts)))
	})

	fb_circle_filled : Rasterizer.Framebuf, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_circle_filled = |fb, cx, cy, r, color| fb_fill_circle_loop(fb, cx, cy, r, (-r), color)

	fb_fill_circle_loop : Rasterizer.Framebuf, I64, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_fill_circle_loop = |fb, cx, cy, r, dy, color| (if (dy > r) { fb } else { ({
		dx = MathLib.math_isqrt(((r * r) - (dy * dy)))
		fb2 = fb_hline(fb, (cx - dx), (cx + dx), (cy + dy), color)
		fb_fill_circle_loop(fb2, cx, cy, r, (dy + 1), color)
	}) })

	fb_tri : Rasterizer.Framebuf, I64, I64, I64, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_tri = |fb, x0, y0, x1, y1, x2, y2, color| ({
		sorted = rast_sort_tri(x0, y0, x1, y1, x2, y2)
		ay = rast_tri_ay(sorted)
		by = rast_tri_by(sorted)
		cy = rast_tri_cy(sorted)
		ax = rast_tri_ax(sorted)
		bx = rast_tri_bx(sorted)
		cx = rast_tri_cx(sorted)
		fb_tri_scan(fb, ax, ay, bx, by, cx, cy, color)
	})

	fb_tri_scan : Rasterizer.Framebuf, I64, I64, I64, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_tri_scan = |fb, ax, ay, bx, by, cx, cy, color| ({
		fb2 = fb_tri_half(fb, ax, ay, bx, by, cx, cy, ay, by, color)
		fb_tri_half(fb2, ax, ay, bx, by, cx, cy, by, cy, color)
	})

	fb_tri_half : Rasterizer.Framebuf, I64, I64, I64, I64, I64, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_tri_half = |fb, ax, ay, bx, by, cx, cy, y_start, y_end, color| (if (y_start > y_end) { fb } else { (if (y_start >= fb.fb_height) { fb } else { ({
		y = y_start
		x_ac = rast_edge_x(ax, ay, cx, cy, y)
		x_side = (if (y < by) { rast_edge_x(ax, ay, bx, by, y) } else { rast_edge_x(bx, by, cx, cy, y) })
		lo = rast_min(x_ac, x_side)
		hi = rast_max(x_ac, x_side)
		fb2 = (if (y >= 0) { fb_hline(fb, lo, hi, y, color) } else { fb })
		fb_tri_half(fb2, ax, ay, bx, by, cx, cy, (y_start + 1), y_end, color)
	}) }) })

	rast_edge_x : I64, I64, I64, I64, I64 -> I64
	rast_edge_x = |x0, y0, x1, y1, y| ({
		dy = (y1 - y0)
		(if (dy == 0) { x0 } else { (x0 + I64.div_trunc_by(((x1 - x0) * (y - y0)), dy)) })
	})

	rast_sort_tri : I64, I64, I64, I64, I64, I64 -> Rasterizer.TriSorted
	rast_sort_tri = |x0, y0, x1, y1, x2, y2| (if (y0 <= y1) { (if (y1 <= y2) { { ts_ax: x0, ts_ay: y0, ts_bx: x1, ts_by: y1, ts_cx: x2, ts_cy: y2 } } else { (if (y0 <= y2) { { ts_ax: x0, ts_ay: y0, ts_bx: x2, ts_by: y2, ts_cx: x1, ts_cy: y1 } } else { { ts_ax: x2, ts_ay: y2, ts_bx: x0, ts_by: y0, ts_cx: x1, ts_cy: y1 } }) }) } else { (if (y0 <= y2) { { ts_ax: x1, ts_ay: y1, ts_bx: x0, ts_by: y0, ts_cx: x2, ts_cy: y2 } } else { (if (y1 <= y2) { { ts_ax: x1, ts_ay: y1, ts_bx: x2, ts_by: y2, ts_cx: x0, ts_cy: y0 } } else { { ts_ax: x2, ts_ay: y2, ts_bx: x1, ts_by: y1, ts_cx: x0, ts_cy: y0 } }) }) })

	rast_tri_ax : Rasterizer.TriSorted -> I64
	rast_tri_ax = |t| t.ts_ax

	rast_tri_ay : Rasterizer.TriSorted -> I64
	rast_tri_ay = |t| t.ts_ay

	rast_tri_bx : Rasterizer.TriSorted -> I64
	rast_tri_bx = |t| t.ts_bx

	rast_tri_by : Rasterizer.TriSorted -> I64
	rast_tri_by = |t| t.ts_by

	rast_tri_cx : Rasterizer.TriSorted -> I64
	rast_tri_cx = |t| t.ts_cx

	rast_tri_cy : Rasterizer.TriSorted -> I64
	rast_tri_cy = |t| t.ts_cy

	fb_rect : Rasterizer.Framebuf, I64, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_rect = |fb, x, y, w, h, color| fb_rect_loop(fb, x, y, w, ((y + h) - 1), color)

	fb_rect_loop : Rasterizer.Framebuf, I64, I64, I64, I64, I64 -> Rasterizer.Framebuf
	fb_rect_loop = |fb, x, y, w, y_end, color| (if (y > y_end) { fb } else { fb_rect_loop(fb_hline(fb, x, ((x + w) - 1), y, color), x, (y + 1), w, y_end, color) })

	fb_polygon : Rasterizer.Framebuf, List(Geometry.Vec2), I64 -> Rasterizer.Framebuf
	fb_polygon = |fb, pts, color| fb_poly_loop(fb, pts, color, 0, U64.to_i64_wrap(List.len(pts)))

	fb_poly_loop : Rasterizer.Framebuf, List(Geometry.Vec2), I64, I64, I64 -> Rasterizer.Framebuf
	fb_poly_loop = |fb, pts, color, i, n| (if (i >= n) { fb } else { ({
		j = (if ((i + 1) >= n) { 0 } else { (i + 1) })
		pi = (List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		pj = (List.get(pts, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))
		fb_poly_loop(fb_line(fb, F64.to_i64_wrap(pi.v2x), F64.to_i64_wrap(pi.v2y), F64.to_i64_wrap(pj.v2x), F64.to_i64_wrap(pj.v2y), color), pts, color, (i + 1), n)
	}) })

	fb_count_color : Rasterizer.Framebuf, I64 -> I64
	fb_count_color = |fb, color| fb_count_loop(fb.fb_pixels, color, 0, U64.to_i64_wrap(List.len(fb.fb_pixels)), 0)

	fb_count_loop : List(I64), I64, I64, I64, I64 -> I64
	fb_count_loop = |px, color, i, n, acc| (if (i >= n) { acc } else { ({
		inc = (if ((List.get(px, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == color) { 1 } else { 0 })
		fb_count_loop(px, color, (i + 1), n, (acc + inc))
	}) })

	rast_min : I64, I64 -> I64
	rast_min = |a, b| (if (a < b) { a } else { b })

	rast_max : I64, I64 -> I64
	rast_max = |a, b| (if (a > b) { a } else { b })

	rast_abs : I64 -> I64
	rast_abs = |n| (if (n < 0) { (-n) } else { n })
}
