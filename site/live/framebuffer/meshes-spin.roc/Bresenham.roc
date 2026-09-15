# Bresenham -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Bresenham :: [].{
	BresPoint : { bx : I64, by : I64 }

	bres_line : I64, I64, I64, I64 -> List(Bresenham.BresPoint)
	bres_line = |x0, y0, x1, y1| ({
		dx = bres_abs((x1 - x0))
		dy = (-bres_abs((y1 - y0)))
		sx = (if (x0 < x1) { 1 } else { (0 - 1) })
		sy = (if (y0 < y1) { 1 } else { (0 - 1) })
		bres_line_loop(x0, y0, x1, y1, dx, dy, sx, sy, (dx + dy), [])
	})

	bres_line_loop : I64, I64, I64, I64, I64, I64, I64, I64, I64, List(Bresenham.BresPoint) -> List(Bresenham.BresPoint)
	bres_line_loop = |x, y, x1, y1, dx, dy, sx, sy, err, acc| ({
		acc2 = List.append(acc, { bx: x, by: y })
		(if ((x == x1) and (y == y1)) { acc2 } else { ({
			e2 = (2 * err)
			new_err = (if (e2 >= dy) { (err + dy) } else { err })
			new_x = (if (e2 >= dy) { (x + sx) } else { x })
			new_err2 = (if (e2 <= dx) { (new_err + dx) } else { new_err })
			new_y = (if (e2 <= dx) { (y + sy) } else { y })
			bres_line_loop(new_x, new_y, x1, y1, dx, dy, sx, sy, new_err2, acc2)
		}) })
	})

	bres_circle : I64, I64, I64 -> List(Bresenham.BresPoint)
	bres_circle = |cx, cy, r| bres_circle_loop(cx, cy, r, 0, (-r), (1 - r), [])

	bres_circle_loop : I64, I64, I64, I64, I64, I64, List(Bresenham.BresPoint) -> List(Bresenham.BresPoint)
	bres_circle_loop = |cx, cy, r, x, y, err, acc| (if (x > (-y)) { acc } else { ({
		acc2 = bres_circle_octants(cx, cy, x, (-y), acc)
		new_err = ((err + (2 * x)) + 1)
		x2 = (x + 1)
		(if (new_err > 0) { bres_circle_loop(cx, cy, r, x2, (y + 1), (new_err + (2 * (y + 1))), acc2) } else { bres_circle_loop(cx, cy, r, x2, y, new_err, acc2) })
	}) })

	bres_circle_octants : I64, I64, I64, I64, List(Bresenham.BresPoint) -> List(Bresenham.BresPoint)
	bres_circle_octants = |cx, cy, x, y, acc| List.concat(acc, [{ bx: (cx + x), by: (cy + y) }, { bx: (cx - x), by: (cy + y) }, { bx: (cx + x), by: (cy - y) }, { bx: (cx - x), by: (cy - y) }, { bx: (cx + y), by: (cy + x) }, { bx: (cx - y), by: (cy + x) }, { bx: (cx + y), by: (cy - x) }, { bx: (cx - y), by: (cy - x) }])

	bres_abs : I64 -> I64
	bres_abs = |n| (if (n < 0) { (-n) } else { n })

	format_bres_point : Bresenham.BresPoint -> Str
	format_bres_point = |p| Str.concat(Str.concat(Str.concat(Str.concat("(", I64.to_str(p.bx)), ","), I64.to_str(p.by)), ")")

	format_bres_points : List(Bresenham.BresPoint) -> Str
	format_bres_points = |pts| format_bres_loop(pts, 0, U64.to_i64_wrap(List.len(pts)), "")

	format_bres_loop : List(Bresenham.BresPoint), I64, I64, Str -> Str
	format_bres_loop = |pts, i, len, acc| (if (i >= len) { acc } else { ({
		sep = (if (i == 0) { "" } else { " " })
		format_bres_loop(pts, (i + 1), len, Str.concat(Str.concat(acc, sep), format_bres_point((List.get(pts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })
}
