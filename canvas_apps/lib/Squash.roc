## Squash turns a figure drawn face-on into the same figure turned away from the
## viewer, about an upright axis. Each x is pulled toward the axis by the
## cosine of the turn, and every y stays where it was, so a flat cut-out seems
## to swing like a door. The shapes are `Shapes`' own, and the squashed list is
## a frame's like any other.
import Brush
import Pixels
import Point
import Shapes

Squash :: [].{

	## Every x pulled toward `axis` by `cosine`, so a figure drawn face-on reads as one
	## turned away by the angle whose cosine that is. A negative cosine mirrors it as
	## well, so a pair beside a path can face each other. A disc keeps its radius,
	## because no shape here is an ellipse. A mirror only reverses the order a
	## region's corners go round in, which no painter minds. Only a flat fill can
	## be squashed: a gradient's geometry would stay where it was while its shape
	## moved, so a region with a gradient crashes.
	squashed_shapes : List(Shapes.Shape), { axis : Pixels, cosine : F64 } -> List(Shapes.Shape)
	squashed_shapes = |shapes, { axis, cosine }| shapes.map(
		|shape|
			match shape {
				Triangle(triangle) =>
					Triangle({
						first: pulled_point(triangle.first, { axis, cosine }),
						second: pulled_point(triangle.second, { axis, cosine }),
						third: pulled_point(triangle.third, { axis, cosine }),
						fill: squashable_fill(triangle.fill),
					})
				Quad(quad) =>
					Quad({
						first: pulled_point(quad.first, { axis, cosine }),
						second: pulled_point(quad.second, { axis, cosine }),
						third: pulled_point(quad.third, { axis, cosine }),
						fourth: pulled_point(quad.fourth, { axis, cosine }),
						fill: squashable_fill(quad.fill),
					})
				Polygon(polygon) => Polygon({
					corners: polygon.corners.map(|corner| pulled_point(corner, { axis, cosine })),
					fill: squashable_fill(polygon.fill),
				})
				Disc(disc) => Disc({
					center: pulled_point(disc.center, { axis, cosine }),
					radius: disc.radius,
					fill: squashable_fill(disc.fill),
				})
				Blend(blend) => Blend(blend)
				View(view) => View(view)
				# A mirror sends a picture's left edge to its right, and a width is
				# never negative.
				Image(image) => {
					span = pulled_span(
						{ x: image.x, width: image.width },
						{ axis: axis.to_f64(), cosine },
					)
					Image({ ..image, x: span.x, width: span.width })
				}
				# Type keeps its letterforms, so only its place moves.
				Text(text_line) => Text({ ..text_line, x: axis.to_f64() + (text_line.x - axis.to_f64()) * cosine })
			},
	)
}

## A squashed shape's fill, which must be flat: a gradient's geometry is in the
## shape's coordinates, and squashing moves the shape but not the gradient.
squashable_fill : Brush.Fill -> Brush.Fill
squashable_fill = |fill|
	match fill {
		Flat(_) => fill
		Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
			crash "Squash.squashed_shapes: a gradient fill would not move with its shape"
	}

## A point's x pulled toward `axis` by `cosine`.
pulled_point : Point, { axis : Pixels, cosine : F64 } -> Point
pulled_point = |{ x, y }, { axis, cosine }| {
	x: Pixels.of(axis.to_f64() + (x.to_f64() - axis.to_f64()) * cosine),
	y,
}

## A span across x pulled toward `axis` by `cosine`, each edge on its own. A
## mirror sends the left edge to the right, so the span starts at whichever
## edge lands leftmost.
pulled_span : { x : F64, width : F64 }, { axis : F64, cosine : F64 } -> { x : F64, width : F64 }
pulled_span = |{ x, width }, { axis, cosine }| {
	start_x = axis + (x - axis) * cosine
	end_x = axis + (x + width - axis) * cosine
	{ x: F64.min(start_x, end_x), width: (end_x - start_x).abs() }
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
	color: {
		r: 32.0,
		g: 32.0,
		b: 32.0,
		a: 1.0,
	},
}

expect Squash.squashed_shapes(
	[Text(line_of_type)],
	{ axis: Pixels.of(0.0), cosine: 0.5 },
) == [Text({ ..line_of_type, x: 50.0 })]
expect Squash.squashed_shapes(
	[Text(line_of_type)],
	{ axis: Pixels.of(0.0), cosine: -1.0 },
) == [Text({ ..line_of_type, x: -100.0 })]
expect Squash.squashed_shapes(
	[Text(line_of_type)],
	{ axis: Pixels.of(100.0), cosine: 0.5 },
) == [Text(line_of_type)]

## The fill the shapes below are drawn in.
ink : Brush.Fill
ink = Flat({
	r: 32.0,
	g: 32.0,
	b: 32.0,
	a: 1.0,
})

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

# A flat polygon and a flat disc are squashed toward the axis with their fills.
expect
	Squash.squashed_shapes(
		[
			Polygon({ corners: house_corners, fill: ink }),
			Disc({
				center: Point.at(1.0, 2.0),
				radius: Pixels.of(3.0),
				fill: ink,
			}),
		],
		{ axis: Pixels.of(10.0), cosine: 0.5 },
	)
		== [
			Polygon({
				corners: [
					Point.at(10.0, 1.0),
					Point.at(10.0, 5.0),
					Point.at(15.0, 9.0),
					Point.at(20.0, 5.0),
					Point.at(20.0, 1.0),
				],
				fill: ink,
			}),
			Disc({
				center: Point.at(5.5, 2.0),
				radius: Pixels.of(3.0),
				fill: ink,
			}),
		]

# A triangle's corners are squashed as a polygon's are.
expect
	Squash.squashed_shapes(
		[
			Triangle({
				first: Point.at(10.0, 1.0),
				second: Point.at(20.0, 2.0),
				third: Point.at(30.0, 3.0),
				fill: ink,
			}),
		],
		{ axis: Pixels.of(10.0), cosine: 0.5 },
	)
		== [
			Triangle({
				first: Point.at(10.0, 1.0),
				second: Point.at(15.0, 2.0),
				third: Point.at(20.0, 3.0),
				fill: ink,
			}),
		]

# A mirrored rectangle keeps its corners in their order, so its left corners
# land on the right: the quad goes round the other way.
expect
	Squash.squashed_shapes(
		[
			Shapes.rectangle({
				top_left: Point.at(20.0, 1.0),
				width: Pixels.of(10.0),
				height: Pixels.of(4.0),
				fill: ink,
			}),
		],
		{ axis: Pixels.of(10.0), cosine: -0.5 },
	)
		== [
			Quad({
				first: Point.at(5.0, 1.0),
				second: Point.at(0.0, 1.0),
				third: Point.at(0.0, 5.0),
				fourth: Point.at(5.0, 5.0),
				fill: ink,
			}),
		]
