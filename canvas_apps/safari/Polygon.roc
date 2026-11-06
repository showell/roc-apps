## Polygon makes Safari's polygons as values, from screen points and
## whole-number colors. Nothing here paints: what a maker gives back is data for
## the page to paint. A color is 0xRRGGBB for a flat or a shaded polygon, and
## 0xAARRGGBB for a gradient. Each maker gives one shape. A polygon of fewer than
## three corners is a bug in the code that asked for it, so a maker crashes on one.
## A drawing module with nothing to draw says so itself, in the list it answers.
import Pixels
import Fraction
import HexColor
import Screen
import lib.Brush
import lib.Shapes

Polygon :: [].{

	## A gradient's two colors, and where each sits along it.
	ColorStops : {
		start_rgba : I64,
		end_rgba : I64,
		start_offset : F64,
		end_offset : F64,
	}

	## A radial gradient smaller than this is too small to see. A caller tests for
	## that before it asks for one.
	min_gradient_radius : Pixels
	min_gradient_radius = Pixels.of(0.5)

	## Makes a polygon of one flat color. Nothing is painted here: this makes a value.
	flat_polygon : I64, List(Screen.Point) -> Shapes.Shape
	flat_polygon = |color, corners|
		Poly({ pts: polygon_points("Polygon.flat_polygon", corners), fill: Flat(Brush.opaque(color)) })

	## Makes a triangle of one flat color.
	triangle : I64,
	{
		first_corner : Screen.Point,
		second_corner : Screen.Point,
		third_corner : Screen.Point,
	} -> Shapes.Shape
	triangle = |color, { first_corner, second_corner, third_corner }|
		flat_polygon(color, [first_corner, second_corner, third_corner])

	## Makes a rectangle of one flat color. Its sides run along the screen's edges.
	rectangle : I64, { top_left : Screen.Point, bottom_right : Screen.Point } -> Shapes.Shape
	rectangle = |color, opposite_corners| flat_polygon(color, rectangle_corners(opposite_corners))

	## A rectangle's four corners, clockwise on the screen from its top left.
	rectangle_corners : {
		top_left : Screen.Point,
		bottom_right : Screen.Point,
	} -> List(Screen.Point)
	rectangle_corners = |{ top_left, bottom_right }| [
		top_left,
		{ x: bottom_right.x, y: top_left.y },
		bottom_right,
		{ x: top_left.x, y: bottom_right.y },
	]

	## Makes a polygon shaded across its width, darker at its edges and lighter in
	## its middle, or a solid one where it has no strength or is too narrow.
	shaded_polygon : List(Screen.Point),
	{
		fill_color : I64,
		strength : Fraction,
	} -> Shapes.Shape
	shaded_polygon = |corners, { fill_color, strength }| {
		pts = polygon_points("Polygon.shaded_polygon", corners)
		Poly({ pts, fill: width_shade(corners, { color: fill_color, strength: strength }) })
	}

	## Makes a polygon filled by a gradient that spreads in a circle from
	## `gradient_center`. A radius under `min_gradient_radius` crashes.
	gradient_polygon : List(Screen.Point),
	{
		center_rgba : I64,
		edge_rgba : I64,
		gradient_center : Screen.Point,
		gradient_radius : Pixels,
	} -> Shapes.Shape
	gradient_polygon = |corners, { center_rgba, edge_rgba, gradient_center, gradient_radius }|
		if gradient_radius < Polygon.min_gradient_radius {
			crash "Polygon.gradient_polygon: the caller tests for too small a radius"
		} else {
			Poly({
				pts: polygon_points("Polygon.gradient_polygon", corners),
				fill: Radial({
					inner: Brush.with_alpha(center_rgba),
					outer: Brush.with_alpha(edge_rgba),
					x: gradient_center.x.to_f64(),
					y: gradient_center.y.to_f64(),
					r0: 0.0,
					r1: gradient_radius.to_f64(),
				}),
			})
		}

	## Makes a polygon filled by a gradient along a line. A gradient with no length
	## has no direction, so that crashes.
	linear_gradient_polygon : List(Screen.Point),
	{
		color_stops : Polygon.ColorStops,
		start_point : Screen.Point,
		end_point : Screen.Point,
	} -> Shapes.Shape
	linear_gradient_polygon = |corners, { color_stops, start_point, end_point }| {
		dx = end_point.x.minus(start_point.x).to_f64()
		dy = end_point.y.minus(start_point.y).to_f64()
		if dx * dx + dy * dy == 0.0 {
			crash "Polygon.linear_gradient_polygon: a gradient has a length"
		} else {
			offsets = offsets_of(color_stops)
			Poly({
				pts: polygon_points("Polygon.linear_gradient_polygon", corners),
				fill: Linear({
					c0: Brush.with_alpha(color_stops.start_rgba),
					c1: Brush.with_alpha(color_stops.end_rgba),
					o0: offsets.first,
					o1: offsets.last,
					ax: start_point.x.to_f64(),
					ay: start_point.y.to_f64(),
					dx,
					dy,
				}),
			})
		}
	}

	## Makes a polygon filled by a gradient on an ellipse, which is `axis_u` and
	## `axis_v` about `center_point`. An ellipse too thin to invert is filled with
	## its first color.
	radial_gradient_polygon : List(Screen.Point),
	{
		color_stops : Polygon.ColorStops,
		center_point : Screen.Point,
		axis_u : Screen.Point,
		axis_v : Screen.Point,
	} -> Shapes.Shape
	radial_gradient_polygon = |corners, { color_stops, center_point, axis_u, axis_v }| {
		ux = axis_u.x.to_f64()
		uy = axis_u.y.to_f64()
		vx = axis_v.x.to_f64()
		vy = axis_v.y.to_f64()
		det = ux * vy - uy * vx
		first_color = Brush.with_alpha(color_stops.start_rgba)
		fill =
			if det.abs() < min_ellipse_determinant {
				Flat(first_color)
			} else {
				offsets = offsets_of(color_stops)
				Ellipse({
					c0: first_color,
					c1: Brush.with_alpha(color_stops.end_rgba),
					o0: offsets.first,
					o1: offsets.last,
					x: center_point.x.to_f64(),
					y: center_point.y.to_f64(),
					ia: vy / det,
					ib: (0.0 - vx) / det,
					ic: (0.0 - uy) / det,
					id: ux / det,
				})
			}
		Poly({ pts: polygon_points("Polygon.radial_gradient_polygon", corners), fill })
	}

	## The flat list of numbers that lib.Shapes takes for a polygon's corners.
	flatten_screen : List(Screen.Point) -> List(F64)
	flatten_screen = |corners| {
		var $flat = List.with_capacity(2 * corners.len())
		for corner in corners {
			$flat = $flat.append(corner.x.to_f64()).append(corner.y.to_f64())
		}
		$flat
	}
}

## The numbers of a polygon's corners. Fewer than three corners enclose nothing,
## so that crashes, naming the `maker` that was asked.
polygon_points : Str, List(Screen.Point) -> List(F64)
polygon_points = |maker, corners|
	if corners.len() < 3 {
		crash "${maker}: a polygon needs three corners"
	} else {
		Polygon.flatten_screen(corners)
	}

## The span of x a polygon covers. Either end is negative for a polygon off the
## left of the screen.
Span : { min_x : Pixels, max_x : Pixels }

shade_edge_darken : Fraction
shade_edge_darken = Fraction.of(0.4)

shade_middle_lift : Fraction
shade_middle_lift = Fraction.of(0.25)

## A shaded polygon's color at its edges.
width_shade_edge : I64, Fraction -> I64
width_shade_edge = |color, strength|
	HexColor.shade_color(color, 1.0 - shade_edge_darken.to_f64() * strength.to_f64())

## A shaded polygon's color in its middle.
width_shade_middle : I64, Fraction -> I64
width_shade_middle = |color, strength| HexColor.shade_color(
	color,
	1.0 + shade_middle_lift.to_f64() * strength.to_f64(),
)

min_shade_width : Pixels
min_shade_width = Pixels.of(1.0)

is_too_narrow_to_shade : Span -> Bool
is_too_narrow_to_shade = |span| span.max_x.minus(span.min_x) < min_shade_width

## The span of x over a polygon's corners. It has at least one corner.
x_span : List(Screen.Point) -> Span
x_span = |corners|
	match corners.map(|corner| corner.x) {
		[first, .. as rest] => {
			min_x: rest.fold(
				first,
				|least, x|
					if x < least {
						x
					} else {
						least
					},
			),
			max_x: rest.fold(
				first,
				|most, x|
					if x > most {
						x
					} else {
						most
					},
			),
		}
		[] => crash "Polygon.x_span: a polygon has a corner"
	}

min_ellipse_determinant : F64
min_ellipse_determinant = 0.0001

## A gradient's offsets held to 0 to 1, the last never before the first.
offsets_of : Polygon.ColorStops -> { first : F64, last : F64 }
offsets_of = |stops| {
	first = Brush.clamp01(stops.start_offset)
	{ first, last: first.max(F64.min(1.0, stops.end_offset)) }
}

## The fill of a polygon shaded across its width.
width_shade : List(Screen.Point), { color : I64, strength : Fraction } -> Brush.Fill
width_shade = |corners, { color, strength }| {
	span = x_span(corners)
	if strength <= Fraction.zero or is_too_narrow_to_shade(span) {
		Flat(Brush.opaque(color))
	} else {
		Span({
			edge: Brush.opaque(width_shade_edge(color, strength)),
			middle: Brush.opaque(width_shade_middle(color, strength)),
			x0: span.min_x.to_f64(),
			x1: span.max_x.to_f64(),
		})
	}
}

three_corners : List(Screen.Point)
three_corners = [
	Screen.point(1.0, 2.0),
	Screen.point(3.0, 4.0),
	Screen.point(5.0, 6.0),
]

triangle_points : List(F64)
triangle_points = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

origin : Screen.Point
origin = Screen.point(0.0, 0.0)

plain_stops : Polygon.ColorStops
plain_stops = {
	start_rgba: 7,
	end_rgba: 8,
	start_offset: 0.0,
	end_offset: 1.0,
}

inner_stops : Polygon.ColorStops
inner_stops = {
	start_rgba: 666,
	end_rgba: 667,
	start_offset: 0.25,
	end_offset: 0.75,
}

radial_polygon : List(Screen.Point), Pixels -> Shapes.Shape
radial_polygon = |corners, gradient_radius|
	Polygon.gradient_polygon(
		corners,
		{
			center_rgba: 7,
			edge_rgba: 8,
			gradient_center: origin,
			gradient_radius,
		},
	)

expect Polygon.flatten_screen(three_corners) == triangle_points
expect Polygon.flatten_screen([]) == []

# A triangle keeps its corners in the order given.
expect
	Polygon.triangle(
		111,
		{
			first_corner: Screen.point(1.0, 2.0),
			second_corner: Screen.point(3.0, 4.0),
			third_corner: Screen.point(5.0, 6.0),
		},
	)
		== Poly({ pts: triangle_points, fill: Flat(Brush.opaque(111)) })

sample_rectangle : { top_left : Screen.Point, bottom_right : Screen.Point }
sample_rectangle = { top_left: Screen.point(1.0, 2.0), bottom_right: Screen.point(5.0, 8.0) }

expect Polygon.rectangle_corners(sample_rectangle) == [
	Screen.point(1.0, 2.0),
	Screen.point(5.0, 2.0),
	Screen.point(5.0, 8.0),
	Screen.point(1.0, 8.0),
]

expect Polygon.rectangle(111, sample_rectangle) == Poly({
	pts: [1.0, 2.0, 5.0, 2.0, 5.0, 8.0, 1.0, 8.0],
	fill: Flat(Brush.opaque(111)),
})

# A rectangle of no size still has its four corners.
expect
	Polygon.rectangle(
		111,
		{ top_left: Screen.point(1.0, 2.0), bottom_right: Screen.point(1.0, 2.0) },
	)
		== Poly({ pts: [1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0], fill: Flat(Brush.opaque(111)) })

# The smallest gradient a maker takes is exactly at the limit.
expect radial_polygon(three_corners, Polygon.min_gradient_radius) == Poly({
	pts: triangle_points,
	fill: Radial({
		inner: Brush.with_alpha(7),
		outer: Brush.with_alpha(8),
		x: 0.0,
		y: 0.0,
		r0: 0.0,
		r1: 0.5,
	}),
})

expect Polygon.flat_polygon(111, three_corners) == Poly({
	pts: triangle_points,
	fill: Flat(Brush.opaque(111)),
})

expect
	Polygon.shaded_polygon(three_corners, { fill_color: 222, strength: Fraction.of(0.75) })
		== Poly({
			pts: triangle_points,
			fill: Span({
				edge: Brush.opaque(155),
				middle: Brush.opaque(255),
				x0: 1.0,
				x1: 5.0,
			}),
		})

expect
	Polygon.gradient_polygon(
		three_corners,
		{
			center_rgba: 444,
			edge_rgba: 445,
			gradient_center: Screen.point(10.0, 20.0),
			gradient_radius: Pixels.of(30.0),
		},
	)
		== Poly({
			pts: triangle_points,
			fill: Radial({
				inner: Brush.with_alpha(444),
				outer: Brush.with_alpha(445),
				x: 10.0,
				y: 20.0,
				r0: 0.0,
				r1: 30.0,
			}),
		})

expect
	Polygon.linear_gradient_polygon(
		three_corners,
		{
			color_stops: {
				start_rgba: 555,
				end_rgba: 556,
				start_offset: 0.25,
				end_offset: 0.75,
			},
			start_point: Screen.point(1.0, 2.0),
			end_point: Screen.point(3.0, 4.0),
		},
	)
		== Poly({
			pts: triangle_points,
			fill: Linear({
				c0: Brush.with_alpha(555),
				c1: Brush.with_alpha(556),
				o0: 0.25,
				o1: 0.75,
				ax: 1.0,
				ay: 2.0,
				dx: 2.0,
				dy: 2.0,
			}),
		})

expect
	Polygon.radial_gradient_polygon(
		three_corners,
		{
			color_stops: inner_stops,
			center_point: Screen.point(1.0, 2.0),
			axis_u: Screen.point(3.0, 4.0),
			axis_v: Screen.point(5.0, 6.0),
		},
	)
		== Poly({
			pts: triangle_points,
			fill: Ellipse({
				c0: Brush.with_alpha(666),
				c1: Brush.with_alpha(667),
				o0: 0.25,
				o1: 0.75,
				x: 1.0,
				y: 2.0,
				ia: -3.0,
				ib: 2.5,
				ic: 2.0,
				id: -1.5,
			}),
		})

offset_linear : { start_offset : F64, end_offset : F64 } -> Shapes.Shape
offset_linear = |{ start_offset, end_offset }|
	Polygon.linear_gradient_polygon(
		three_corners,
		{
			color_stops: { ..inner_stops, start_offset, end_offset },
			start_point: Screen.point(1.0, 2.0),
			end_point: Screen.point(3.0, 4.0),
		},
	)

linear_fill : { o0 : F64, o1 : F64 } -> Shapes.Shape
linear_fill = |{ o0, o1 }|
	Poly({
		pts: triangle_points,
		fill: Linear({
			c0: Brush.with_alpha(666),
			c1: Brush.with_alpha(667),
			o0,
			o1,
			ax: 1.0,
			ay: 2.0,
			dx: 2.0,
			dy: 2.0,
		}),
	})

# An offset outside 0 to 1 is held there, and the last is never before the first.
expect offset_linear({ start_offset: -1.0, end_offset: 2.0 }) == linear_fill({ o0: 0.0, o1: 1.0 })
expect offset_linear({ start_offset: 0.0, end_offset: 1.0 }) == linear_fill({ o0: 0.0, o1: 1.0 })
expect offset_linear({
	start_offset: 0.75,
	end_offset: 0.25,
}) == linear_fill({ o0: 0.75, o1: 0.75 })

ellipse_of_height : F64 -> Shapes.Shape
ellipse_of_height = |height|
	Polygon.radial_gradient_polygon(
		three_corners,
		{
			color_stops: inner_stops,
			center_point: Screen.point(1.0, 2.0),
			axis_u: Screen.point(0.01, 0.0),
			axis_v: { x: Pixels.zero, y: Pixels.of(height) },
		},
	)

# An ellipse just under the limit is flat, and one just over it is not.
expect ellipse_of_height(0.009) == Poly({
	pts: triangle_points,
	fill: Flat(Brush.with_alpha(666)),
})
expect ellipse_of_height(0.011) != Poly({
	pts: triangle_points,
	fill: Flat(Brush.with_alpha(666)),
})

sample_color : I64
sample_color = 0x804020

expect width_shade_edge(sample_color, Fraction.whole) == 0x4D2613
expect width_shade_middle(sample_color, Fraction.whole) == 0xA05028
expect width_shade_edge(sample_color, Fraction.of(0.5)) == 0x66331A
expect width_shade_middle(sample_color, Fraction.of(0.5)) == 0x904824
expect width_shade_edge(sample_color, Fraction.zero) == sample_color
expect width_shade_middle(sample_color, Fraction.zero) == sample_color

# A lift past 255 holds at white.
expect width_shade_middle(0xFAFAFA, Fraction.whole) == 0xFFFFFF

expect is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(10.5) })
expect !is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(11.0) })
expect !is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) })

expect min_shade_width.to_f64() == 1.0
expect shade_edge_darken.to_f64() == 0.4
expect shade_middle_lift.to_f64() == 0.25

expect x_span(wide_corners) == { min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) }
expect x_span([Screen.point(5.0, 99.0)]) == { min_x: Pixels.of(5.0), max_x: Pixels.of(5.0) }

wide_corners : List(Screen.Point)
wide_corners = [
	Screen.point(10.0, 1.0),
	Screen.point(30.0, 2.0),
	Screen.point(20.0, 3.0),
]

narrow_corners : List(Screen.Point)
narrow_corners = [
	Screen.point(10.0, 1.0),
	Screen.point(10.5, 2.0),
	Screen.point(10.2, 3.0),
]

expect
	Polygon.shaded_polygon(wide_corners, { fill_color: sample_color, strength: Fraction.whole })
		== Poly({
			pts: [10.0, 1.0, 30.0, 2.0, 20.0, 3.0],
			fill: Span({
				edge: Brush.opaque(0x4D2613),
				middle: Brush.opaque(0xA05028),
				x0: 10.0,
				x1: 30.0,
			}),
		})

# No strength, or too narrow a polygon, is a solid fill.
expect
	Polygon.shaded_polygon(wide_corners, { fill_color: sample_color, strength: Fraction.zero })
		== Poly({
			pts: [10.0, 1.0, 30.0, 2.0, 20.0, 3.0],
			fill: Flat(Brush.opaque(sample_color)),
		})

expect
	Polygon.shaded_polygon(narrow_corners, { fill_color: sample_color, strength: Fraction.whole })
		== Poly({
			pts: [10.0, 1.0, 10.5, 2.0, 10.2, 3.0],
			fill: Flat(Brush.opaque(sample_color)),
		})
