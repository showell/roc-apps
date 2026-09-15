# Shapes -- a Safari frame as shapes a drawing platform fills itself, each with
# the Brush it is painted with, in scene coordinates before the camera roll.
#
# Hand-written, for roc-ray, where roc-ray draws the frame and Roc does not
# paint pixels. roc-ray fills only convex polygons, so a concave one is cut into
# triangles by ear clipping; the pieces share the polygon's brush. A triangle
# comes out in the order raylib keeps: roc-ray's convex fill reverses a polygon
# whose signed area is positive, and its triangle passes the points through as
# given.
#
# The backdrop is the blitter's: the sky's linear gradient, the grass, and the
# sun's glow and disc clipped to the sky, the glow as a rectangle that is the
# clip and the disc marked sky-only.
import Paint
import Sky
import Brush

Shapes :: [].{
	Shape : [
		# A convex polygon, x0, y0, x1, y1, ...
		Convex({ pts : List(F64), fill : Brush.Fill }),
		# The triangles of one concave polygon, six numbers each.
		Pieces({ tris : List(F64), fill : Brush.Fill }),
		# A disc; `sky_only` keeps it to the sky, (0, 0) to (960, 300).
		Disc({ x : F64, y : F64, r : F64, fill : Brush.Fill, sky_only : Bool }),
		Rect({ x : F64, y : F64, w : F64, h : F64, fill : Brush.Fill }),
	]

	# The frame in paint order: the sky, the grass, the sun, then every command.
	frame : List(Paint.DrawCmd), I64, I64, Sky.SunPos -> List(Shapes.Shape)
	frame = |commands, sky_top, sky_horizon, sun| {
		var $out = List.with_capacity(2 * List.len(commands) + 8)
		# Oversized, as the blitter draws them, so the rolled frame's corners stay
		# filled: the top colour to a fifth of the way down to the horizon at y
		# 300, then the fade; the grass from a pixel above the horizon.
		sky = Linear({ c0: Brush.opaque(sky_top), c1: Brush.opaque(sky_horizon), o0: 0.2, o1: 1.0, ax: 0.0, ay: 0.0, dx: 0.0, dy: 300.0, len2: 90000.0 })
		$out = List.append($out, Rect({ x: -1080.0, y: -1260.0, w: 3120.0, h: 1560.0, fill: sky }))
		$out = List.append($out, Rect({ x: -1080.0, y: 299.0, w: 3120.0, h: 1561.0, fill: Flat(Brush.opaque(0x4a8f43)) }))
		$out = if sun.visible and sun.scale > 0.0 {
			glow = Glow({
				c0: { r: 255.0, g: 201.0, b: 128.0, a: 0.85 },
				c1: { r: 255.0, g: 150.0, b: 92.0, a: 0.32 },
				c2: { r: 255.0, g: 150.0, b: 92.0, a: 0.0 },
				x: sun.x,
				y: sun.y,
				r0: 8.0 * sun.scale,
				r1: 340.0 * sun.scale,
			})
			disc = Radial({ inner: Brush.opaque(0xffe6a3), outer: Brush.opaque(0xff9d5c), x: sun.x, y: sun.y, r0: 4.0 * sun.scale, r1: 46.0 * sun.scale })
			List.concat($out, [
				Rect({ x: 0.0, y: 0.0, w: 960.0, h: 300.0, fill: glow }),
				Disc({ x: sun.x, y: sun.y, r: 46.0 * sun.scale, fill: disc, sky_only: Bool.True }),
			])
		} else {
			$out
		}
		n = List.len(commands)
		var $k = 0
		while $k < n {
			$out = List.concat($out, of_command(List.get(commands, $k) ?? crash("command out of range")))
			$k = $k + 1
		}
		$out
	}

	# One command's shapes: a disc, or its polygon with its brush.
	of_command : Paint.DrawCmd -> List(Shapes.Shape)
	of_command = |c|
		if c.tag == 3 {
			col = Brush.opaque(c.color)
			[Disc({ x: Brush.geom(c, 0), y: Brush.geom(c, 1), r: Brush.geom(c, 2), fill: Flat({ ..col, a: c.strength }), sky_only: Bool.False })]
		} else {
			fill = Brush.of_command(c)
			match fill {
				Skip => []
				_ => polygon(c.pts, fill)
			}
		}

	polygon : List(F64), Brush.Fill -> List(Shapes.Shape)
	polygon = |pts, fill| {
		n = List.len(pts) // 2
		if n < 3 {
			[]
		} else if is_convex(pts) {
			[Convex({ pts, fill })]
		} else {
			[Pieces({ tris: wound(triangulate(pts)), fill })]
		}
	}

	# Each triangle wound as roc-ray's convex fill winds one: its second and
	# third corners swapped when its signed area is positive.
	wound : List(F64) -> List(F64)
	wound = |tris| {
		m = List.len(tris) // 6
		var $out = List.with_capacity(6 * m)
		var $k = 0
		while $k < m {
			b = 6 * $k
			ax = at(tris, b)
			ay = at(tris, b + 1)
			bx = at(tris, b + 2)
			by = at(tris, b + 3)
			cx = at(tris, b + 4)
			cy = at(tris, b + 5)
			$out = if cross3(ax, ay, bx, by, cx, cy) > 0.0 {
				List.concat($out, [ax, ay, cx, cy, bx, by])
			} else {
				List.concat($out, [ax, ay, bx, by, cx, cy])
			}
			$k = $k + 1
		}
		$out
	}

	# --- Geometry -------------------------------------------------------------

	at : List(F64), U64 -> F64
	at = |xs, i| List.get(xs, i) ?? 0.0

	cross3 : F64, F64, F64, F64, F64, F64 -> F64
	cross3 = |ax, ay, bx, by, cx, cy| (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

	# Twice the signed area, summed as roc-ray's host sums it.
	twice_area : List(F64) -> F64
	twice_area = |pts| {
		n = List.len(pts) // 2
		var $sum = 0.0
		var $k = 0
		while $k < n {
			k1 = if $k + 1 == n { 0 } else { $k + 1 }
			$sum = $sum + at(pts, 2 * $k) * at(pts, 2 * k1 + 1) - at(pts, 2 * k1) * at(pts, 2 * $k + 1)
			$k = $k + 1
		}
		$sum
	}

	# A convex boundary reverses its horizontal and vertical direction at most
	# twice each.
	flip_limit : U64
	flip_limit = 2

	# Convex when every corner turns the same way and the boundary reverses its
	# horizontal and vertical direction at most twice each, which rules out a
	# star whose corners all turn one way.
	is_convex : List(F64) -> Bool
	is_convex = |pts| {
		n = List.len(pts) // 2
		var $sign = 0.0
		var $bad = Bool.False
		var $xflips = 0
		var $yflips = 0
		var $xdir = 0.0
		var $ydir = 0.0
		var $k = 0
		while $k < n and !$bad {
			k1 = if $k + 1 >= n { $k + 1 - n } else { $k + 1 }
			k2 = if $k + 2 >= n { $k + 2 - n } else { $k + 2 }
			x0 = at(pts, 2 * $k)
			y0 = at(pts, 2 * $k + 1)
			x1 = at(pts, 2 * k1)
			y1 = at(pts, 2 * k1 + 1)
			turn = cross3(x0, y0, x1, y1, at(pts, 2 * k2), at(pts, 2 * k2 + 1))
			$bad = turn * $sign < 0.0
			$sign = if $sign == 0.0 { turn } else { $sign }
			dx = x1 - x0
			dy = y1 - y0
			$xflips = if dx != 0.0 and $xdir != 0.0 and (dx > 0.0) != ($xdir > 0.0) { $xflips + 1 } else { $xflips }
			$yflips = if dy != 0.0 and $ydir != 0.0 and (dy > 0.0) != ($ydir > 0.0) { $yflips + 1 } else { $yflips }
			$xdir = if dx != 0.0 { dx } else { $xdir }
			$ydir = if dy != 0.0 { dy } else { $ydir }
			$k = $k + 1
		}
		!$bad and $xflips <= flip_limit and $yflips <= flip_limit
	}

	# The polygon cut into triangles by ear clipping, six numbers a triangle. A
	# corner in line with its neighbours is dropped without a triangle. A polygon
	# that crosses itself can run out of ears; what is left is fanned.
	triangulate : List(F64) -> List(F64)
	triangulate = |pts| {
		n = List.len(pts) // 2
		orient = if twice_area(pts) >= 0.0 { 1.0 } else { -1.0 }
		var $idx = List.with_capacity(n)
		var $k = 0
		while $k < n {
			$idx = List.append($idx, $k)
			$k = $k + 1
		}
		var $out = List.with_capacity(6 * n)
		var $i = 0
		var $misses = 0
		while List.len($idx) > 3 and $misses < List.len($idx) {
			m = List.len($idx)
			ip = if $i == 0 { m - 1 } else { $i - 1 }
			inx = if $i + 1 >= m { 0 } else { $i + 1 }
			a = List.get($idx, ip) ?? crash("vertex out of range")
			b = List.get($idx, $i) ?? crash("vertex out of range")
			c = List.get($idx, inx) ?? crash("vertex out of range")
			ax = at(pts, 2 * a)
			ay = at(pts, 2 * a + 1)
			bx = at(pts, 2 * b)
			by = at(pts, 2 * b + 1)
			cx = at(pts, 2 * c)
			cy = at(pts, 2 * c + 1)
			turn = cross3(ax, ay, bx, by, cx, cy) * orient
			ear = turn >= 0.0 and !any_inside(pts, $idx, a, b, c, orient)
			$out = if ear and turn > 0.0 { List.concat($out, [ax, ay, bx, by, cx, cy]) } else { $out }
			$idx = if ear { List.drop_at($idx, $i) } else { $idx }
			$misses = if ear { 0 } else { $misses + 1 }
			$i = if ear { (if $i >= List.len($idx) { 0 } else { $i }) } else { inx }
		}
		fan(pts, $idx, $out)
	}

	# Whether a remaining corner other than a, b and c lies strictly inside the
	# triangle a b c.
	any_inside : List(F64), List(U64), U64, U64, U64, F64 -> Bool
	any_inside = |pts, idx, a, b, c, orient| {
		ax = at(pts, 2 * a)
		ay = at(pts, 2 * a + 1)
		bx = at(pts, 2 * b)
		by = at(pts, 2 * b + 1)
		cx = at(pts, 2 * c)
		cy = at(pts, 2 * c + 1)
		m = List.len(idx)
		var $found = Bool.False
		var $k = 0
		while $k < m and !$found {
			p = List.get(idx, $k) ?? crash("vertex out of range")
			px = at(pts, 2 * p)
			py = at(pts, 2 * p + 1)
			$found = p != a and p != b and p != c and cross3(ax, ay, bx, by, px, py) * orient > 0.0 and cross3(bx, by, cx, cy, px, py) * orient > 0.0 and cross3(cx, cy, ax, ay, px, py) * orient > 0.0
			$k = $k + 1
		}
		$found
	}

	# The remaining corners as a fan from the first, onto `out`.
	fan : List(F64), List(U64), List(F64) -> List(F64)
	fan = |pts, idx, out| {
		m = List.len(idx)
		first = List.get(idx, 0) ?? 0
		var $out = out
		var $k = 1
		while $k + 1 < m {
			p = List.get(idx, $k) ?? crash("vertex out of range")
			q = List.get(idx, $k + 1) ?? crash("vertex out of range")
			$out = List.concat($out, [at(pts, 2 * first), at(pts, 2 * first + 1), at(pts, 2 * p), at(pts, 2 * p + 1), at(pts, 2 * q), at(pts, 2 * q + 1)])
			$k = $k + 1
		}
		$out
	}
}
