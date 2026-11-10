## Shapes is the vocabulary every app's frame is written in. A frame is a list
## of these shapes in the app's own coordinates, and each painter draws the list
## in order. What one app draws is built in that app's own folder.
import Brush
import Pixels
import Point

Shapes :: [].{

	## One thing in a frame. A later shape in the list paints over an earlier one.
	## A shape is a region and a fill: any of the four regions takes any fill.
	Shape : [
		## Three corners, which is every triangle and nothing else.
		Triangle({ first : Point.Point, second : Point.Point, third : Point.Point, fill : Brush.Fill }),

		## Four corners in order round the edge. `Shapes.rectangle` makes an
		## upright one.
		Quad({ first : Point.Point, second : Point.Point, third : Point.Point, fourth : Point.Point, fill : Brush.Fill }),

		Disc({ center : Point.Point, radius : Pixels, fill : Brush.Fill }),

		## An outline of any other count of corners, in order round its edge: a
		## traced still, a mountain, the road.
		Polygon({ corners : List(Point.Point), fill : Brush.Fill }),

		## A mark, not a shape: how the shapes after it combine, until the next `Blend`.
		## A painter holds this as a mode, so a mark in the list says it directly.
		## `Shapes.added_light_shapes` writes the pair of marks around a run of shapes.
		Blend(Shapes.Mode),

		## A mark, not a shape: the space the shapes after it are in, until the next
		## `View`. It is a mark for the same reason `Blend` is. `Shapes.shapes_in_space`
		## writes the pair of marks around a run of shapes.
		View(Shapes.Space),

		## `cols` by `rows` pixels stretched over the box without smoothing. It carries
		## the pixels, not a handle, so there is no second copy of them to keep in step.
		Image({ x : F64, y : F64, width : F64, height : F64, cols : U64, rows : U64, pixels : List(Brush.Rgba) }),

		## A line of words in a real typeface. `Font.plotted_shapes` gives a painter that has
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
	## pixels, where every frame starts. `World` carries points and numbers rather than a
	## Camera, because the mark crosses to JavaScript, which has no such type. As in
	## a Camera, the world point `target` lands on the screen point `offset`, turned
	## clockwise by `rotation` degrees and scaled by `zoom`. `world_space` is the
	## way to make a `World`, because it checks the zoom.
	Space : [
		Screen,
		World({ target : Point.Point, offset : Point.Point, rotation : F64, zoom : F64 }),
	]

	## A `World` space, its zoom checked. A zoom of zero has no inverse, so a
	## painter could not map the screen back into this space, and a zoom that is
	## not finite comes only from a bug; either crashes.
	world_space : { target : Point.Point, offset : Point.Point, rotation : F64, zoom : F64 } -> Shapes.Space
	world_space = |world|
		if world.zoom == 0.0 or !world.zoom.is_finite() {
			crash "Shapes.world_space: a zoom must be finite and not zero"
		} else {
			World(world)
		}

	## The shapes lit in `Add` mode, so each adds its light to what is under it,
	## and the mode back to `Over` after them.
	added_light_shapes : List(Shapes.Shape) -> List(Shapes.Shape)
	added_light_shapes = |shapes| shapes.prepend(Blend(Add)).append(Blend(Over))

	## The shapes in `space`, and the space back to the screen after them.
	shapes_in_space : Shapes.Space, List(Shapes.Shape) -> List(Shapes.Shape)
	shapes_in_space = |space, shapes| Shapes.lists_in_space(space, [shapes])

	## The shapes of each of `shape_lists` in turn, in `space`, and the space back
	## to the screen after them: what `shapes_in_space` gives for the lists joined, with
	## every shape copied once.
	lists_in_space : Shapes.Space, List(List(Shapes.Shape)) -> List(Shapes.Shape)
	lists_in_space = |space, shape_lists| [[View(space)]].concat(shape_lists).append([View(Screen)]).join()

	## The region round `corners`, in order, tagged by how many there are: three
	## make a `Triangle`, four a `Quad`, and any other number a `Polygon`. Every
	## maker that works through a list of corners comes here, so the count
	## always matches the tag.
	region_from_corners : List(Point.Point), Brush.Fill -> Shapes.Shape
	region_from_corners = |corners, fill|
		match corners {
			[first, second, third] => Triangle({ first, second, third, fill })
			[first, second, third, fourth] => Quad({ first, second, third, fourth, fill })
			_ => Polygon({ corners, fill })
		}

	## The corners of a straight-edged region, in order round its edge. A disc,
	## a picture, a line of type and a mark have no corners to give.
	region_corners : Shapes.Shape -> Try(List(Point.Point), [NoCorners])
	region_corners = |shape|
		match shape {
			Triangle(t) => Ok([t.first, t.second, t.third])
			Quad(q) => Ok([q.first, q.second, q.third, q.fourth])
			Polygon(p) => Ok(p.corners)
			Disc(_) | Image(_) | Text(_) | Blend(_) | View(_) => Err(NoCorners)
		}

	## An upright box, `width` across and `height` down from `top_left`, as the
	## quad it is: clockwise on the screen from its top left corner.
	rectangle : { top_left : Point.Point, width : Pixels, height : Pixels, fill : Brush.Fill } -> Shapes.Shape
	rectangle = |{ top_left, width, height, fill }| {
		right = top_left.x.plus(width)
		bottom = top_left.y.plus(height)
		Quad({
			first: top_left,
			second: { x: right, y: top_left.y },
			third: { x: right, y: bottom },
			fourth: { x: top_left.x, y: bottom },
			fill,
		})
	}

	## A line `width` pixels wide between two points, as the quad it is, so no
	## painter has to learn a stroke. It has no cap and no join, which suits a
	## gridline. A line from a point to itself has no direction to be wide
	## across, and crashes.
	line : { from : Point.Point, to : Point.Point, width : Pixels }, Brush.Fill -> Shapes.Shape
	line = |{ from, to, width }, fill| {
		x0 = from.x.to_f64()
		y0 = from.y.to_f64()
		x1 = to.x.to_f64()
		y1 = to.y.to_f64()
		dx = x1 - x0
		dy = y1 - y0
		length = (dx * dx + dy * dy).sqrt()
		if length == 0.0 {
			crash "Shapes.line: a line from a point to itself"
		} else {
			# The unit normal, half a width each way.
			half_width = width.to_f64() / 2.0
			nx = 0.0 - dy / length * half_width
			ny = dx / length * half_width
			Quad({
				first: Point.at(x0 + nx, y0 + ny),
				second: Point.at(x1 + nx, y1 + ny),
				third: Point.at(x1 - nx, y1 - ny),
				fourth: Point.at(x0 - nx, y0 - ny),
				fill,
			})
		}
	}

	## A circle's outline, `line_width` wide around the rim, as `sides` sectors
	## of the band between two circles. Neighbouring sectors share their edge
	## exactly, so the band has no gap at a corner. A disc under a smaller disc
	## makes a ring too, but only on a background of a known flat color. Fewer
	## than three sides enclose nothing, and crash.
	ring_shapes : { center : Point.Point, radius : Pixels, line_width : Pixels, sides : U64 }, Brush.Fill -> List(Shapes.Shape)
	ring_shapes = |{ center, radius, line_width, sides }, fill|
		if sides < 3 {
			crash "Shapes.ring_shapes: a ring needs at least three sides"
		} else {
			inner_radius = radius.to_f64() - line_width.to_f64() / 2.0
			outer_radius = radius.to_f64() + line_width.to_f64() / 2.0
			cx = center.x.to_f64()
			cy = center.y.to_f64()
			# The last side ends at angle 0 itself, not at a whole turn, so it
			# meets the first side's corners exactly.
			rim_point = |r, k| {
				angle = F64.tau * (k % sides).to_f64() / sides.to_f64()
				Point.at(cx + r * angle.cos(), cy + r * angle.sin())
			}
			var $out = List.with_capacity(sides)
			for k in 0..<sides {
				sector = Quad({
					first: rim_point(outer_radius, k),
					second: rim_point(outer_radius, k + 1),
					third: rim_point(inner_radius, k + 1),
					fourth: rim_point(inner_radius, k),
					fill,
				})
				$out = $out.append(sector)
			}
			$out
		}

	## Every x pulled toward `axis` by `cosine`, so a figure drawn face-on reads as one
	## turned away by the angle whose cosine that is. A negative cosine mirrors it as
	## well, so a pair beside a path can face each other. A disc keeps its radius,
	## because no shape here is an ellipse. A mirror only reverses the order a
	## region's corners go round in, which no painter minds. Only a flat fill can
	## be squashed: a gradient's geometry would stay where it was while its shape
	## moved, so a region with a gradient crashes.
	squashed_shapes : List(Shapes.Shape), { axis : Pixels, cosine : F64 } -> List(Shapes.Shape)
	squashed_shapes = |shapes, { axis, cosine: k }| shapes.map(
		|shape|
			match shape {
				Triangle(t) =>
					Triangle({
						first: pulled_point(t.first, { axis, cosine: k }),
						second: pulled_point(t.second, { axis, cosine: k }),
						third: pulled_point(t.third, { axis, cosine: k }),
						fill: squashable_fill(t.fill),
					})
				Quad(q) =>
					Quad({
						first: pulled_point(q.first, { axis, cosine: k }),
						second: pulled_point(q.second, { axis, cosine: k }),
						third: pulled_point(q.third, { axis, cosine: k }),
						fourth: pulled_point(q.fourth, { axis, cosine: k }),
						fill: squashable_fill(q.fill),
					})
				Polygon(p) => Polygon({ corners: p.corners.map(|corner| pulled_point(corner, { axis, cosine: k })), fill: squashable_fill(p.fill) })
				Disc(d) => Disc({ center: pulled_point(d.center, { axis, cosine: k }), radius: d.radius, fill: squashable_fill(d.fill) })
				Blend(m) => Blend(m)
				View(l) => View(l)
				# A mirror sends a picture's left edge to its right, and a width is
				# never negative.
				Image(i) => {
					span = pulled_span({ x: i.x, width: i.width }, { axis: axis.to_f64(), cosine: k })
					Image({ ..i, x: span.x, width: span.width })
				}
				# Type keeps its letterforms, so only its place moves.
				Text(t) => Text({ ..t, x: axis.to_f64() + (t.x - axis.to_f64()) * k })
			},
	)

	## A picture `cols` by `rows` pixels, row by row, stretched over the box. A
	## pixel list of any other length crashes: a painter would read past its end
	## or leave some of it out.
	image : { x : F64, y : F64, width : F64, height : F64, cols : U64, rows : U64, pixels : List(Brush.Rgba) } -> Shapes.Shape
	image = |picture|
		if picture.pixels.len() != picture.cols * picture.rows {
			crash "Shapes.image: a picture's pixels number its cols times its rows"
		} else {
			Image(picture)
		}

	## Light in `color` at the middle, at the colour's own alpha, fading to
	## nothing at `radius`.
	halo : { center : Point.Point, radius : Pixels }, Brush.Rgba -> Shapes.Shape
	halo = |{ center, radius }, color|
		Disc({
			center,
			radius,
			fill: Radial({ inner_color: color, outer_color: { ..color, a: 0.0 }, center, inner_radius: Pixels.zero, outer_radius: radius }),
		})

	## A rectangle whose corners are rounded by `corner_radius`, each corner drawn in
	## `corner_steps` steps. A radius of zero or no steps gives the plain box, and a
	## radius too big for the box is held to half its shorter side.
	rounded_rect : { top_left : Point.Point, width : Pixels, height : Pixels, corner_radius : Pixels, corner_steps : U64 }, Brush.Fill -> Shapes.Shape
	rounded_rect = |box, fill| {
		x = box.top_left.x.to_f64()
		y = box.top_left.y.to_f64()
		width = box.width.to_f64()
		height = box.height.to_f64()
		corner_steps = box.corner_steps
		radius = box.corner_radius.to_f64().min((width / 2.0).min(height / 2.0))
		if radius <= 0.0 or corner_steps == 0 {
			Shapes.rectangle({ top_left: box.top_left, width: box.width, height: box.height, fill })
		} else {
			var $corners = List.with_capacity(4 * (corner_steps + 1))
			# Clockwise from the top-left corner, each swept from its own start angle.
			$corners = quarter_turn_corners($corners, { center: { x: x + radius, y: y + radius }, radius, start_angle: half_pi * 2.0, steps: corner_steps })
			$corners = quarter_turn_corners($corners, { center: { x: x + width - radius, y: y + radius }, radius, start_angle: -half_pi, steps: corner_steps })
			$corners = quarter_turn_corners($corners, { center: { x: x + width - radius, y: y + height - radius }, radius, start_angle: 0.0, steps: corner_steps })
			$corners = quarter_turn_corners($corners, { center: { x: x + radius, y: y + height - radius }, radius, start_angle: half_pi, steps: corner_steps })
			Polygon({ corners: $corners, fill })
		}
	}
}

## A squashed shape's fill, which must be flat: a gradient's geometry is in the
## shape's coordinates, and squashing moves the shape but not the gradient.
squashable_fill : Brush.Fill -> Brush.Fill
squashable_fill = |fill|
	match fill {
		Flat(_) => fill
		Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
			crash "Shapes.squashed_shapes: a gradient fill would not move with its shape"
	}

## A point's x pulled toward `axis` by `cosine`.
pulled_point : Point.Point, { axis : Pixels, cosine : F64 } -> Point.Point
pulled_point = |{ x, y }, { axis, cosine: k }| { x: Pixels.of(axis.to_f64() + (x.to_f64() - axis.to_f64()) * k), y }

## A span across x pulled toward `axis` by `cosine`, each edge on its own. A
## mirror sends the left edge to the right, so the span starts at whichever
## edge lands leftmost.
pulled_span : { x : F64, width : F64 }, { axis : F64, cosine : F64 } -> { x : F64, width : F64 }
pulled_span = |{ x, width }, { axis, cosine: k }| {
	start_x = axis + (x - axis) * k
	end_x = axis + (x + width - axis) * k
	{ x: start_x.min(end_x), width: (end_x - start_x).abs() }
}

half_pi : F64
half_pi = F64.pi / 2.0

## The corners of a quarter turn about `center`, starting at `start_angle`,
## onto `corners`.
quarter_turn_corners : List(Point.Point), { center : { x : F64, y : F64 }, radius : F64, start_angle : F64, steps : U64 } -> List(Point.Point)
quarter_turn_corners = |corners, { center, radius, start_angle, steps }| {
	var $out = corners
	for k in 0..=steps {
		a = start_angle + half_pi * k.to_f64() / steps.to_f64()
		$out = $out.append(Point.at(center.x + radius * a.cos(), center.y + radius * a.sin()))
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

expect Shapes.squashed_shapes([Text(line_of_type)], { axis: Pixels.of(0.0), cosine: 0.5 }) == [Text({ ..line_of_type, x: 50.0 })]
expect Shapes.squashed_shapes([Text(line_of_type)], { axis: Pixels.of(0.0), cosine: -1.0 }) == [Text({ ..line_of_type, x: -100.0 })]
expect Shapes.squashed_shapes([Text(line_of_type)], { axis: Pixels.of(100.0), cosine: 0.5 }) == [Text(line_of_type)]

## The fill the shapes below are drawn in.
ink : Brush.Fill
ink = Flat({ r: 32.0, g: 32.0, b: 32.0, a: 1.0 })

## A dot of light, as the shape both brackets hold.
dot : Shapes.Shape
dot = Disc({ center: Point.at(1.0, 2.0), radius: Pixels.of(3.0), fill: ink })

expect Shapes.added_light_shapes([dot]) == [Blend(Add), dot, Blend(Over)]
expect Shapes.added_light_shapes([]) == [Blend(Add), Blend(Over)]
expect Shapes.shapes_in_space(Screen, [dot]) == [View(Screen), dot, View(Screen)]
expect Shapes.shapes_in_space(Screen, []) == [View(Screen), View(Screen)]
expect Shapes.lists_in_space(Screen, [[dot], [], [ink_dot, dot]]) == [View(Screen), dot, ink_dot, dot, View(Screen)]
expect Shapes.lists_in_space(Screen, []) == [View(Screen), View(Screen)]

## A second dot, so an order shows.
ink_dot : Shapes.Shape
ink_dot = Disc({ center: Point.at(5.0, 6.0), radius: Pixels.of(1.0), fill: ink })

# A small zoom, near the zero it refuses, makes a world space.
expect {
	corner = Point.at(0.0, 0.0)
	world = { target: corner, offset: corner, rotation: 0.0, zoom: 0.001 }
	Shapes.world_space(world) == World(world)
}

# A picture two pixels wide and one high holds two pixels.
expect {
	white = { r: 255.0, g: 255.0, b: 255.0, a: 1.0 }
	picture = { x: 0.0, y: 0.0, width: 4.0, height: 2.0, cols: 2, rows: 1, pixels: [white, white] }
	Shapes.image(picture) == Image(picture)
}

## Five corners round a house's end: up a wall, the roof's two slopes, down the
## other wall, and back along the floor.
house_corners : List(Point.Point)
house_corners = [Point.at(10.0, 1.0), Point.at(10.0, 5.0), Point.at(20.0, 9.0), Point.at(30.0, 5.0), Point.at(30.0, 1.0)]

# A flat polygon and a flat disc are squashed toward the axis with their fills.
expect
	Shapes.squashed_shapes([Polygon({ corners: house_corners, fill: ink }), dot], { axis: Pixels.of(10.0), cosine: 0.5 })
		== [
			Polygon({ corners: [Point.at(10.0, 1.0), Point.at(10.0, 5.0), Point.at(15.0, 9.0), Point.at(20.0, 5.0), Point.at(20.0, 1.0)], fill: ink }),
			Disc({ center: Point.at(5.5, 2.0), radius: Pixels.of(3.0), fill: ink }),
		]

# A triangle's corners are squashed as a polygon's are.
expect
	Shapes.squashed_shapes([Triangle({ first: Point.at(10.0, 1.0), second: Point.at(20.0, 2.0), third: Point.at(30.0, 3.0), fill: ink })], { axis: Pixels.of(10.0), cosine: 0.5 })
		== [Triangle({ first: Point.at(10.0, 1.0), second: Point.at(15.0, 2.0), third: Point.at(20.0, 3.0), fill: ink })]

# A mirrored rectangle keeps its corners in their order, so its left corners
# land on the right: the quad goes round the other way.
expect
	Shapes.squashed_shapes([Shapes.rectangle({ top_left: Point.at(20.0, 1.0), width: Pixels.of(10.0), height: Pixels.of(4.0), fill: ink })], { axis: Pixels.of(10.0), cosine: -0.5 })
		== [Quad({ first: Point.at(5.0, 1.0), second: Point.at(0.0, 1.0), third: Point.at(0.0, 5.0), fourth: Point.at(5.0, 5.0), fill: ink })]

# A rectangle is the quad clockwise on the screen from its top left corner.
expect
	Shapes.rectangle({ top_left: Point.at(2.0, 3.0), width: Pixels.of(4.0), height: Pixels.of(5.0), fill: ink })
		== Quad({ first: Point.at(2.0, 3.0), second: Point.at(6.0, 3.0), third: Point.at(6.0, 8.0), fourth: Point.at(2.0, 8.0), fill: ink })

# Three corners make a triangle, four a quad, and five a polygon, and each
# gives back the corners it was made from.
expect {
	three = house_corners.take_first(3)
	four = house_corners.take_first(4)
	tagged = [three, four, house_corners].map(|corners| Shapes.region_from_corners(corners, ink))
	match tagged {
		[Triangle(_), Quad(_), Polygon(_)] =>
			tagged.map(Shapes.region_corners) == [Ok(three), Ok(four), Ok(house_corners)]
		_ => False
	}
}

# Fewer than three corners enclose nothing, and are still a polygon rather
# than a crash.
expect {
	two = house_corners.take_first(2)
	Shapes.region_from_corners(two, ink) == Polygon({ corners: two, fill: ink })
}

# A disc and a mark have no corners.
expect [dot, Blend(Add)].map(Shapes.region_corners) == [Err(NoCorners), Err(NoCorners)]

# A horizontal line two wide stands one each side of its axis.
expect
	Shapes.line({ from: Point.at(0.0, 0.0), to: Point.at(10.0, 0.0), width: Pixels.of(2.0) }, ink)
		== Quad({ first: Point.at(0.0, 1.0), second: Point.at(10.0, 1.0), third: Point.at(10.0, -1.0), fourth: Point.at(0.0, -1.0), fill: ink })

# The fewest sides a ring may have make three sectors.
expect Shapes.ring_shapes({ center: Point.at(0.0, 0.0), radius: Pixels.of(5.0), line_width: Pixels.of(1.0), sides: 3 }, ink).len() == 3

## A ring sector's corners: outer start, outer end, inner end, inner start.
sector_corners : Shapes.Shape -> List(Point.Point)
sector_corners = |shape|
	match shape {
		Quad(q) => [q.first, q.second, q.third, q.fourth]
		Triangle(_) | Disc(_) | Polygon(_) | Blend(_) | View(_) | Image(_) | Text(_) => crash "Shapes: a ring's sectors are all quads"
	}

# Each sector starts where the one before it ends, outer corner and inner
# corner, all the way round to the first again. Its inner corners sit nearer
# the center than its outer ones, by the line's width.
expect {
	sectors = Shapes.ring_shapes({ center: Point.at(3.0, 4.0), radius: Pixels.of(10.0), line_width: Pixels.of(2.0), sides: 7 }, ink).map(sector_corners)
	first = sectors.first() ?? crash "Shapes: a ring of seven sides has sectors"
	following = sectors.drop_first(1).append(first)
	shared = sectors.map2(following, |sector, next| sector.get(1) == next.get(0) and sector.get(2) == next.get(3))
	outer = first.get(0) ?? crash "Shapes: a sector has an outer start corner"
	inner = first.get(3) ?? crash "Shapes: a sector has an inner start corner"
	sectors.len() == 7 and shared.all(|same| same) and outer.x - inner.x == Pixels.of(2.0)
}
