# Vector -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cordic
import GlyphRasterizer
import MathLib

Vector :: [].{
	PathCmd : [PcMoveTo(I64, I64), PcLineTo(I64, I64), PcBezierTo(I64, I64, I64, I64, I64, I64), PcArcTo(I64, I64, I64, I64, I64), PcClose]
	VecPath : { vp_commands : List(Vector.PathCmd), vp_count : I64 }
	VecStyle : { vs_stroke_color : I64, vs_fill_color : I64, vs_stroke_width : I64, vs_filled : Bool, vs_stroked : Bool }
	VecPixel : { vpx_x : I64, vpx_y : I64, vpx_color : I64 }

	vec_path_new : Vector.VecPath
	vec_path_new = { vp_commands: [], vp_count: 0 }

	vec_move_to : Vector.VecPath, I64, I64 -> Vector.VecPath
	vec_move_to = |p, x, y| { vp_commands: List.append(p.vp_commands, PcMoveTo(x, y)), vp_count: (p.vp_count + 1) }

	vec_line_to : Vector.VecPath, I64, I64 -> Vector.VecPath
	vec_line_to = |p, x, y| { vp_commands: List.append(p.vp_commands, PcLineTo(x, y)), vp_count: (p.vp_count + 1) }

	vec_bezier_to : Vector.VecPath, I64, I64, I64, I64, I64, I64 -> Vector.VecPath
	vec_bezier_to = |p, cx1, cy1, cx2, cy2, x, y| { vp_commands: List.append(p.vp_commands, PcBezierTo(cx1, cy1, cx2, cy2, x, y)), vp_count: (p.vp_count + 1) }

	vec_arc_to : Vector.VecPath, I64, I64, I64, I64, I64 -> Vector.VecPath
	vec_arc_to = |p, cx, cy, rx, ry, angle| { vp_commands: List.append(p.vp_commands, PcArcTo(cx, cy, rx, ry, angle)), vp_count: (p.vp_count + 1) }

	vec_close : Vector.VecPath -> Vector.VecPath
	vec_close = |p| { vp_commands: List.append(p.vp_commands, PcClose), vp_count: (p.vp_count + 1) }

	vec_style_default : Vector.VecStyle
	vec_style_default = { vs_stroke_color: 0, vs_fill_color: 0, vs_stroke_width: 1000, vs_filled: False, vs_stroked: True }

	vec_style_fill : I64 -> Vector.VecStyle
	vec_style_fill = |color| { vs_stroke_color: 0, vs_fill_color: color, vs_stroke_width: 0, vs_filled: True, vs_stroked: False }

	vec_style_stroke : I64, I64 -> Vector.VecStyle
	vec_style_stroke = |color, width| { vs_stroke_color: color, vs_fill_color: 0, vs_stroke_width: width, vs_filled: False, vs_stroked: True }

	vec_rect : I64, I64, I64, I64 -> Vector.VecPath
	vec_rect = |x, y, w, h| ({
		p = vec_move_to(vec_path_new, x, y)
		p2 = vec_line_to(p, (x + w), y)
		p3 = vec_line_to(p2, (x + w), (y + h))
		p4 = vec_line_to(p3, x, (y + h))
		vec_close(p4)
	})

	vec_circle : I64, I64, I64, I64 -> Vector.VecPath
	vec_circle = |cx, cy, r, segments| vec_circle_loop(vec_path_new, cx, cy, r, segments, 0, True)

	vec_circle_loop : Vector.VecPath, I64, I64, I64, I64, I64, Bool -> Vector.VecPath
	vec_circle_loop = |p, cx, cy, r, segments, i, first| (if (i > segments) { vec_close(p) } else { ({
		angle = I64.div_trunc_by((i * 6283), segments)
		px = (cx + I64.div_trunc_by((r * Cordic.cordic_cos(angle)), 1000))
		py = (cy + I64.div_trunc_by((r * Cordic.cordic_sin(angle)), 1000))
		(if first { vec_circle_loop(vec_move_to(p, px, py), cx, cy, r, segments, (i + 1), False) } else { vec_circle_loop(vec_line_to(p, px, py), cx, cy, r, segments, (i + 1), False) })
	}) })

	vec_line : I64, I64, I64, I64 -> Vector.VecPath
	vec_line = |x1, y1, x2, y2| vec_line_to(vec_move_to(vec_path_new, x1, y1), x2, y2)

	vec_rasterize : Vector.VecPath, Vector.VecStyle -> List(Vector.VecPixel)
	vec_rasterize = |path, style| vec_stroke_edges(vec_edges(path, 1), 0, style.vs_stroke_color, [])

	vec_stroke_edges : List(GlyphRasterizer.Edge), I64, I64, List(Vector.VecPixel) -> List(Vector.VecPixel)
	vec_stroke_edges = |es, i, color, acc| (if (i >= U64.to_i64_wrap(List.len(es))) { acc } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		vec_stroke_edges(es, (i + 1), color, List.concat(acc, bresenham(e.e_x0, e.e_y0, e.e_x1, e.e_y1, color, [])))
	}) })

	bresenham : I64, I64, I64, I64, I64, List(Vector.VecPixel) -> List(Vector.VecPixel)
	bresenham = |x0, y0, x1, y1, color, acc| ({
		dx = (if (x1 > x0) { (x1 - x0) } else { (x0 - x1) })
		dy = (if (y1 > y0) { (y1 - y0) } else { (y0 - y1) })
		sx = (if (x0 < x1) { 1 } else { (0 - 1) })
		sy = (if (y0 < y1) { 1 } else { (0 - 1) })
		bresenham_loop(x0, y0, x1, y1, dx, dy, sx, sy, (dx - dy), color, acc)
	})

	bresenham_loop : I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, List(Vector.VecPixel) -> List(Vector.VecPixel)
	bresenham_loop = |x, y, x1, y1, dx, dy, sx, sy, err, color, acc| ({
		acc2 = List.append(acc, { vpx_x: x, vpx_y: y, vpx_color: color })
		(if (x == x1) { (if (y == y1) { acc2 } else { bresenham_step(x, y, x1, y1, dx, dy, sx, sy, err, color, acc2) }) } else { bresenham_step(x, y, x1, y1, dx, dy, sx, sy, err, color, acc2) })
	})

	bresenham_step : I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, List(Vector.VecPixel) -> List(Vector.VecPixel)
	bresenham_step = |x, y, x1, y1, dx, dy, sx, sy, err, color, acc| ({
		e2 = (err * 2)
		x2 = (if (e2 > (0 - dy)) { (x + sx) } else { x })
		y2 = (if (e2 < dx) { (y + sy) } else { y })
		err2 = ((err + (if (e2 > (0 - dy)) { (0 - dy) } else { 0 })) + (if (e2 < dx) { dx } else { 0 }))
		bresenham_loop(x2, y2, x1, y1, dx, dy, sx, sy, err2, color, acc)
	})

	vec_super : I64
	vec_super = 4

	vec_sub : I64
	vec_sub = 64

	vec_abs : I64 -> I64
	vec_abs = |v| (if (v < 0) { (0 - v) } else { v })

	vec_min : I64, I64 -> I64
	vec_min = |a, b| (if (a < b) { a } else { b })

	vec_max : I64, I64 -> I64
	vec_max = |a, b| (if (a > b) { a } else { b })

	vec_seg : List(GlyphRasterizer.Edge), I64, I64, I64, I64 -> List(GlyphRasterizer.Edge)
	vec_seg = |acc, x0, y0, x1, y1| List.append(acc, { e_x0: x0, e_y0: y0, e_x1: x1, e_y1: y1 })

	vec_cubic : List(GlyphRasterizer.Edge), I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 -> List(GlyphRasterizer.Edge)
	vec_cubic = |acc, k, x0, y0, x1, y1, x2, y2, x3, y3, depth| ({
		flat = (vec_abs((((x0 + x3) - x1) - x2)) + vec_abs((((y0 + y3) - y1) - y2)))
		(if (depth >= 8) { vec_seg(acc, x0, y0, x3, y3) } else { (if (flat <= k) { vec_seg(acc, x0, y0, x3, y3) } else { ({
			ax = I64.div_trunc_by((x0 + x1), 2)
			ay = I64.div_trunc_by((y0 + y1), 2)
			bx = I64.div_trunc_by((x1 + x2), 2)
			by = I64.div_trunc_by((y1 + y2), 2)
			cx = I64.div_trunc_by((x2 + x3), 2)
			cy = I64.div_trunc_by((y2 + y3), 2)
			dx = I64.div_trunc_by((ax + bx), 2)
			dy = I64.div_trunc_by((ay + by), 2)
			ex = I64.div_trunc_by((bx + cx), 2)
			ey = I64.div_trunc_by((by + cy), 2)
			mx = I64.div_trunc_by((dx + ex), 2)
			my = I64.div_trunc_by((dy + ey), 2)
			left = vec_cubic(acc, k, x0, y0, ax, ay, dx, dy, mx, my, (depth + 1))
			vec_cubic(left, k, mx, my, ex, ey, cx, cy, x3, y3, (depth + 1))
		}) }) })
	})

	vec_arc_steps : I64 -> I64
	vec_arc_steps = |angle| (1 + I64.div_trunc_by((vec_abs(angle) * 16), Cordic.cordic_pi))

	vec_arc_x : I64, I64, I64 -> I64
	vec_arc_x = |cx, rx, a| (cx + I64.div_trunc_by((rx * Cordic.cordic_cos(a)), Cordic.cordic_scale))

	vec_arc_y : I64, I64, I64 -> I64
	vec_arc_y = |cy, ry, a| (cy + I64.div_trunc_by((ry * Cordic.cordic_sin(a)), Cordic.cordic_scale))

	vec_arc_edges : List(GlyphRasterizer.Edge), I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 -> List(GlyphRasterizer.Edge)
	vec_arc_edges = |acc, cx, cy, rx, ry, a0, sweep, n, i, px, py| (if (i > n) { acc } else { ({
		a = (a0 + I64.div_trunc_by((sweep * i), n))
		x = vec_arc_x(cx, rx, a)
		y = vec_arc_y(cy, ry, a)
		vec_arc_edges(vec_seg(acc, px, py, x, y), cx, cy, rx, ry, a0, sweep, n, (i + 1), x, y)
	}) })

	vec_arc_start : I64, I64, I64, I64 -> I64
	vec_arc_start = |cx, cy, px, py| Cordic.cordic_atan2((py - cy), (px - cx)).angle

	vec_edges : Vector.VecPath, I64 -> List(GlyphRasterizer.Edge)
	vec_edges = |p, k| vec_edge_cmds(p.vp_commands, 0, p.vp_count, k, 0, 0, 0, 0, [])

	vec_edge_cmds : List(Vector.PathCmd), I64, I64, I64, I64, I64, I64, I64, List(GlyphRasterizer.Edge) -> List(GlyphRasterizer.Edge)
	vec_edge_cmds = |cmds, i, len, k, cx, cy, sx, sy, acc| (if (i >= len) { acc } else { ({
		cmd = (List.get(cmds, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(match cmd {
			PcMoveTo(x, y) => vec_edge_cmds(cmds, (i + 1), len, k, (x * k), (y * k), (x * k), (y * k), acc)
			PcLineTo(x, y) => vec_edge_cmds(cmds, (i + 1), len, k, (x * k), (y * k), sx, sy, vec_seg(acc, cx, cy, (x * k), (y * k)))
			PcBezierTo(c1x, c1y, c2x, c2y, x, y) => vec_edge_cmds(cmds, (i + 1), len, k, (x * k), (y * k), sx, sy, vec_cubic(acc, k, cx, cy, (c1x * k), (c1y * k), (c2x * k), (c2y * k), (x * k), (y * k), 0))
			PcArcTo(ax, ay, rx, ry, ang) => ({
				a0 = vec_arc_start((ax * k), (ay * k), cx, cy)
				n = vec_arc_steps(ang)
				ex = vec_arc_x((ax * k), (rx * k), (a0 + ang))
				ey = vec_arc_y((ay * k), (ry * k), (a0 + ang))
				vec_edge_cmds(cmds, (i + 1), len, k, ex, ey, sx, sy, vec_arc_edges(acc, (ax * k), (ay * k), (rx * k), (ry * k), a0, ang, n, 1, cx, cy))
			})
			PcClose => vec_edge_cmds(cmds, (i + 1), len, k, sx, sy, sx, sy, vec_seg(acc, cx, cy, sx, sy))
		})
	}) })

	vec_coverage : Vector.VecPath, I64, I64 -> List(I64)
	vec_coverage = |p, w, h| ({
		sw = (w * vec_super)
		sh = (h * vec_super)
		edges = vec_edges(p, (vec_super * vec_sub))
		GlyphRasterizer.gr_downsample_4x(GlyphRasterizer.gr_render_edges(edges, sw, sh, 0, sh), sw, sh, w, h)
	})

	vec_coverage_in : Vector.VecPath, I64, I64 -> List(I64)
	vec_coverage_in = |p, em, n| (if (em <= 0) { vec_coverage(p, n, n) } else { ({
		sw = (n * vec_super)
		edges = vec_edges(p, I64.div_trunc_by(((vec_super * vec_sub) * n), em))
		GlyphRasterizer.gr_downsample_4x(GlyphRasterizer.gr_render_edges(edges, sw, sw, 0, sw), sw, sw, n, n)
	}) })

	vec_coverage_at : List(I64), I64, I64, I64 -> I64
	vec_coverage_at = |cov, w, x, y| (List.get(cov, I64.to_u64_wrap(((y * w) + x))) ?? crash("list-at out of range"))

	vec_half_w : I64, I64 -> I64
	vec_half_w = |width, k| I64.div_trunc_by((width * k), 2)

	vec_quad : I64, I64, I64, I64, I64 -> List(GlyphRasterizer.Edge)
	vec_quad = |x0, y0, x1, y1, hw| ({
		ex = (x1 - x0)
		ey = (y1 - y0)
		len = MathLib.math_isqrt(((ex * ex) + (ey * ey)))
		(if (len <= 0) { [] } else { ({
			ux = I64.div_trunc_by((ex * hw), len)
			uy = I64.div_trunc_by((ey * hw), len)
			nx = (0 - uy)
			ny = ux
			ax = ((x0 - ux) + nx)
			ay = ((y0 - uy) + ny)
			bx = ((x1 + ux) + nx)
			by = ((y1 + uy) + ny)
			cx = ((x1 + ux) - nx)
			cy = ((y1 + uy) - ny)
			dx = ((x0 - ux) - nx)
			dy = ((y0 - uy) - ny)
			vec_seg(vec_seg(vec_seg(vec_seg([], ax, ay, bx, by), bx, by, cx, cy), cx, cy, dx, dy), dx, dy, ax, ay)
		}) })
	})

	vec_edges_min_y : List(GlyphRasterizer.Edge), I64, I64, I64 -> I64
	vec_edges_min_y = |es, i, n, m| (if (i >= n) { m } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		vec_edges_min_y(es, (i + 1), n, vec_min(m, vec_min(e.e_y0, e.e_y1)))
	}) })

	vec_edges_max_y : List(GlyphRasterizer.Edge), I64, I64, I64 -> I64
	vec_edges_max_y = |es, i, n, m| (if (i >= n) { m } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		vec_edges_max_y(es, (i + 1), n, vec_max(m, vec_max(e.e_y0, e.e_y1)))
	}) })

	vec_cov_max : List(I64), List(I64), I64, I64, I64, I64 -> List(I64)
	vec_cov_max = |acc, band, sw, row0, n, i| (if (i >= n) { acc } else { ({
		v = (List.get(band, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (v <= 0) { vec_cov_max(acc, band, sw, row0, n, (i + 1)) } else { ({
			idx = ((row0 * sw) + i)
			(if (v <= (List.get(acc, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))) { vec_cov_max(acc, band, sw, row0, n, (i + 1)) } else { vec_cov_max((List.set(acc, I64.to_u64_wrap(idx), v) ?? crash("list-set-at past the end")), band, sw, row0, n, (i + 1)) })
		}) })
	}) })

	vec_stroke_seg : List(I64), I64, I64, I64, I64, I64, I64, I64 -> List(I64)
	vec_stroke_seg = |acc, sw, sh, x0, y0, x1, y1, hw| ({
		q = vec_quad(x0, y0, x1, y1, hw)
		(if (U64.to_i64_wrap(List.len(q)) == 0) { acc } else { ({
			lo0 = I64.div_trunc_by(vec_edges_min_y(q, 0, U64.to_i64_wrap(List.len(q)), 999999999), vec_sub)
			hi0 = (I64.div_trunc_by(vec_edges_max_y(q, 0, U64.to_i64_wrap(List.len(q)), (0 - 999999999)), vec_sub) + 1)
			lo = vec_max(0, lo0)
			hi = vec_min(sh, hi0)
			(if (hi <= lo) { acc } else { vec_cov_max(acc, GlyphRasterizer.gr_render_edges(q, sw, (hi - lo), lo, hi), sw, lo, (sw * (hi - lo)), 0) })
		}) })
	})

	vec_stroke_loop : List(I64), List(GlyphRasterizer.Edge), I64, I64, I64, I64, I64 -> List(I64)
	vec_stroke_loop = |acc, es, i, n, sw, sh, hw| (if (i >= n) { acc } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		vec_stroke_loop(vec_stroke_seg(acc, sw, sh, e.e_x0, e.e_y0, e.e_x1, e.e_y1, hw), es, (i + 1), n, sw, sh, hw)
	}) })

	vec_stroke_cov_k : Vector.VecPath, I64, I64, I64, I64, I64, I64 -> List(I64)
	vec_stroke_cov_k = |p, sw, sh, w, h, hw, k| ({
		es = vec_edges(p, k)
		acc = GlyphRasterizer.gr_make_row((sw * sh), 0)
		GlyphRasterizer.gr_downsample_4x(vec_stroke_loop(acc, es, 0, U64.to_i64_wrap(List.len(es)), sw, sh, hw), sw, sh, w, h)
	})

	vec_stroke_coverage : Vector.VecPath, I64, I64, I64 -> List(I64)
	vec_stroke_coverage = |p, w, h, width| ({
		k = (vec_super * vec_sub)
		vec_stroke_cov_k(p, (w * vec_super), (h * vec_super), w, h, vec_half_w(width, k), k)
	})

	vec_stroke_coverage_in : Vector.VecPath, I64, I64, I64 -> List(I64)
	vec_stroke_coverage_in = |p, em, n, width| (if (em <= 0) { vec_stroke_coverage(p, n, n, width) } else { ({
		k = I64.div_trunc_by(((vec_super * vec_sub) * n), em)
		vec_stroke_cov_k(p, (n * vec_super), (n * vec_super), n, n, vec_half_w(width, k), k)
	}) })

	vec_path_length : Vector.VecPath -> I64
	vec_path_length = |p| p.vp_count

	vec_bounds : Vector.VecPath -> List(I64)
	vec_bounds = |p| ({
		es = vec_edges(p, 1)
		(if (U64.to_i64_wrap(List.len(es)) == 0) { vec_bounds_cmds(p.vp_commands, 0, p.vp_count, 999999, 999999, (0 - 999999), (0 - 999999)) } else { vec_bounds_loop(es, 0, U64.to_i64_wrap(List.len(es)), 999999, 999999, (0 - 999999), (0 - 999999)) })
	})

	vec_bounds_loop : List(GlyphRasterizer.Edge), I64, I64, I64, I64, I64, I64 -> List(I64)
	vec_bounds_loop = |es, i, len, min_x, min_y, max_x, max_y| (if (i >= len) { [min_x, min_y, max_x, max_y] } else { ({
		e = (List.get(es, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		nx = vec_min(min_x, vec_min(e.e_x0, e.e_x1))
		ny = vec_min(min_y, vec_min(e.e_y0, e.e_y1))
		xx = vec_max(max_x, vec_max(e.e_x0, e.e_x1))
		xy = vec_max(max_y, vec_max(e.e_y0, e.e_y1))
		vec_bounds_loop(es, (i + 1), len, nx, ny, xx, xy)
	}) })

	vec_bounds_cmds : List(Vector.PathCmd), I64, I64, I64, I64, I64, I64 -> List(I64)
	vec_bounds_cmds = |cmds, i, len, min_x, min_y, max_x, max_y| (if (i >= len) { [min_x, min_y, max_x, max_y] } else { ({
		cmd = (List.get(cmds, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(match cmd {
			PcMoveTo(x, y) => vec_bounds_cmds(cmds, (i + 1), len, vec_min(min_x, x), vec_min(min_y, y), vec_max(max_x, x), vec_max(max_y, y))
			_ => vec_bounds_cmds(cmds, (i + 1), len, min_x, min_y, max_x, max_y)
		})
	}) })

	eq_PathCmd : Vector.PathCmd, Vector.PathCmd -> Bool
	eq_PathCmd = |ex, ey| (match ex {
		PcMoveTo(exf0, exf1) => (match ey {
			PcMoveTo(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		PcLineTo(exf0, exf1) => (match ey {
			PcLineTo(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		PcBezierTo(exf0, exf1, exf2, exf3, exf4, exf5) => (match ey {
			PcBezierTo(eyf0, eyf1, eyf2, eyf3, eyf4, eyf5) => ((((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4)) and (exf5 == eyf5))
			_ => False
		})
		PcArcTo(exf0, exf1, exf2, exf3, exf4) => (match ey {
			PcArcTo(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
			_ => False
		})
		PcClose => (match ey {
			PcClose => True
			_ => False
		})
	})
}
