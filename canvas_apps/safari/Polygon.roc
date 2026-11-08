## Polygon makes Safari's polygons as values, from screen points and colors.
## Nothing here paints: what a maker gives back is data for the page to paint. A
## color is an `RgbColor` for a flat or a shaded polygon, and an `ArgbColor` for
## a gradient. Each maker gives one shape. A polygon of fewer than
## three corners is a bug in the code that asked for it, so a maker crashes on one.
## A circular gradient can shrink out of sight as it goes away, so that maker
## answers a `Try`.
import Pixels
import Fraction
import ColorShade
import Screen
import lib.ArgbColor
import lib.Brush
import lib.RgbColor
import lib.Shapes

Polygon :: [].{

	## A gradient's two colors, and where each sits along it.
	ColorStops : {
		start_color : ArgbColor,
		end_color : ArgbColor,
		start_offset : Fraction,
		end_offset : Fraction,
	}

	## Makes a polygon of one flat color.
	flat_polygon : List(Screen.Point), RgbColor -> Shapes.Shape
	flat_polygon = |corners, color|
		Poly({
			coordinates: polygon_coordinates("Polygon.flat_polygon", corners),
			fill: Brush.flat(color),
		})

	## Makes a triangle of one flat color.
	triangle : {
		first_corner : Screen.Point,
		second_corner : Screen.Point,
		third_corner : Screen.Point,
	},
	RgbColor -> Shapes.Shape
	triangle = |{ first_corner, second_corner, third_corner }, color|
		flat_polygon([first_corner, second_corner, third_corner], color)

	## Makes a rectangle of one flat color. Its sides run along the screen's edges.
	rectangle : { top_left : Screen.Point, bottom_right : Screen.Point }, RgbColor -> Shapes.Shape
	rectangle = |opposite_corners, color| flat_polygon(rectangle_corners(opposite_corners), color)

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
	shaded_polygon : List(Screen.Point), { color : RgbColor, strength : Fraction } -> Shapes.Shape
	shaded_polygon = |corners, shade| {
		coordinates = polygon_coordinates("Polygon.shaded_polygon", corners)
		Poly({ coordinates, fill: width_shade(corners, shade) })
	}

	## Makes a polygon filled by a gradient that spreads in a circle from
	## `gradient_center`, or `TooSmall` when the radius is too small to see.
	circular_gradient_polygon : List(Screen.Point),
	{
		center_color : ArgbColor,
		edge_color : ArgbColor,
		gradient_center : Screen.Point,
		gradient_radius : Pixels,
	} -> Try(Shapes.Shape, [TooSmall])
	circular_gradient_polygon = |corners, gradient| {
		center = gradient.gradient_center
		if gradient.gradient_radius < min_gradient_radius {
			Err(TooSmall)
		} else {
			Ok(
				Poly({
					coordinates: polygon_coordinates("Polygon.circular_gradient_polygon", corners),
					fill: Radial({
						inner_color: Brush.translucent(gradient.center_color),
						outer_color: Brush.translucent(gradient.edge_color),
						center: { x: center.x.to_f64(), y: center.y.to_f64() },
						inner_radius: 0.0,
						outer_radius: gradient.gradient_radius.to_f64(),
					}),
				}),
			)
		}
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
			Poly({
				coordinates: polygon_coordinates("Polygon.linear_gradient_polygon", corners),
				fill: Linear({
					stops: brush_stops(color_stops),
					start_point: { x: start_point.x.to_f64(), y: start_point.y.to_f64() },
					end_point: { x: end_point.x.to_f64(), y: end_point.y.to_f64() },
				}),
			})
		}
	}

	## Makes a polygon filled by a gradient on an ellipse, which is `axis_u` and
	## `axis_v` about `center_point`. An ellipse too thin for Brush to invert
	## crashes: a still, the only caller, is never drawn small enough to thin
	## its ellipses past Brush's limit.
	elliptical_gradient_polygon : List(Screen.Point),
	{
		color_stops : Polygon.ColorStops,
		center_point : Screen.Point,
		axis_u : Screen.Point,
		axis_v : Screen.Point,
	} -> Shapes.Shape
	elliptical_gradient_polygon = |corners, { color_stops, center_point, axis_u, axis_v }| {
		ellipse = Brush.ellipse({
			stops: brush_stops(color_stops),
			center: { x: center_point.x.to_f64(), y: center_point.y.to_f64() },
			axis_u: { x: axis_u.x.to_f64(), y: axis_u.y.to_f64() },
			axis_v: { x: axis_v.x.to_f64(), y: axis_v.y.to_f64() },
		})
		fill =
			match ellipse {
				Ok(gradient) => gradient
				Err(TooThin) => crash "Polygon.elliptical_gradient_polygon: an ellipse too thin for Brush to invert"
			}
		Poly({ coordinates: polygon_coordinates("Polygon.elliptical_gradient_polygon", corners), fill })
	}
}

## The flat list of numbers that lib.Shapes takes for a polygon's corners.
flat_coordinates : List(Screen.Point) -> List(F64)
flat_coordinates = |corners| {
	var $flat = List.with_capacity(2 * corners.len())
	for corner in corners {
		$flat = $flat.append(corner.x.to_f64()).append(corner.y.to_f64())
	}
	$flat
}

## The numbers of a polygon's corners. Fewer than three corners enclose nothing,
## so that crashes, naming the `maker` that was asked.
polygon_coordinates : Str, List(Screen.Point) -> List(F64)
polygon_coordinates = |maker, corners|
	if corners.len() < 3 {
		crash "${maker}: a polygon needs three corners"
	} else {
		flat_coordinates(corners)
	}

## A radial gradient smaller than this is too small to see.
min_gradient_radius : Pixels
min_gradient_radius = Pixels.of(0.5)

## The span of x a polygon covers. Either end is negative for a polygon off the
## left of the screen.
Span : { min_x : Pixels, max_x : Pixels }

shade_edge_darken : Fraction
shade_edge_darken = Fraction.of(0.4)

shade_middle_lift : Fraction
shade_middle_lift = Fraction.of(0.25)

## A shaded polygon's color at its edges.
width_shade_edge : RgbColor, Fraction -> RgbColor
width_shade_edge = |color, strength|
	ColorShade.shade_color(color, shade_edge_darken.times(strength).less().to_f64())

## A shaded polygon's color in its middle.
width_shade_middle : RgbColor, Fraction -> RgbColor
width_shade_middle = |color, strength| ColorShade.shade_color(
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

## The stops as a brush takes them.
brush_stops : Polygon.ColorStops -> Brush.TwoStops
brush_stops = |stops| {
	start_color: Brush.translucent(stops.start_color),
	end_color: Brush.translucent(stops.end_color),
	start_offset: stops.start_offset.to_f64(),
	end_offset: stops.end_offset.to_f64(),
}

## The fill of a polygon shaded across its width.
width_shade : List(Screen.Point), { color : RgbColor, strength : Fraction } -> Brush.Fill
width_shade = |corners, { color, strength }| {
	span = x_span(corners)
	if strength <= Fraction.zero or is_too_narrow_to_shade(span) {
		Brush.flat(color)
	} else {
		Span({
			edge_color: Brush.opaque(width_shade_edge(color, strength)),
			middle_color: Brush.opaque(width_shade_middle(color, strength)),
			left_x: span.min_x.to_f64(),
			right_x: span.max_x.to_f64(),
		})
	}
}

three_corners : List(Screen.Point)
three_corners = [
	Screen.point(1.0, 2.0),
	Screen.point(3.0, 4.0),
	Screen.point(5.0, 6.0),
]

triangle_coordinates : List(F64)
triangle_coordinates = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

origin : Screen.Point
origin = Screen.point(0.0, 0.0)

plain_stops : Polygon.ColorStops
plain_stops = {
	start_color: ArgbColor.of(7),
	end_color: ArgbColor.of(8),
	start_offset: Fraction.zero,
	end_offset: Fraction.whole,
}

inner_stops : Polygon.ColorStops
inner_stops = {
	start_color: ArgbColor.of(666),
	end_color: ArgbColor.of(667),
	start_offset: Fraction.of(0.25),
	end_offset: Fraction.of(0.75),
}

radial_polygon : List(Screen.Point), Pixels -> Try(Shapes.Shape, [TooSmall])
radial_polygon = |corners, gradient_radius|
	Polygon.circular_gradient_polygon(
		corners,
		{
			center_color: ArgbColor.of(7),
			edge_color: ArgbColor.of(8),
			gradient_center: origin,
			gradient_radius,
		},
	)

expect flat_coordinates(three_corners) == triangle_coordinates
expect flat_coordinates([]) == []

# A triangle keeps its corners in the order given.
expect
	Polygon.triangle(
		{
			first_corner: Screen.point(1.0, 2.0),
			second_corner: Screen.point(3.0, 4.0),
			third_corner: Screen.point(5.0, 6.0),
		},
		RgbColor.of(111),
	)
		== Poly({ coordinates: triangle_coordinates, fill: Flat(Brush.opaque(RgbColor.of(111))) })

sample_rectangle : { top_left : Screen.Point, bottom_right : Screen.Point }
sample_rectangle = { top_left: Screen.point(1.0, 2.0), bottom_right: Screen.point(5.0, 8.0) }

expect Polygon.rectangle_corners(sample_rectangle) == [
	Screen.point(1.0, 2.0),
	Screen.point(5.0, 2.0),
	Screen.point(5.0, 8.0),
	Screen.point(1.0, 8.0),
]

expect Polygon.rectangle(sample_rectangle, RgbColor.of(111)) == Poly({
	coordinates: [1.0, 2.0, 5.0, 2.0, 5.0, 8.0, 1.0, 8.0],
	fill: Flat(Brush.opaque(RgbColor.of(111))),
})

# A rectangle of no size still has its four corners.
expect
	Polygon.rectangle(
		{ top_left: Screen.point(1.0, 2.0), bottom_right: Screen.point(1.0, 2.0) },
		RgbColor.of(111),
	)
		== Poly({
			coordinates: [1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0],
			fill: Flat(Brush.opaque(RgbColor.of(111))),
		})

# A gradient is too small just under the limit, and not at it.
expect radial_polygon(three_corners, Pixels.of(0.49)) == Err(TooSmall)
expect radial_polygon(three_corners, Pixels.of(0.5)) == Ok(
	Poly({
		coordinates: triangle_coordinates,
		fill: Radial({
			inner_color: Brush.translucent(ArgbColor.of(7)),
			outer_color: Brush.translucent(ArgbColor.of(8)),
			center: { x: 0.0, y: 0.0 },
			inner_radius: 0.0,
			outer_radius: 0.5,
		}),
	}),
)

expect Polygon.flat_polygon(three_corners, RgbColor.of(111)) == Poly({
	coordinates: triangle_coordinates,
	fill: Flat(Brush.opaque(RgbColor.of(111))),
})

expect
	Polygon.shaded_polygon(three_corners, { color: RgbColor.of(222), strength: Fraction.of(0.75) })
		== Poly({
			coordinates: triangle_coordinates,
			fill: Span({
				edge_color: Brush.opaque(RgbColor.of(155)),
				middle_color: Brush.opaque(RgbColor.of(255)),
				left_x: 1.0,
				right_x: 5.0,
			}),
		})

expect
	Polygon.circular_gradient_polygon(
		three_corners,
		{
			center_color: ArgbColor.of(444),
			edge_color: ArgbColor.of(445),
			gradient_center: Screen.point(10.0, 20.0),
			gradient_radius: Pixels.of(30.0),
		},
	)
		== Ok(
			Poly({
				coordinates: triangle_coordinates,
				fill: Radial({
					inner_color: Brush.translucent(ArgbColor.of(444)),
					outer_color: Brush.translucent(ArgbColor.of(445)),
					center: { x: 10.0, y: 20.0 },
					inner_radius: 0.0,
					outer_radius: 30.0,
				}),
			}),
		)

expect
	Polygon.linear_gradient_polygon(
		three_corners,
		{
			color_stops: {
				start_color: ArgbColor.of(555),
				end_color: ArgbColor.of(556),
				start_offset: Fraction.of(0.25),
				end_offset: Fraction.of(0.75),
			},
			start_point: Screen.point(1.0, 2.0),
			end_point: Screen.point(3.0, 4.0),
		},
	)
		== Poly({
			coordinates: triangle_coordinates,
			fill: Linear({
				stops: {
					start_color: Brush.translucent(ArgbColor.of(555)),
					end_color: Brush.translucent(ArgbColor.of(556)),
					start_offset: 0.25,
					end_offset: 0.75,
				},
				start_point: { x: 1.0, y: 2.0 },
				end_point: { x: 3.0, y: 4.0 },
			}),
		})

expect
	Polygon.elliptical_gradient_polygon(
		three_corners,
		{
			color_stops: inner_stops,
			center_point: Screen.point(1.0, 2.0),
			axis_u: Screen.point(3.0, 4.0),
			axis_v: Screen.point(5.0, 6.0),
		},
	)
		== Poly({
			coordinates: triangle_coordinates,
			fill: Ellipse({
				stops: {
					start_color: Brush.translucent(ArgbColor.of(666)),
					end_color: Brush.translucent(ArgbColor.of(667)),
					start_offset: 0.25,
					end_offset: 0.75,
				},
				center: { x: 1.0, y: 2.0 },
				axis_u: { x: 3.0, y: 4.0 },
				axis_v: { x: 5.0, y: 6.0 },
			}),
		})

sample_color : RgbColor
sample_color = RgbColor.of(0x804020)

expect width_shade_edge(sample_color, Fraction.whole) == RgbColor.of(0x4D2613)
expect width_shade_middle(sample_color, Fraction.whole) == RgbColor.of(0xA05028)
expect width_shade_edge(sample_color, Fraction.of(0.5)) == RgbColor.of(0x66331A)
expect width_shade_middle(sample_color, Fraction.of(0.5)) == RgbColor.of(0x904824)
expect width_shade_edge(sample_color, Fraction.zero) == sample_color
expect width_shade_middle(sample_color, Fraction.zero) == sample_color

# A lift past 255 holds at white.
expect width_shade_middle(RgbColor.of(0xFAFAFA), Fraction.whole) == RgbColor.of(0xFFFFFF)

expect is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(10.5) })
expect !is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(11.0) })
expect !is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) })

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
	Polygon.shaded_polygon(wide_corners, { color: sample_color, strength: Fraction.whole })
		== Poly({
			coordinates: [10.0, 1.0, 30.0, 2.0, 20.0, 3.0],
			fill: Span({
				edge_color: Brush.opaque(RgbColor.of(0x4D2613)),
				middle_color: Brush.opaque(RgbColor.of(0xA05028)),
				left_x: 10.0,
				right_x: 30.0,
			}),
		})

# No strength, or too narrow a polygon, is a solid fill.
expect
	Polygon.shaded_polygon(wide_corners, { color: sample_color, strength: Fraction.zero })
		== Poly({
			coordinates: [
				10.0,
				1.0,
				30.0,
				2.0,
				20.0,
				3.0,
			],
			fill: Flat(Brush.opaque(sample_color)),
		})

expect
	Polygon.shaded_polygon(narrow_corners, { color: sample_color, strength: Fraction.whole })
		== Poly({
			coordinates: [
				10.0,
				1.0,
				10.5,
				2.0,
				10.2,
				3.0,
			],
			fill: Flat(Brush.opaque(sample_color)),
		})
