# Shapes -- a Safari frame as shapes a drawing platform fills itself: convex
# polygons, triangles, discs, radial glows and rectangles, in scene coordinates,
# before the camera roll.
#
# Hand-written, for roc-ray's second iteration, where roc-ray draws the frame
# and Roc no longer paints pixels. roc-ray fills only convex polygons, so a
# concave one is cut into triangles by ear clipping. A triangle comes out in the
# order raylib keeps: roc-ray's convex fill reverses a polygon whose signed area
# is positive, and its triangle passes the points through as given.
#
# Gradients are flat for now, at the colour halfway between their stops, and
# the sun's three-stop glow is one two-stop glow. The blitter clips the sun to
# the sky; here the grass is drawn after the sun instead, which hides it below
# the horizon the same way.
import Paint
import Sky

Shapes :: [].{
	Rgba8 : { r : U8, g : U8, b : U8, a : U8 }

	Shape : [
		Convex({ pts : List(F64), color : Shapes.Rgba8 }),
		Triangle({ ax : F64, ay : F64, bx : F64, by : F64, cx : F64, cy : F64, color : Shapes.Rgba8 }),
		Disc({ x : F64, y : F64, r : F64, color : Shapes.Rgba8 }),
		Glow({ x : F64, y : F64, r : F64, inner : Shapes.Rgba8, outer : Shapes.Rgba8 }),
		Rect({ x : F64, y : F64, w : F64, h : F64, color : Shapes.Rgba8 }),
		RectV({ x : F64, y : F64, w : F64, h : F64, top : Shapes.Rgba8, bottom : Shapes.Rgba8 }),
	]

	# The frame in paint order: the sky, the sun, the grass, then every command.
	frame : List(Paint.DrawCmd), I64, I64, Sky.SunPos -> List(Shapes.Shape)
	frame = |commands, sky_top, sky_horizon, sun| {
		top = opaque(sky_top)
		var $out = List.with_capacity(2 * List.len(commands) + 8)
		# The sky band and the grass, oversized as the blitter draws them so the
		# rolled frame's corners stay filled: the top colour to a fifth of the way
		# down to the horizon at y 300, then the fade, and the grass from a pixel
		# above the horizon.
		$out = List.append($out, Rect({ x: -1080.0, y: -1260.0, w: 3120.0, h: 1320.0, color: top }))
		$out = List.append($out, RectV({ x: -1080.0, y: 60.0, w: 3120.0, h: 240.0, top, bottom: opaque(sky_horizon) }))
		$out = if sun.visible and sun.scale > 0.0 {
			List.concat($out, [
				Glow({ x: sun.x, y: sun.y, r: 340.0 * sun.scale, inner: { r: 255, g: 201, b: 128, a: 217 }, outer: { r: 255, g: 150, b: 92, a: 0 } }),
				Glow({ x: sun.x, y: sun.y, r: 46.0 * sun.scale, inner: opaque(0xffe6a3), outer: opaque(0xff9d5c) }),
			])
		} else {
			$out
		}
		$out = List.append($out, Rect({ x: -1080.0, y: 299.0, w: 3120.0, h: 1561.0, color: opaque(0x4a8f43) }))
		n = List.len(commands)
		var $k = 0
		while $k < n {
			$out = List.concat($out, of_command(List.get(commands, $k) ?? crash("command out of range")))
			$k = $k + 1
		}
		$out
	}

	# One command's shapes: a disc, or its polygon at its flat colour.
	of_command : Paint.DrawCmd -> List(Shapes.Shape)
	of_command = |c|
		if c.tag == 3 {
			col = opaque(c.color)
			[Disc({ x: at(c.geom, 0), y: at(c.geom, 1), r: at(c.geom, 2), color: { ..col, a: unit_byte(c.strength) } })]
		} else {
			polygon(c.pts, flat_color(c))
		}

	# The colour a command's polygon is filled with while gradients are flat.
	flat_color : Paint.DrawCmd -> Shapes.Rgba8
	flat_color = |c|
		if c.tag == 0 {
			opaque(c.color)
		} else if c.tag == 2 {
			opaque(c.color2)
		} else if c.tag >= 4 and c.tag <= 6 {
			halfway(with_alpha(c.color), with_alpha(c.color2))
		} else {
			opaque(c.color)
		}

	polygon : List(F64), Shapes.Rgba8 -> List(Shapes.Shape)
	polygon = |pts, color| {
		n = List.len(pts) // 2
		if n < 3 {
			[]
		} else if is_convex(pts) {
			[Convex({ pts, color })]
		} else {
			tris = triangulate(pts)
			m = List.len(tris) // 6
			var $out = List.with_capacity(m)
			var $k = 0
			while $k < m {
				b = 6 * $k
				$out = List.append($out, triangle(at(tris, b), at(tris, b + 1), at(tris, b + 2), at(tris, b + 3), at(tris, b + 4), at(tris, b + 5), color))
				$k = $k + 1
			}
			$out
		}
	}

	# A triangle wound as roc-ray's convex fill winds one: swapped when its
	# signed area is positive.
	triangle : F64, F64, F64, F64, F64, F64, Shapes.Rgba8 -> Shapes.Shape
	triangle = |ax, ay, bx, by, cx, cy, color|
		if cross3(ax, ay, bx, by, cx, cy) > 0.0 {
			Triangle({ ax, ay, bx: cx, by: cy, cx: bx, cy: by, color })
		} else {
			Triangle({ ax, ay, bx, by, cx, cy, color })
		}

	# --- Colour ---------------------------------------------------------------

	byte_of : I64, U8 -> U8
	byte_of = |c, shift| I64.to_u8_wrap(I64.bitwise_and(I64.shr_wrap(c, shift), 255))

	opaque : I64 -> Shapes.Rgba8
	opaque = |c| { r: byte_of(c, 16), g: byte_of(c, 8), b: byte_of(c, 0), a: 255 }

	with_alpha : I64 -> Shapes.Rgba8
	with_alpha = |c| { r: byte_of(c, 16), g: byte_of(c, 8), b: byte_of(c, 0), a: byte_of(c, 24) }

	unit_byte : F64 -> U8
	unit_byte = |v| {
		n = F64.to_i64_wrap(v * 255.0 + 0.5)
		I64.to_u8_wrap(if n < 0 { 0 } else if n > 255 { 255 } else { n })
	}

	mid : U8, U8 -> U8
	mid = |p, q| I64.to_u8_wrap((U8.to_i64(p) + U8.to_i64(q) + 1) // 2)

	halfway : Shapes.Rgba8, Shapes.Rgba8 -> Shapes.Rgba8
	halfway = |p, q| { r: mid(p.r, q.r), g: mid(p.g, q.g), b: mid(p.b, q.b), a: mid(p.a, q.a) }

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
