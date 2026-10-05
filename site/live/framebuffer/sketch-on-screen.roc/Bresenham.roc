# Bresenham -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Bresenham :: [].{
	BresPoint := { bx : I64, by : I64 }.{
		is_eq : Bresenham.BresPoint, Bresenham.BresPoint -> Bool
		is_eq = |a, b| eq_BresPoint(a, b)
	}

	bres_line : I64, I64, I64, I64 -> List(Bresenham.BresPoint)
	bres_line = |x0, y0, x1, y1| ({
		dx : I64
		dx = bres_abs((x1 - x0))
		dy : I64
		dy = (-bres_abs((y1 - y0)))
		sx : I64
		sx = (if (x0 < x1) { 1 } else { (0 - 1) })
		sy : I64
		sy = (if (y0 < y1) { 1 } else { (0 - 1) })
		bres_line_loop(x0, y0, x1, y1, dx, dy, sx, sy, (dx + dy), [])
	})

	bres_line_loop : I64, I64, I64, I64, I64, I64, I64, I64, I64, List(Bresenham.BresPoint) -> List(Bresenham.BresPoint)
	bres_line_loop = |x, y, x1, y1, dx, dy, sx, sy, err, acc| ({
		acc2 = List.append(acc, Bresenham.BresPoint.{ bx: x, by: y })
		(if ((x == x1) and (y == y1)) { acc2 } else { ({
			e2 : I64
			e2 = (2 * err)
			new_err : I64
			new_err = (if (e2 >= dy) { (err + dy) } else { err })
			new_x : I64
			new_x = (if (e2 >= dy) { (x + sx) } else { x })
			new_err2 : I64
			new_err2 = (if (e2 <= dx) { (new_err + dx) } else { new_err })
			new_y : I64
			new_y = (if (e2 <= dx) { (y + sy) } else { y })
			bres_line_loop(new_x, new_y, x1, y1, dx, dy, sx, sy, new_err2, acc2)
		}) })
	})

	bres_abs : I64 -> I64
	bres_abs = |n| (if (n < 0) { (-n) } else { n })

	eq_BresPoint : Bresenham.BresPoint, Bresenham.BresPoint -> Bool
	eq_BresPoint = |ex, ey| ((ex.bx == ey.bx) and (ex.by == ey.by))
}
