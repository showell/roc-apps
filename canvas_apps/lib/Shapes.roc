## Shapes is the vocabulary every app's frame is written in. A frame is a list
## of these shapes in the app's own coordinates, and each painter draws the list
## in order. What one app draws is built in that app's own folder.
import Brush
import Point

Shapes :: [].{

	## One thing in a frame. A later shape in the list paints over an earlier one.
	Shape : [
		## A polygon, as x0, y0, x1, y1 and so on. It can be any polygon. A painter
		## that fills only convex ones has `ConvexCut` cut the rest into triangles.
		Poly({ coordinates : List(F64), fill : Brush.Fill }),

		Disc({ x : F64, y : F64, radius : F64, fill : Brush.Fill }),
		Rect({ x : F64, y : F64, width : F64, height : F64, fill : Brush.Fill }),

		## A mark, not a shape: how the shapes after it combine, until the next `Blend`.
		## A painter holds this as a mode, so a mark in the list says it directly.
		## `Shapes.added_light` writes the pair of marks around a run of shapes.
		Blend(Shapes.Mode),

		## A mark, not a shape: the space the shapes after it are in, until the next
		## `View`. It is a mark for the same reason `Blend` is. `Shapes.in_space`
		## writes the pair of marks around a run of shapes.
		View(Shapes.Space),

		## `cols` by `rows` pixels stretched over the box without smoothing. It carries
		## the pixels, not a handle, so there is no second copy of them to keep in step.
		Image({ x : F64, y : F64, width : F64, height : F64, cols : U64, rows : U64, pixels : List(Brush.Rgba) }),

		## A line of words in a real typeface. `Font.plotted` gives a painter that has
		## no typefaces the strokes of the same line.
		Text(Shapes.TextLine),
	]

	## A line of type. `y` is its baseline, `x` its left end or its middle as `align`
	## says, and `size` the height of its em square, as in CSS. The viewer's machine
	## chooses the typeface and measures the words, so nothing in Roc knows how wide
	## the line came out: `Font.room_for` is the room to leave for it.
	TextLine : {
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
		World({ target : Point.Point, offset : Point.Point, rotation : F64, zoom : F64 }),
	]

	## The shapes lit in `Add` mode, so each adds its light to what is under it,
	## and the mode back to `Over` after them.
	added_light : List(Shapes.Shape) -> List(Shapes.Shape)
	added_light = |shapes| shapes.prepend(Blend(Add)).append(Blend(Over))

	## The shapes in `space`, and the space back to the screen after them.
	in_space : Shapes.Space, List(Shapes.Shape) -> List(Shapes.Shape)
	in_space = |space, shapes| shapes.prepend(View(space)).append(View(Screen))

	## A line `width` pixels wide between two points, as the quad it is, so no
	## painter has to learn a stroke. It has no cap and no join, which suits a
	## gridline. A line from a point to itself has no direction to be wide
	## across, and crashes.
	line : { from : Point.Point, to : Point.Point, width : F64 }, Brush.Fill -> Shapes.Shape
	line = |{ from, to, width }, fill| {
		dx = to.x - from.x
		dy = to.y - from.y
		length = (dx * dx + dy * dy).sqrt()
		if length == 0.0 {
			crash "Shapes.line: a line from a point to itself"
		} else {
			# The unit normal, half a width each way.
			nx = 0.0 - dy / length * (width / 2.0)
			ny = dx / length * (width / 2.0)
			Poly({ coordinates: [from.x + nx, from.y + ny, to.x + nx, to.y + ny, to.x - nx, to.y - ny, from.x - nx, from.y - ny], fill })
		}
	}

	## A circle's outline, `line_width` wide around the rim, as `sides` sectors
	## of the band between two circles. Neighbouring sectors share their edge
	## exactly, so the band has no gap at a corner. A disc under a smaller disc
	## makes a ring too, but only on a background of a known flat color. Fewer
	## than three sides enclose nothing, and crash.
	ring_shapes : { center : Point.Point, radius : F64, line_width : F64, sides : U64 }, Brush.Fill -> List(Shapes.Shape)
	ring_shapes = |{ center, radius, line_width, sides }, fill|
		if sides < 3 {
			crash "Shapes.ring_shapes: a ring needs at least three sides"
		} else {
			inner_radius = radius - line_width / 2.0
			outer_radius = radius + line_width / 2.0
			# The last side ends at angle 0 itself, not at a whole turn, so it
			# meets the first side's corners exactly.
			rim_point = |r, k| {
				angle = F64.tau * (k % sides).to_f64() / sides.to_f64()
				[center.x + r * angle.cos(), center.y + r * angle.sin()]
			}
			var $out = List.with_capacity(sides)
			for k in 0..<sides {
				coordinates = rim_point(outer_radius, k)
					.concat(rim_point(outer_radius, k + 1))
					.concat(rim_point(inner_radius, k + 1))
					.concat(rim_point(inner_radius, k))
				$out = $out.append(Poly({ coordinates, fill }))
			}
			$out
		}

	## Every x pulled toward `axis` by `cosine`, so a figure drawn face-on reads as one
	## turned away by the angle whose cosine that is. A negative cosine mirrors it as
	## well, so a pair beside a path can face each other. A disc keeps its radius,
	## because no shape here is an ellipse.
	squashed_shapes : List(Shapes.Shape), { axis : F64, cosine : F64 } -> List(Shapes.Shape)
	squashed_shapes = |shapes, { axis, cosine: k }| shapes.map(
		|shape|
			match shape {
				Poly(p) => Poly({ coordinates: pulled(p.coordinates, { axis, cosine: k }), fill: p.fill })
				Disc(d) => Disc({ x: axis + (d.x - axis) * k, y: d.y, radius: d.radius, fill: d.fill })
				# A mirror sends a rectangle's left edge to its right, and a width is never
				# negative.
				Rect(r) => {
					a = axis + (r.x - axis) * k
					b = axis + (r.x + r.width - axis) * k
					Rect({
						x: a.min(b),
						y: r.y,
						width: if b < a {
							a - b
						} else {
							b - a
						},
						height: r.height,
						fill: r.fill,
					})
				}
				Blend(m) => Blend(m)
				View(l) => View(l)
				# A mirror sends a picture's left edge to its right, as it does a rectangle's.
				Image(i) => {
					a = axis + (i.x - axis) * k
					b = axis + (i.x + i.width - axis) * k
					Image({
						..i,
						x: a.min(b),
						width: if b < a {
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

	## Light in `color` at the middle, at the colour's own alpha, fading to
	## nothing at `radius`.
	halo : { center : Point.Point, radius : F64 }, Brush.Rgba -> Shapes.Shape
	halo = |{ center, radius }, color|
		Disc({
			x: center.x,
			y: center.y,
			radius,
			fill: Radial({ inner_color: color, outer_color: { ..color, a: 0.0 }, center, inner_radius: 0.0, outer_radius: radius }),
		})

	## A rectangle whose corners are rounded by `corner_radius`, each corner drawn in
	## `corner_steps` steps. A radius of zero or no steps gives the plain box, and a
	## radius too big for the box is held to half its shorter side.
	rounded_rect : { x : F64, y : F64, width : F64, height : F64, corner_radius : F64, corner_steps : U64 }, Brush.Fill -> Shapes.Shape
	rounded_rect = |{ x, y, width, height, corner_radius, corner_steps }, fill| {
		radius = corner_radius.min((width / 2.0).min(height / 2.0))
		if radius <= 0.0 or corner_steps == 0 {
			Poly({ coordinates: [x, y, x + width, y, x + width, y + height, x, y + height], fill })
		} else {
			var $coordinates = List.with_capacity(8 * (corner_steps + 1))
			# Clockwise from the top-left corner, each swept from its own start angle.
			$coordinates = corner_coordinates($coordinates, { center: { x: x + radius, y: y + radius }, radius, start_angle: half_pi * 2.0, steps: corner_steps })
			$coordinates = corner_coordinates($coordinates, { center: { x: x + width - radius, y: y + radius }, radius, start_angle: -half_pi, steps: corner_steps })
			$coordinates = corner_coordinates($coordinates, { center: { x: x + width - radius, y: y + height - radius }, radius, start_angle: 0.0, steps: corner_steps })
			$coordinates = corner_coordinates($coordinates, { center: { x: x + radius, y: y + height - radius }, radius, start_angle: half_pi, steps: corner_steps })
			Poly({ coordinates: $coordinates, fill })
		}
	}
}

## Every x of the coordinates pulled toward `axis` by `cosine`.
pulled : List(F64), { axis : F64, cosine : F64 } -> List(F64)
pulled = |xs, { axis, cosine: k }| {
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

at : List(F64), U64 -> F64
at = |xs, i| xs.get(i) ?? crash "Shapes.at: an index past the end of the coordinates"

half_pi : F64
half_pi = F64.pi / 2.0

## The coordinates of a quarter turn about `center`, starting at `start_angle`,
## onto `coordinates`.
corner_coordinates : List(F64), { center : Point.Point, radius : F64, start_angle : F64, steps : U64 } -> List(F64)
corner_coordinates = |coordinates, { center, radius, start_angle, steps }| {
	var $out = coordinates
	for k in 0..=steps {
		a = start_angle + half_pi * k.to_f64() / steps.to_f64()
		$out = $out.append(center.x + radius * a.cos())
		$out = $out.append(center.y + radius * a.sin())
	}
	$out
}

## A line of type 100 px from the axis at 0.
line_of_type : Shapes.TextLine
line_of_type = {
	text: "Hi",
	x: 100.0,
	y: 20.0,
	size: 16.0,
	face: Code,
	align: Center,
	color: { r: 32.0, g: 32.0, b: 32.0, a: 1.0 },
}

expect Shapes.squashed_shapes([Text(line_of_type)], { axis: 0.0, cosine: 0.5 }) == [Text({ ..line_of_type, x: 50.0 })]
expect Shapes.squashed_shapes([Text(line_of_type)], { axis: 0.0, cosine: -1.0 }) == [Text({ ..line_of_type, x: -100.0 })]
expect Shapes.squashed_shapes([Text(line_of_type)], { axis: 100.0, cosine: 0.5 }) == [Text(line_of_type)]

## The fill the shapes below are drawn in.
ink : Brush.Fill
ink = Flat({ r: 32.0, g: 32.0, b: 32.0, a: 1.0 })

## A dot of light, as the shape both brackets hold.
dot : Shapes.Shape
dot = Disc({ x: 1.0, y: 2.0, radius: 3.0, fill: ink })

expect Shapes.added_light([dot]) == [Blend(Add), dot, Blend(Over)]
expect Shapes.added_light([]) == [Blend(Add), Blend(Over)]
expect Shapes.in_space(Screen, [dot]) == [View(Screen), dot, View(Screen)]

# A horizontal line two wide stands one each side of its axis.
expect
	Shapes.line({ from: { x: 0.0, y: 0.0 }, to: { x: 10.0, y: 0.0 }, width: 2.0 }, ink)
		== Poly({ coordinates: [0.0, 1.0, 10.0, 1.0, 10.0, -1.0, 0.0, -1.0], fill: ink })

# The fewest sides a ring may have make three sectors.
expect Shapes.ring_shapes({ center: { x: 0.0, y: 0.0 }, radius: 5.0, line_width: 1.0, sides: 3 }, ink).len() == 3

## A ring sector's corners: outer start, outer end, inner end, inner start.
sector_corners : Shapes.Shape -> List(F64)
sector_corners = |shape|
	match shape {
		Poly({ coordinates, fill: _ }) => coordinates
		_ => []
	}

# Each sector starts where the one before it ends, outer corner and inner
# corner, all the way round to the first again. Its inner corners sit nearer
# the center than its outer ones, by the line's width.
expect {
	sectors = Shapes.ring_shapes({ center: { x: 3.0, y: 4.0 }, radius: 10.0, line_width: 2.0, sides: 7 }, ink).map(sector_corners)
	following = sectors.drop_first(1).append(sectors.first() ?? [])
	shared = sectors.map2(following, |sector, next| sector.sublist({ start: 2, len: 2 }) == next.sublist({ start: 0, len: 2 }) and sector.sublist({ start: 4, len: 2 }) == next.sublist({ start: 6, len: 2 }))
	first = sectors.first() ?? []
	outer_x = first.get(0) ?? 0.0
	inner_x = first.get(6) ?? 0.0
	sectors.len() == 7 and first.len() == 8 and shared.all(|same| same) and outer_x - inner_x == 2.0
}
