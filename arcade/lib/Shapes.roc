# Shapes -- what a frame is made of: convex and concave polygons, discs and
# rectangles, each with the Brush it is filled with, in scene coordinates
# before the camera roll.
#
# **EVERY MOVIE'S.** Building Safari's own frame -- its sky, its grass, its sun
# and its Codex draw commands -- is in movies/safari/SafariShapes.roc; what is
# here is the vocabulary three movies now share.
#
# Hand-written, for roc-ray, where roc-ray draws the frame and Roc does not
# paint pixels. roc-ray fills only convex polygons, so a concave one is cut into
# triangles by ear clipping; the pieces share the polygon's brush. A triangle
# comes out in the order raylib keeps: roc-ray's convex fill reverses a polygon
# whose signed area is positive, and its triangle passes the points through as
# given.
#
# The backdrop is the runner's: the sky's linear gradient, the grass, and the
# sun's glow and disc clipped to the sky, the glow as a rectangle that is the
# clip and the disc carrying the same rectangle as its own.
import Brush
import Trig

Shapes :: [].{
	Shape : [
		# A polygon, x0, y0, x1, y1, ... — any polygon, as a movie describes
		# it. **After `cut` it is convex**, which is the only kind some
		# platforms will fill.
		Poly({ pts : List(F64), fill : Brush.Fill }),
		# The triangles of one concave polygon, six numbers each. Only `cut`
		# makes these, for a platform that asked to be spared a concave one.
		Pieces({ tris : List(F64), fill : Brush.Fill }),
		# A disc, kept to `clip` if it names a rectangle. **A CLIP IS A
		# RECTANGLE, NOT A PLACE**: this used to be `sky_only`, which meant
		# "(0, 0) to (960, 300)" and put one movie's sky into every painter
		# that drew a disc, the fragment shader included.
		Disc({ x : F64, y : F64, r : F64, fill : Brush.Fill, clip : Shapes.Clip }),
		Rect({ x : F64, y : F64, w : F64, h : F64, fill : Brush.Fill }),
		# **NOT A SHAPE: HOW THE SHAPES AFTER IT ARE COMBINED.** A glow is
		# light added to what is already there, not paint laid over it, and
		# every game so far has apologised in its own comments for faking one
		# with a translucent fill. A frame is a list, so the cheapest way to
		# say this is a mark in the list that changes the mode until the next
		# mark -- which is what both painters do underneath anyway
		# (`globalCompositeOperation` on a canvas, `BeginBlendMode` on
		# roc-ray). A frame that never mentions it paints exactly as before.
		Blend(Shapes.Mode),
		# **NOT A SHAPE: WHERE THE SHAPES AFTER IT ARE.** Until the next one,
		# coordinates are read through this lens instead of as screen pixels.
		# The same mark as Blend, for the same reason: both painters already
		# take this as a scope rather than a flag (`setTransform` on a canvas,
		# `BeginMode2D` on roc-ray), and a frame is a list, so the cheapest way
		# to say it is a mark that holds until the next one.
		View(Shapes.Lens),
		# **A PICTURE, IN THE FRAME.** `cols` x `rows` pixels stretched over
		# the rectangle without smoothing, so a 16 x 16 canvas drawn at 448
		# pixels is 28-pixel cells with hard edges.
		#
		# **IT CARRIES THE PIXELS, NOT A HANDLE**, which is the whole reason
		# roc-ray's Pixel Workshop shrank when it was ported. There, the
		# picture lives twice -- once in the model and once on the GPU -- and
		# every branch that changes the model has to remember to emit the
		# matching upload; upstream says so in its own comment, and has an
		# `Edit` type to carry them. A frame that is a VALUE computed from the
		# model cannot have a second copy to keep in step, so the upload, the
		# handle and the `Edit` all go away together.
		#
		# The trade is bandwidth: the whole picture crosses every frame rather
		# than one changed pixel. That is the same trade this design makes
		# everywhere, and at 256 pixels beside the nine thousand words a frame
		# already carries it is not close. **A LOADED IMAGE IS A DIFFERENT
		# THING** -- a tileset is not re-sent sixty times a second -- and it
		# still wants a handle, and a way to load one, which is the wall.
		Image({ x : F64, y : F64, w : F64, h : F64, cols : U64, rows : U64, pixels : List(Brush.Rgba) }),
	]

	# `Over` paints; `Add` lights.
	Mode : [Over, Add]

	# `Screen` is the game's own pixels, which is where every frame starts, so
	# a frame that never says `View` paints exactly as it did before.
	#
	# **A LENS CARRIES NUMBERS, NOT A CAMERA.** Camera.roc builds one and names
	# the same four settings roc-ray's `Camera2D` does, but a mark that crossed
	# the wire carrying that type would need the type on the far side, and the
	# far side is JavaScript.
	Lens : [
		Screen,
		World({ target : { x : F64, y : F64 }, offset : { x : F64, y : F64 }, rotation : F64, zoom : F64 }),
	]

	# Back to the game's own pixels: what a HUD is drawn in.
	screen : Shapes.Shape
	screen = View(Screen)

	# ── what a polygon can be, given a little arithmetic ────────────────────
	#
	# **A THICK LINE AND A ROUNDED RECTANGLE ARE POLYGONS**, so they are built
	# here rather than added to the vocabulary every painter has to learn. A
	# second movie (roc-ray's capture_plot) wanted both: gridlines with a
	# thickness, and a progress bar with a radius.

	# A line of `w` pixels between two points: the quad it actually is. Exact
	# at any angle; it has no cap and no join, which is what a gridline wants.
	line : F64, F64, F64, F64, F64, Brush.Fill -> Shapes.Shape
	line = |x0, y0, x1, y1, w, fill| {
		dx = x1 - x0
		dy = y1 - y0
		len = sqrt(dx * dx + dy * dy)
		if len == 0.0 {
			Poly({ pts: [], fill })
		} else {
			# The unit normal, half a width each way.
			nx = 0.0 - dy / len * (w / 2.0)
			ny = dx / len * (w / 2.0)
			Poly({ pts: [x0 + nx, y0 + ny, x1 + nx, y1 + ny, x1 - nx, y1 - ny, x0 - nx, y0 - ny], fill })
		}
	}

	# A circle's OUTLINE, as the strokes it actually is: `sides` quads around
	# the rim. **NOT A NEW SHAPE** -- the same trick Font plays with a letter,
	# so a hollow circle needs nothing new on any wire and no painter learns a
	# stroke. A filled disc under a smaller one is the other way to get a ring,
	# and it only works where the background is a known flat colour.
	ring : F64, F64, F64, F64, U64, Brush.Fill -> List(Shapes.Shape)
	ring = |x, y, r, w, sides, fill| {
		n = if sides < 3 { 3 } else { sides }
		var $out = List.with_capacity(n)
		var $k = 0
		while $k < n {
			a0 = Trig.two_pi * count($k) / count(n)
			a1 = Trig.two_pi * count($k + 1) / count(n)
			$out = List.append(
				$out,
				line(x + r * Trig.r_cos(a0), y + r * Trig.r_sin(a0), x + r * Trig.r_cos(a1), y + r * Trig.r_sin(a1), w, fill),
			)
			$k = $k + 1
		}
		$out
	}

	count : U64 -> F64
	count = |n| I64.to_f64(U64.to_i64_wrap(n))

	# **A FIGURE TURNED AWAY FROM US IS THE SAME FIGURE, NARROWER.** Every x is
	# pulled toward `axis` by `k`, so a drawing made face-on reads as one yawed
	# by the angle whose cosine is `k`; a negative `k` mirrors it as well, which
	# is how a pair flanking a path can face each other. A disc keeps its
	# radius -- a skull turned forty-five degrees is still round, and an
	# ellipse is not in the vocabulary.
	squash_x : List(Shapes.Shape), F64, F64 -> List(Shapes.Shape)
	squash_x = |shapes, axis, k| {
		n = List.len(shapes)
		var $out = List.with_capacity(n)
		var $i = 0
		while $i < n {
			$out = List.append(
				$out,
				match List.get(shapes, $i) ?? crash("shape out of range") {
					Poly(p) => Poly({ pts: pulled(p.pts, axis, k), fill: p.fill })
					Pieces(p) => Pieces({ tris: pulled(p.tris, axis, k), fill: p.fill })
					Disc(d) => Disc({ x: axis + (d.x - axis) * k, y: d.y, r: d.r, fill: d.fill, clip: d.clip })
					# A mirror sends a rectangle's left edge to its right, and a
					# width is never negative.
					Rect(r) => {
						a = axis + (r.x - axis) * k
						b = axis + (r.x + r.w - axis) * k
						Rect({ x: F64.min(a, b), y: r.y, w: if b < a { a - b } else { b - a }, h: r.h, fill: r.fill })
					}
					# A mark is not geometry; turning a figure does not touch it.
					Blend(m) => Blend(m)
					View(l) => View(l)
					# A picture pulled toward the axis is the same picture,
					# narrower; a mirror sends its left edge to its right.
					Image(i) => {
						a = axis + (i.x - axis) * k
						b = axis + (i.x + i.w - axis) * k
						Image({ ..i, x: F64.min(a, b), w: if b < a { a - b } else { b - a } })
					}
				},
			)
			$i = $i + 1
		}
		$out
	}

	# The x of every point pulled toward `axis`; the y of each left alone.
	pulled : List(F64), F64, F64 -> List(F64)
	pulled = |xs, axis, k| {
		n = List.len(xs)
		var $out = List.with_capacity(n)
		var $i = 0
		while $i + 1 < n {
			$out = List.append($out, axis + (at(xs, $i) - axis) * k)
			$out = List.append($out, at(xs, $i + 1))
			$i = $i + 2
		}
		$out
	}

	# **A HALO**: light that fades to nothing at `r`. Three games drew one by
	# hand, each spelling out the same radial fill.
	halo : F64, F64, F64, Brush.Rgba, F64 -> Shapes.Shape
	halo = |x, y, r, colour, alpha|
		Disc({
			x,
			y,
			r,
			fill: Radial({ inner: { ..colour, a: alpha }, outer: { ..colour, a: 0.0 }, x, y, r0: 0.0, r1: r }),
			clip: Anywhere,
		})

	# A rectangle whose corners are rounded by `r`, each corner drawn with
	# `segments` steps -- the same two numbers roc-ray's own rounded_rectangle
	# takes. A radius of zero, or one too big for the box, gives the box.
	rounded_rect : F64, F64, F64, F64, F64, I64, Brush.Fill -> Shapes.Shape
	rounded_rect = |x, y, w, h, r, segments, fill| {
		rr = F64.min(r, F64.min(w / 2.0, h / 2.0))
		if rr <= 0.0 or segments < 1 {
			Poly({ pts: [x, y, x + w, y, x + w, y + h, x, y + h], fill })
		} else {
			var $pts = List.with_capacity(I64.to_u64_wrap(8 * (segments + 1)))
			# Clockwise from the top-left corner's arc, each corner swept from
			# its own start angle.
			$pts = corner($pts, x + rr, y + rr, rr, half_pi * 2.0, segments)
			$pts = corner($pts, x + w - rr, y + rr, rr, 0.0 - half_pi, segments)
			$pts = corner($pts, x + w - rr, y + h - rr, rr, 0.0, segments)
			$pts = corner($pts, x + rr, y + h - rr, rr, half_pi, segments)
			Poly({ pts: $pts, fill })
		}
	}

	half_pi : F64
	half_pi = 1.5707963267948966

	# One quarter turn about (cx, cy), from `from` through a right angle.
	corner : List(F64), F64, F64, F64, F64, I64 -> List(F64)
	corner = |pts, cx, cy, r, from, segments| {
		var $out = pts
		var $k = 0
		while $k <= segments {
			a = from + half_pi * I64.to_f64($k) / I64.to_f64(segments)
			$out = List.concat($out, [cx + r * Trig.r_cos(a), cy + r * Trig.r_sin(a)])
			$k = $k + 1
		}
		$out
	}

	sqrt : F64 -> F64
	sqrt = |v| if v <= 0.0 { 0.0 } else { F64.sqrt(v) }

	# Where a shape is allowed to paint, when it is not allowed everywhere.
	Clip : [Anywhere, Within({ x : F64, y : F64, w : F64, h : F64 })]

	polygon : List(F64), Brush.Fill -> List(Shapes.Shape)
	polygon = |pts, fill| {
		n = List.len(pts) // 2
		if n < 3 {
			[]
		} else {
			[Poly({ pts, fill })]
		}
	}

	# **CUTTING IS THE PLATFORM'S BUSINESS, NOT THE MOVIE'S.** A canvas fills a
	# concave polygon itself and would rather have the polygon; roc-ray fills
	# only convex ones, so it asks for this, which leaves a convex polygon
	# alone and cuts a concave one into triangles wound the way its own convex
	# fill winds them. A frame that has been through here paints the same as
	# one that has not -- that is what ShapesFrame checks.
	cut : List(Shapes.Shape) -> List(Shapes.Shape)
	cut = |shapes| {
		n = List.len(shapes)
		var $out = List.with_capacity(n)
		var $k = 0
		while $k < n {
			$out = List.concat(
				$out,
				match List.get(shapes, $k) ?? crash("shape out of range") {
					Poly(p) =>
						if is_convex(p.pts) {
							[Poly(p)]
						} else {
							[Pieces({ tris: wound(triangulate(p.pts)), fill: p.fill })]
						}
					other => [other]
				},
			)
			$k = $k + 1
		}
		$out
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
