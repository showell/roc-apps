# SafariBrush -- the brush a Codex draw command names.
#
# Hand-written. `Brush` is every movie's and moved to movie/ when a second and
# a third arrived; this is the half that reads one out of a `Paint.DrawCmd`,
# which only Safari has. The tags are the blitter's, and so is what they mean.
import Paint
import lib.Brush

SafariBrush :: [].{
	# The brush a polygon command names. Tag 3, the disc, is not a polygon and
	# has no brush here; Raster and Shapes read its colour and alpha directly.
	of_command : Paint.DrawCmd -> Brush.Fill
	of_command = |c|
		if c.tag == 2 {
			x0 = geom(c, 0)
			x1 = geom(c, 1)
			if x1 == x0 { Skip } else { Span({ edge: Brush.opaque(c.color), middle: Brush.opaque(c.color2), x0, x1 }) }
		} else if c.tag == 4 {
			Radial({ inner: Brush.with_alpha(c.color), outer: Brush.with_alpha(c.color2), x: geom(c, 0), y: geom(c, 1), r0: 0.0, r1: geom(c, 2) })
		} else if c.tag == 5 {
			o0 = Brush.clamp01(geom(c, 0))
			o1 = F64.max(o0, F64.min(1.0, geom(c, 1)))
			ax = geom(c, 2)
			ay = geom(c, 3)
			dx = geom(c, 4) - ax
			dy = geom(c, 5) - ay
			len2 = dx * dx + dy * dy
			if len2 == 0.0 { Skip } else { Linear({ c0: Brush.with_alpha(c.color), c1: Brush.with_alpha(c.color2), o0, o1, ax, ay, dx, dy }) }
		} else if c.tag == 6 {
			o0 = Brush.clamp01(geom(c, 0))
			o1 = F64.max(o0, F64.min(1.0, geom(c, 1)))
			ux = geom(c, 4)
			uy = geom(c, 5)
			vx = geom(c, 6)
			vy = geom(c, 7)
			det = ux * vy - uy * vx
			if F64.abs(det) < 0.0001 {
				Flat(Brush.with_alpha(c.color))
			} else {
				Ellipse({ c0: Brush.with_alpha(c.color), c1: Brush.with_alpha(c.color2), o0, o1, x: geom(c, 2), y: geom(c, 3), ia: vy / det, ib: (0.0 - vx) / det, ic: (0.0 - uy) / det, id: ux / det })
			}
		} else {
			Flat(Brush.opaque(c.color))
		}
	geom : Paint.DrawCmd, U64 -> F64
	geom = |c, i| at(c.geom, i)

	at : List(F64), U64 -> F64
	at = |xs, i| List.get(xs, i) ?? 0.0
}
