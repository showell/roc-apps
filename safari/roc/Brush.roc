# Brush -- the paint a draw command names, decoded once for every painter: a
# flat colour or one of the blitter's gradients, its geometry in scene
# coordinates. Raster shades a brush on the CPU; the roc-ray app hands one to a
# fragment shader that does the same arithmetic.
#
# Hand-written. The tags are blitter.js's, and so is what they mean: gradients
# mix unpremultiplied, as the canvas specification says, and an offset outside
# [0, 1] is clamped as the blitter clamps it.
import Paint

Brush :: [].{
	# Red, green and blue in 0..255, alpha in 0..1.
	Rgba : { r : F64, g : F64, b : F64, a : F64 }

	Fill : [
		Skip,
		Flat(Brush.Rgba),
		# Tag 2: edge, middle, edge, across [x0, x1].
		Span({ edge : Brush.Rgba, middle : Brush.Rgba, x0 : F64, x1 : F64 }),
		# Tag 4 (r0 0), and the sun's disc: from radius r0 to r1 about (x, y).
		Radial({ inner : Brush.Rgba, outer : Brush.Rgba, x : F64, y : F64, r0 : F64, r1 : F64 }),
		# Tag 5: two stops along a..a+d, at offsets o0 <= o1.
		Linear({ c0 : Brush.Rgba, c1 : Brush.Rgba, o0 : F64, o1 : F64, ax : F64, ay : F64, dx : F64, dy : F64, len2 : F64 }),
		# Tag 6: two stops out from (x, y) through the ellipse whose inverse is
		# ia ib / ic id, taking a scene offset to the unit circle.
		Ellipse({ c0 : Brush.Rgba, c1 : Brush.Rgba, o0 : F64, o1 : F64, x : F64, y : F64, ia : F64, ib : F64, ic : F64, id : F64 }),
		# The sun's glow: stops at 0, 0.4 and 1, from radius r0 to r1 about (x, y).
		Glow({ c0 : Brush.Rgba, c1 : Brush.Rgba, c2 : Brush.Rgba, x : F64, y : F64, r0 : F64, r1 : F64 }),
	]

	# The brush a polygon command names. Tag 3, the disc, is not a polygon and
	# has no brush here; Raster and Shapes read its colour and alpha directly.
	of_command : Paint.DrawCmd -> Brush.Fill
	of_command = |c|
		if c.tag == 2 {
			x0 = geom(c, 0)
			x1 = geom(c, 1)
			if x1 == x0 { Skip } else { Span({ edge: opaque(c.color), middle: opaque(c.color2), x0, x1 }) }
		} else if c.tag == 4 {
			Radial({ inner: with_alpha(c.color), outer: with_alpha(c.color2), x: geom(c, 0), y: geom(c, 1), r0: 0.0, r1: geom(c, 2) })
		} else if c.tag == 5 {
			o0 = clamp01(geom(c, 0))
			o1 = F64.max(o0, F64.min(1.0, geom(c, 1)))
			ax = geom(c, 2)
			ay = geom(c, 3)
			dx = geom(c, 4) - ax
			dy = geom(c, 5) - ay
			len2 = dx * dx + dy * dy
			if len2 == 0.0 { Skip } else { Linear({ c0: with_alpha(c.color), c1: with_alpha(c.color2), o0, o1, ax, ay, dx, dy, len2 }) }
		} else if c.tag == 6 {
			o0 = clamp01(geom(c, 0))
			o1 = F64.max(o0, F64.min(1.0, geom(c, 1)))
			ux = geom(c, 4)
			uy = geom(c, 5)
			vx = geom(c, 6)
			vy = geom(c, 7)
			det = ux * vy - uy * vx
			if F64.abs(det) < 0.0001 {
				Flat(with_alpha(c.color))
			} else {
				Ellipse({ c0: with_alpha(c.color), c1: with_alpha(c.color2), o0, o1, x: geom(c, 2), y: geom(c, 3), ia: vy / det, ib: (0.0 - vx) / det, ic: (0.0 - uy) / det, id: ux / det })
			}
		} else {
			Flat(opaque(c.color))
		}

	# The colour a brush gives the scene point (x, y).
	shade : Brush.Fill, F64, F64 -> Brush.Rgba
	shade = |fill, x, y|
		match fill {
			Skip => { r: 0.0, g: 0.0, b: 0.0, a: 0.0 }
			Flat(col) => col
			Span(p) => {
				t = clamp01((x - p.x0) / (p.x1 - p.x0))
				if t <= 0.5 { mix(p.edge, p.middle, t * 2.0) } else { mix(p.middle, p.edge, (t - 0.5) * 2.0) }
			}
			Radial(p) => {
				d = F64.sqrt((x - p.x) * (x - p.x) + (y - p.y) * (y - p.y))
				mix(p.inner, p.outer, if p.r1 > p.r0 { clamp01((d - p.r0) / (p.r1 - p.r0)) } else { 1.0 })
			}
			Linear(p) => two_stop(p.c0, p.o0, p.c1, p.o1, clamp01(((x - p.ax) * p.dx + (y - p.ay) * p.dy) / p.len2))
			Ellipse(p) => {
				qx = x - p.x
				qy = y - p.y
				ux = p.ia * qx + p.ib * qy
				uy = p.ic * qx + p.id * qy
				two_stop(p.c0, p.o0, p.c1, p.o1, clamp01(F64.sqrt(ux * ux + uy * uy)))
			}
			Glow(p) => {
				d = F64.sqrt((x - p.x) * (x - p.x) + (y - p.y) * (y - p.y))
				t = if p.r1 > p.r0 { clamp01((d - p.r0) / (p.r1 - p.r0)) } else { 1.0 }
				if t <= 0.4 { mix(p.c0, p.c1, t / 0.4) } else { mix(p.c1, p.c2, (t - 0.4) / 0.6) }
			}
		}

	at : List(F64), U64 -> F64
	at = |xs, i| List.get(xs, i) ?? 0.0

	geom : Paint.DrawCmd, U64 -> F64
	geom = |c, i| at(c.geom, i)

	chan : I64, U8 -> F64
	chan = |c, shift| I64.to_f64(I64.bitwise_and(I64.shr_wrap(c, shift), 255))

	# 0xRRGGBB, opaque.
	opaque : I64 -> Brush.Rgba
	opaque = |c| { r: chan(c, 16), g: chan(c, 8), b: chan(c, 0), a: 1.0 }

	# 0xAARRGGBB.
	with_alpha : I64 -> Brush.Rgba
	with_alpha = |c| { r: chan(c, 16), g: chan(c, 8), b: chan(c, 0), a: chan(c, 24) / 255.0 }

	mix : Brush.Rgba, Brush.Rgba, F64 -> Brush.Rgba
	mix = |p, q, t| { r: p.r + (q.r - p.r) * t, g: p.g + (q.g - p.g) * t, b: p.b + (q.b - p.b) * t, a: p.a + (q.a - p.a) * t }

	clamp01 : F64 -> F64
	clamp01 = |t| if t < 0.0 { 0.0 } else if t > 1.0 { 1.0 } else { t }

	# Two stops at offsets o0 <= o1: the first colour up to o0, the second from o1.
	two_stop : Brush.Rgba, F64, Brush.Rgba, F64, F64 -> Brush.Rgba
	two_stop = |c0, o0, c1, o1, t| if t <= o0 { c0 } else if t >= o1 { c1 } else { mix(c0, c1, (t - o0) / (o1 - o0)) }
}
