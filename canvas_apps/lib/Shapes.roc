## Shapes is the vocabulary every app's frame is written in. A frame is a list
## of these shapes in the app's own coordinates, and each painter draws the list
## in order. What one app draws is built in that app's own folder.
import Brush

Shapes :: [].{

	## One thing in a frame. A later shape in the list paints over an earlier one.
	Shape : [
		## A polygon, as x0, y0, x1, y1 and so on. It can be any polygon, until `cut_shapes`
		## leaves only convex ones for a painter that fills nothing else.
		Poly({ points : List(F64), fill : Brush.Fill }),

		## The triangles of one concave polygon, six numbers each. Only `cut_shapes` makes these.
		Pieces({ tris : List(F64), fill : Brush.Fill }),

		## A disc, kept inside `clip`. A clip is a rectangle, not a named place, so no
		## painter has to know about one app's picture.
		Disc({ x : F64, y : F64, r : F64, fill : Brush.Fill, clip : Shapes.Clip }),
		Rect({ x : F64, y : F64, w : F64, h : F64, fill : Brush.Fill }),

		## A mark, not a shape: how the shapes after it combine, until the next `Blend`.
		## A painter holds this as a mode, so a mark in the list says it directly.
		Blend(Shapes.Mode),

		## A mark, not a shape: the space the shapes after it are in, until the next
		## `View`. It is a mark for the same reason `Blend` is.
		View(Shapes.Space),

		## `cols` by `rows` pixels stretched over the box without smoothing. It carries
		## the pixels, not a handle, so there is no second copy of them to keep in step.
		Image({ x : F64, y : F64, w : F64, h : F64, cols : U64, rows : U64, pixels : List(Brush.Rgba) }),

		## A line of words in a real typeface. `Font.plotted` gives a painter that has
		## no typefaces the strokes of the same line.
		Text(Shapes.Line),
	]

	## A line of type. `y` is its baseline, `x` its left end or its middle as `align`
	## says, and `size` the height of its em square, as in CSS. The viewer's machine
	## chooses the typeface and measures the words, so nothing in Roc knows how wide
	## the line came out: `Font.room_for` is the room to leave for it.
	Line : {
		text : Str,
		x : F64,
		y : F64,
		size : F64,
		face : Shapes.Face,
		align : Shapes.Align,
		color : Brush.Rgba,
	}

	## `Prose` is the viewer's own sans serif, for words. `Code` is a monospace, for
	## what a program says.
	Face : [Prose, Code]

	Align : [Left, Center]

	## `Over` paints over what is there. `Add` adds light to it, which is what a glow
	## is.
	Mode : [Over, Add]

	## The space the shapes after a `View` mark are in. `Screen` is the game's own
	## pixels, where every frame starts. `World` carries plain numbers rather than a
	## Camera, because the mark crosses to JavaScript, which has no such type.
	Space : [
		Screen,
		World({ target : { x : F64, y : F64 }, offset : { x : F64, y : F64 }, rotation : F64, zoom : F64 }),
	]

	## The mark back to the game's own pixels, which a HUD is drawn in.
	screen : Shapes.Shape
	screen = View(Screen)

	## A line `w` pixels wide between two points, as the quad it is, so no painter
	## has to learn a stroke. It has no cap and no join, which suits a gridline.
	line : F64, F64, F64, F64, F64, Brush.Fill -> Shapes.Shape
	line = |x0, y0, x1, y1, w, fill| {
		dx = x1 - x0
		dy = y1 - y0
		len = (dx * dx + dy * dy).sqrt()
		if len == 0.0 {
			Poly({ points: [], fill })
		} else {
			# The unit normal, half a width each way.
			nx = 0.0 - dy / len * (w / 2.0)
			ny = dx / len * (w / 2.0)
			Poly({ points: [x0 + nx, y0 + ny, x1 + nx, y1 + ny, x1 - nx, y1 - ny, x0 - nx, y0 - ny], fill })
		}
	}

	## A circle's outline, as `sides` quads around the rim. A disc under a smaller
	## disc makes a ring too, but only on a background of a known flat color.
	ring_shapes : F64, F64, F64, F64, U64, Brush.Fill -> List(Shapes.Shape)
	ring_shapes = |x, y, r, w, sides, fill| {
		n = if sides < 3 {
			3
		} else {
			sides
		}
		var $out = List.with_capacity(n)
		for k in 0..<n {
			a0 = F64.tau * k.to_f64() / n.to_f64()
			a1 = F64.tau * (k + 1).to_f64() / n.to_f64()
			$out = $out.append(
				line(x + r * a0.cos(), y + r * a0.sin(), x + r * a1.cos(), y + r * a1.sin(), w, fill),
			)
		}
		$out
	}

	## Every x pulled toward `axis` by `k`, so a figure drawn face-on reads as one
	## turned away by the angle whose cosine is `k`. A negative `k` mirrors it as
	## well, so a pair beside a path can face each other. A disc keeps its radius,
	## because no shape here is an ellipse.
	squashed_shapes : List(Shapes.Shape), F64, F64 -> List(Shapes.Shape)
	squashed_shapes = |shapes, axis, k| shapes.map(
		|shape|
			match shape {
				Poly(p) => Poly({ points: pulled(p.points, axis, k), fill: p.fill })
				Pieces(p) => Pieces({ tris: pulled(p.tris, axis, k), fill: p.fill })
				Disc(d) => Disc({ x: axis + (d.x - axis) * k, y: d.y, r: d.r, fill: d.fill, clip: d.clip })
				# A mirror sends a rectangle's left edge to its right, and a width is never
				# negative.
				Rect(r) => {
					a = axis + (r.x - axis) * k
					b = axis + (r.x + r.w - axis) * k
					Rect({
						x: a.min(b),
						y: r.y,
						w: if b < a {
							a - b
						} else {
							b - a
						},
						h: r.h,
						fill: r.fill,
					})
				}
				Blend(m) => Blend(m)
				View(l) => View(l)
				# A mirror sends a picture's left edge to its right, as it does a rectangle's.
				Image(i) => {
					a = axis + (i.x - axis) * k
					b = axis + (i.x + i.w - axis) * k
					Image({
						..i,
						x: a.min(b),
						w: if b < a {
							a - b
						} else {
							b - a
						},
					})
				}
				# Type keeps its letterforms, so only its place moves.
				Text(t) => Text({ ..t, x: axis + (t.x - axis) * k })
			},
	)

	pulled : List(F64), F64, F64 -> List(F64)
	pulled = |xs, axis, k| {
		n = xs.len()
		var $out = List.with_capacity(n)
		var $i = 0
		while $i + 1 < n {
			$out = $out.append(axis + (at(xs, $i) - axis) * k)
			$out = $out.append(at(xs, $i + 1))
			$i = $i + 2
		}
		$out
	}

	## Light that fades to nothing at `r`.
	halo : F64, F64, F64, Brush.Rgba, F64 -> Shapes.Shape
	halo = |x, y, r, colour, alpha|
		Disc({
			x,
			y,
			r,
			fill: Radial({ inner: { ..colour, a: alpha }, outer: { ..colour, a: 0.0 }, x, y, r0: 0.0, r1: r }),
			clip: Anywhere,
		})

	## A rectangle whose corners are rounded by `r`, each corner drawn in `segments`
	## steps. A radius of zero gives the plain box, and a radius too big for the box
	## is held to half its shorter side.
	rounded_rect : F64, F64, F64, F64, F64, I64, Brush.Fill -> Shapes.Shape
	rounded_rect = |x, y, w, h, r, segments, fill| {
		rr = r.min((w / 2.0).min(h / 2.0))
		if rr <= 0.0 or segments < 1 {
			Poly({ points: [x, y, x + w, y, x + w, y + h, x, y + h], fill })
		} else {
			var $points = List.with_capacity((8 * (segments + 1)).to_u64_wrap())
			# Clockwise from the top-left corner, each swept from its own start angle.
			$points = corner_points($points, x + rr, y + rr, rr, half_pi * 2.0, segments)
			$points = corner_points($points, x + w - rr, y + rr, rr, -half_pi, segments)
			$points = corner_points($points, x + w - rr, y + h - rr, rr, 0.0, segments)
			$points = corner_points($points, x + rr, y + h - rr, rr, half_pi, segments)
			Poly({ points: $points, fill })
		}
	}

	half_pi : F64
	half_pi = F64.pi / 2.0

	## The points of a quarter turn about (cx, cy), starting at the angle `from`.
	corner_points : List(F64), F64, F64, F64, F64, I64 -> List(F64)
	corner_points = |points, cx, cy, r, from, segments| {
		var $out = points
		for k in 0..=segments {
			a = from + half_pi * k.to_f64() / segments.to_f64()
			$out = $out.concat([cx + r * a.cos(), cy + r * a.sin()])
		}
		$out
	}

	## Where a shape may paint.
	Clip : [Anywhere, Within({ x : F64, y : F64, w : F64, h : F64 })]

	## The frame with each concave polygon cut into triangles, for a painter that
	## fills only convex polygons, as roc-ray does. A canvas fills a concave polygon
	## itself and doesn't ask for this. A frame paints the same either way, which the
	## gates' ShapesFrame checks.
	cut_shapes : List(Shapes.Shape) -> List(Shapes.Shape)
	cut_shapes = |shapes| shapes.join_map(
		|shape|
			match shape {
				Poly(p) =>
					if is_convex(p.points) {
						[Poly(p)]
					} else {
						[Pieces({ tris: wound_triangles(triangles(p.points)), fill: p.fill })]
					}
				other => [other]
			},
	)

	## Each triangle wound as roc-ray's convex fill winds one: its second and third
	## corners swapped when its signed area is positive.
	wound_triangles : List(F64) -> List(F64)
	wound_triangles = |tris| {
		m = tris.len() // 6
		var $out = List.with_capacity(6 * m)
		for k in 0..<m {
			b = 6 * k
			ax = at(tris, b)
			ay = at(tris, b + 1)
			bx = at(tris, b + 2)
			by = at(tris, b + 3)
			cx = at(tris, b + 4)
			cy = at(tris, b + 5)
			$out = if cross3(ax, ay, bx, by, cx, cy) > 0.0 {
				$out.concat([ax, ay, cx, cy, bx, by])
			} else {
				$out.concat([ax, ay, bx, by, cx, cy])
			}
		}
		$out
	}

	at : List(F64), U64 -> F64
	at = |xs, i| xs.get(i) ?? 0.0

	cross3 : F64, F64, F64, F64, F64, F64 -> F64
	cross3 = |ax, ay, bx, by, cx, cy| (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

	## Twice the signed area, summed as roc-ray's host sums it.
	twice_area : List(F64) -> F64
	twice_area = |points| {
		n = points.len() // 2
		var $sum = 0.0
		for k in 0..<n {
			k1 = if k + 1 == n {
				0
			} else {
				k + 1
			}
			$sum = $sum + at(points, 2 * k) * at(points, 2 * k1 + 1) - at(points, 2 * k1) * at(points, 2 * k + 1)
		}
		$sum
	}

	## A convex boundary reverses its horizontal and vertical direction at most twice
	## each.
	flip_limit : U64
	flip_limit = 2

	## Convex when every corner turns the same way and the boundary stays within
	## `flip_limit`, which rules out a star whose corners all turn one way.
	is_convex : List(F64) -> Bool
	is_convex = |points| {
		n = points.len() // 2
		var $sign = 0.0
		var $bad = False
		var $xflips = 0
		var $yflips = 0
		var $xdir = 0.0
		var $ydir = 0.0
		var $k = 0
		while $k < n and !$bad {
			k1 = if $k + 1 >= n {
				$k + 1 - n
			} else {
				$k + 1
			}
			k2 = if $k + 2 >= n {
				$k + 2 - n
			} else {
				$k + 2
			}
			x0 = at(points, 2 * $k)
			y0 = at(points, 2 * $k + 1)
			x1 = at(points, 2 * k1)
			y1 = at(points, 2 * k1 + 1)
			turn = cross3(x0, y0, x1, y1, at(points, 2 * k2), at(points, 2 * k2 + 1))
			$bad = turn * $sign < 0.0
			$sign = if $sign == 0.0 {
				turn
			} else {
				$sign
			}
			dx = x1 - x0
			dy = y1 - y0
			$xflips = if dx != 0.0 and $xdir != 0.0 and (dx > 0.0) != ($xdir > 0.0) {
				$xflips + 1
			} else {
				$xflips
			}
			$yflips = if dy != 0.0 and $ydir != 0.0 and (dy > 0.0) != ($ydir > 0.0) {
				$yflips + 1
			} else {
				$yflips
			}
			$xdir = if dx != 0.0 {
				dx
			} else {
				$xdir
			}
			$ydir = if dy != 0.0 {
				dy
			} else {
				$ydir
			}
			$k = $k + 1
		}
		!$bad and $xflips <= flip_limit and $yflips <= flip_limit
	}

	## The polygon cut into triangles by ear clipping, six numbers a triangle. A
	## corner in line with its neighbors is dropped without a triangle. A polygon
	## that crosses itself can run out of ears, and what is left is fanned.
	triangles : List(F64) -> List(F64)
	triangles = |points| {
		n = points.len() // 2
		orient = if twice_area(points) >= 0.0 {
			1.0
		} else {
			-1.0
		}
		var $indices = List.from_iter(U64.until(0, n))
		var $out = List.with_capacity(6 * n)
		var $i = 0
		var $misses = 0
		while $indices.len() > 3 and $misses < $indices.len() {
			m = $indices.len()
			ip = if $i == 0 {
				m - 1
			} else {
				$i - 1
			}
			inx = if $i + 1 >= m {
				0
			} else {
				$i + 1
			}
			a = $indices.get(ip) ?? crash "vertex out of range"
			b = $indices.get($i) ?? crash "vertex out of range"
			c = $indices.get(inx) ?? crash "vertex out of range"
			ax = at(points, 2 * a)
			ay = at(points, 2 * a + 1)
			bx = at(points, 2 * b)
			by = at(points, 2 * b + 1)
			cx = at(points, 2 * c)
			cy = at(points, 2 * c + 1)
			turn = cross3(ax, ay, bx, by, cx, cy) * orient
			ear = turn >= 0.0 and !any_inside(points, $indices, a, b, c, orient)
			$out = if ear and turn > 0.0 {
				$out.concat([ax, ay, bx, by, cx, cy])
			} else {
				$out
			}
			$indices = if ear {
				$indices.drop_at($i)
			} else {
				$indices
			}
			$misses = if ear {
				0
			} else {
				$misses + 1
			}
			$i = if ear {
				if $i >= $indices.len() {
					0
				} else {
					$i
				}
			} else {
				inx
			}
		}
		fan(points, $indices, $out)
	}

	## Whether a remaining corner other than a, b and c lies strictly inside the
	## triangle a b c.
	any_inside : List(F64), List(U64), U64, U64, U64, F64 -> Bool
	any_inside = |points, indices, a, b, c, orient| {
		ax = at(points, 2 * a)
		ay = at(points, 2 * a + 1)
		bx = at(points, 2 * b)
		by = at(points, 2 * b + 1)
		cx = at(points, 2 * c)
		cy = at(points, 2 * c + 1)
		indices.any(
			|p| {
				px = at(points, 2 * p)
				py = at(points, 2 * p + 1)
				p != a and p != b and p != c and cross3(ax, ay, bx, by, px, py) * orient > 0.0 and cross3(bx, by, cx, cy, px, py) * orient > 0.0 and cross3(cx, cy, ax, ay, px, py) * orient > 0.0
			},
		)
	}

	## The remaining corners as a fan from the first, onto `out`.
	fan : List(F64), List(U64), List(F64) -> List(F64)
	fan = |points, indices, out| {
		m = indices.len()
		first = indices.get(0) ?? 0
		var $out = out
		var $k = 1
		while $k + 1 < m {
			p = indices.get($k) ?? crash "vertex out of range"
			q = indices.get($k + 1) ?? crash "vertex out of range"
			$out = $out.concat([at(points, 2 * first), at(points, 2 * first + 1), at(points, 2 * p), at(points, 2 * p + 1), at(points, 2 * q), at(points, 2 * q + 1)])
			$k = $k + 1
		}
		$out
	}
}

## A line of type 100 px from the axis at 0.
line_of_type : Shapes.Line
line_of_type = {
	text: "Hi",
	x: 100.0,
	y: 20.0,
	size: 16.0,
	face: Code,
	align: Center,
	color: Brush.opaque(0x202020),
}

expect Shapes.squashed_shapes([Text(line_of_type)], 0.0, 0.5) == [Text({ ..line_of_type, x: 50.0 })]
expect Shapes.squashed_shapes([Text(line_of_type)], 0.0, -1.0) == [Text({ ..line_of_type, x: -100.0 })]
expect Shapes.squashed_shapes([Text(line_of_type)], 100.0, 0.5) == [Text(line_of_type)]
