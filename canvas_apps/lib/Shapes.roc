## Shapes is the vocabulary every app's frame is written in. A frame is a list
## of these shapes in the app's own coordinates, and each painter draws the list
## in order. What one app draws is built in that app's own folder. Rings and
## rounded boxes are built in `CurvedShapes`, and a figure turned away from the
## viewer in `Squash`, both from these shapes.
import Brush
import Pixels
import Point

Shapes :: [].{

	## One thing in a frame. A later shape in the list paints over an earlier one.
	## A shape is a region and a fill: any of the four regions takes any fill.
	Shape : [
		## Three corners, which is every triangle and nothing else.
		Triangle(
			{
				first : Point,
				second : Point,
				third : Point,
				fill : Brush.Fill,
			},
		),

		## Four corners in order around the edge. `Shapes.rectangle` makes an
		## upright one.
		Quad(
			{
				first : Point,
				second : Point,
				third : Point,
				fourth : Point,
				fill : Brush.Fill,
			},
		),

		## A circle, `radius` out from `center`.
		Disc(
			{
				center : Point,
				radius : Pixels,
				fill : Brush.Fill,
			},
		),

		## An outline of any other number of corners, in order around its edge: a
		## traced still, a mountain, the road.
		Polygon({ corners : List(Point), fill : Brush.Fill }),

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
		Image(
			{
				x : F64,
				y : F64,
				width : F64,
				height : F64,
				cols : U64,
				rows : U64,
				pixels : List(Brush.Rgba),
			},
		),

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
		World(
			{
				target : Point,
				offset : Point,
				rotation : F64,
				zoom : F64,
			},
		),
	]

	## A `World` space, its zoom checked. A zoom of zero has no inverse, so a
	## painter could not map the screen back into this space, and a zoom that is
	## not finite comes only from a bug; either crashes.
	world_space : {
		target : Point,
		offset : Point,
		rotation : F64,
		zoom : F64,
	} -> Shapes.Space
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
	lists_in_space = |
		space,
		shape_lists,
	| List.concat([[View(space)]], shape_lists).append([View(Screen)]).join()

	## The region round `corners`, in order, tagged by how many there are: three
	## make a `Triangle`, four a `Quad`, and any other number a `Polygon`. Every
	## maker that works through a list of corners comes here, so the count
	## always matches the tag.
	region_from_corners : List(Point), Brush.Fill -> Shapes.Shape
	region_from_corners = |corners, fill|
		match corners {
			[first, second, third] => Triangle({ first, second, third, fill })
			[first, second, third, fourth] => Quad({ first, second, third, fourth, fill })
			_ => Polygon({ corners, fill })
		}

	## The corners of a straight-edged region, in order round its edge. A disc,
	## a picture, a line of type and a mark have no corners to give.
	region_corners : Shapes.Shape -> Try(List(Point), [NoCorners])
	region_corners = |shape|
		match shape {
			Triangle(triangle) => Ok([triangle.first, triangle.second, triangle.third])
			Quad(quad) => Ok([quad.first, quad.second, quad.third, quad.fourth])
			Polygon(polygon) => Ok(polygon.corners)
			Disc(_) | Image(_) | Text(_) | Blend(_) | View(_) => Err(NoCorners)
		}

	## An upright box, `width` across and `height` down from `top_left`, as the
	## quad it is: clockwise on the screen from its top left corner.
	rectangle : {
		top_left : Point,
		width : Pixels,
		height : Pixels,
		fill : Brush.Fill,
	} -> Shapes.Shape
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
	line : {
		from : Point,
		to : Point,
		width : Pixels,
	},
	Brush.Fill -> Shapes.Shape
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

	## A picture `cols` by `rows` pixels, row by row, stretched over the box. A
	## pixel list of any other length crashes: a painter would read past its end
	## or leave some of it out.
	image : {
		x : F64,
		y : F64,
		width : F64,
		height : F64,
		cols : U64,
		rows : U64,
		pixels : List(Brush.Rgba),
	} -> Shapes.Shape
	image = |picture|
		if picture.pixels.len() != picture.cols * picture.rows {
			crash "Shapes.image: a picture's pixels number its cols times its rows"
		} else {
			Image(picture)
		}

	## Light in `color` at the middle, at the colour's own alpha, fading to
	## nothing at `radius`.
	halo : { center : Point, radius : Pixels }, Brush.Rgba -> Shapes.Shape
	halo = |{ center, radius }, color|
		Disc({
			center,
			radius,
			fill: Radial({
				inner_color: color,
				outer_color: { ..color, a: 0.0 },
				center,
				inner_radius: Pixels.zero,
				outer_radius: radius,
			}),
		})
}

## The fill the shapes below are drawn in.
ink : Brush.Fill
ink = Flat({
	r: 32.0,
	g: 32.0,
	b: 32.0,
	a: 1.0,
})

## A dot of light, as the shape both brackets hold.
dot : Shapes.Shape
dot = Disc({
	center: Point.at(1.0, 2.0),
	radius: Pixels.of(3.0),
	fill: ink,
})

expect Shapes.added_light_shapes([dot]) == [Blend(Add), dot, Blend(Over)]
expect Shapes.added_light_shapes([]) == [Blend(Add), Blend(Over)]
expect Shapes.shapes_in_space(Screen, [dot]) == [View(Screen), dot, View(Screen)]
expect Shapes.shapes_in_space(Screen, []) == [View(Screen), View(Screen)]
expect Shapes.lists_in_space(Screen, [[dot], [], [ink_dot, dot]]) == [
	View(Screen),
	dot,
	ink_dot,
	dot,
	View(Screen),
]
expect Shapes.lists_in_space(Screen, []) == [View(Screen), View(Screen)]

## A second dot, so an order shows.
ink_dot : Shapes.Shape
ink_dot = Disc({
	center: Point.at(5.0, 6.0),
	radius: Pixels.of(1.0),
	fill: ink,
})

# A small zoom, near the zero it refuses, makes a world space.
expect {
	corner = Point.at(0.0, 0.0)
	world = {
		target: corner,
		offset: corner,
		rotation: 0.0,
		zoom: 0.001,
	}
	Shapes.world_space(world) == World(world)
}

# A picture two pixels wide and one high holds two pixels.
expect {
	white = {
		r: 255.0,
		g: 255.0,
		b: 255.0,
		a: 1.0,
	}
	picture = {
		x: 0.0,
		y: 0.0,
		width: 4.0,
		height: 2.0,
		cols: 2,
		rows: 1,
		pixels: [white, white],
	}
	Shapes.image(picture) == Image(picture)
}

## Five corners round a house's end: up a wall, the roof's two slopes, down the
## other wall, and back along the floor.
house_corners : List(Point)
house_corners = [
	Point.at(10.0, 1.0),
	Point.at(10.0, 5.0),
	Point.at(20.0, 9.0),
	Point.at(30.0, 5.0),
	Point.at(30.0, 1.0),
]

# A rectangle is the quad clockwise on the screen from its top left corner.
expect
	Shapes.rectangle({
		top_left: Point.at(2.0, 3.0),
		width: Pixels.of(4.0),
		height: Pixels.of(5.0),
		fill: ink,
	})
		== Quad({
			first: Point.at(2.0, 3.0),
			second: Point.at(6.0, 3.0),
			third: Point.at(6.0, 8.0),
			fourth: Point.at(2.0, 8.0),
			fill: ink,
		})

# Three corners make a triangle, four a quad, and five a polygon, and each
# gives back the corners it was made from.
expect {
	three = house_corners.take_first(3)
	four = house_corners.take_first(4)
	tagged = [three, four, house_corners].map(|corners| Shapes.region_from_corners(corners, ink))
	match tagged {
		[
			Triangle(_),
			Quad(_),
			Polygon(_),
		] =>
			tagged.map(Shapes.region_corners) == [
				Ok(three),
				Ok(four),
				Ok(house_corners),
			]
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
	Shapes.line(
		{
			from: Point.at(0.0, 0.0),
			to: Point.at(10.0, 0.0),
			width: Pixels.of(2.0),
		},
		ink,
	)
		== Quad({
			first: Point.at(0.0, 1.0),
			second: Point.at(10.0, 1.0),
			third: Point.at(10.0, -1.0),
			fourth: Point.at(0.0, -1.0),
			fill: ink,
		})
