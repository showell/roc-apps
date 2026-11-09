## Polygon makes Safari's polygons as values, from screen points and colors.
## What a maker gives back is data for the page to paint. A color is an
## `RgbColor` for a flat or a shaded polygon, and an `ArgbColor` for a gradient.
## A polygon of fewer than three corners is a bug in the code that asked for it,
## so a maker crashes on one.
## A circular gradient can shrink out of sight as it goes away, so that maker
## answers a `Try`. It also cuts a polygon in the rider's view at the near plane
## and puts it on the screen.
import Camera
import RiderView
import Pixels
import Fraction
import ColorShade
import Screen
import lib.ArgbColor
import lib.Brush
import lib.Point
import lib.RgbColor
import lib.Shapes

Polygon :: [].{

	## Makes a polygon of one flat color.
	flat_polygon : List(Screen.Point), RgbColor -> Shapes.Shape
	flat_polygon = |corners, color|
		Polygon({ corners: polygon_corners(corners), fill: Brush.flat(color) })

	## Makes a triangle of one flat color.
	triangle : {
		first_corner : Screen.Point,
		second_corner : Screen.Point,
		third_corner : Screen.Point,
	},
	RgbColor -> Shapes.Shape
	triangle = |{ first_corner, second_corner, third_corner }, color|
		Triangle({
			first: frame_point(first_corner),
			second: frame_point(second_corner),
			third: frame_point(third_corner),
			fill: Brush.flat(color),
		})

	## Makes a polygon shaded across its width, darker at its edges and lighter in
	## its middle, or a solid one where it has no strength or is too narrow.
	shaded_polygon : List(Screen.Point), { color : RgbColor, strength : Fraction } -> Shapes.Shape
	shaded_polygon = |corners, shade| {
		Polygon({
			corners: polygon_corners(corners),
			fill: Polygon.width_shade(x_span(corners), shade),
		})
	}

	## The span of x a shape covers. Either end is negative for a shape off the
	## left of the screen.
	Span : { min_x : Pixels, max_x : Pixels }

	## The fill of a shape spanning `span`, shaded across its width as
	## `shaded_polygon` shades a polygon. A rectangle takes it too, so that the
	## two shade alike.
	width_shade : Polygon.Span, { color : RgbColor, strength : Fraction } -> Brush.Fill
	width_shade = |span, { color, strength }|
		if strength <= Fraction.zero or is_too_narrow_to_shade(span) {
			Brush.flat(color)
		} else {
			Span({
				edge_color: Brush.opaque_rgba(width_shade_edge(color, strength)),
				middle_color: Brush.opaque_rgba(width_shade_middle(color, strength)),
				left_x: span.min_x.to_f64(),
				right_x: span.max_x.to_f64(),
			})
		}

	## Makes a polygon filled by a gradient that spreads in a circle from
	## `gradient_center`, or `TooSmall` when the radius is too small to see.
	circular_gradient_polygon : List(Screen.Point),
	Polygon.CircularGradient -> Try(
		Shapes.Shape,
		[TooSmall],
	)
	circular_gradient_polygon = |corners, gradient| {
		fill = Polygon.circular_gradient_fill(gradient)?
		Ok(Polygon({ corners: polygon_corners(corners), fill }))
	}

	## A gradient that spreads in a circle from `gradient_center`, from
	## `center_color` there to `edge_color` at `gradient_radius`.
	CircularGradient : {
		center_color : ArgbColor,
		edge_color : ArgbColor,
		gradient_center : Screen.Point,
		gradient_radius : Pixels,
	}

	## The fill of a circular gradient, or `TooSmall` when its radius is too
	## small to see. A disc takes it as well as a polygon.
	circular_gradient_fill : Polygon.CircularGradient -> Try(Brush.Fill, [TooSmall])
	circular_gradient_fill = |gradient| {
		center = gradient.gradient_center
		if gradient.gradient_radius < smallest_gradient_radius {
			Err(TooSmall)
		} else {
			Ok(
				Radial({
					inner_color: Brush.translucent(gradient.center_color),
					outer_color: Brush.translucent(gradient.edge_color),
					center: { x: center.x.to_f64(), y: center.y.to_f64() },
					inner_radius: 0.0,
					outer_radius: gradient.gradient_radius.to_f64(),
				}),
			)
		}
	}

	## Makes a polygon filled by a gradient along a line. A gradient with no length
	## has no direction, so that crashes.
	linear_gradient_polygon : List(Screen.Point),
	{
		stops : Brush.TwoStops,
		start_point : Screen.Point,
		end_point : Screen.Point,
	} -> Shapes.Shape
	linear_gradient_polygon = |corners, { stops, start_point, end_point }| {
		dx = end_point.x.minus(start_point.x).to_f64()
		dy = end_point.y.minus(start_point.y).to_f64()
		if dx * dx + dy * dy == 0.0 {
			crash "Polygon.linear_gradient_polygon: a gradient has a length"
		} else {
			Polygon({
				corners: polygon_corners(corners),
				fill: Linear({
					stops,
					start_point: { x: start_point.x.to_f64(), y: start_point.y.to_f64() },
					end_point: { x: end_point.x.to_f64(), y: end_point.y.to_f64() },
				}),
			})
		}
	}

	## Makes a polygon filled by a gradient on an ellipse, which is `axis_u` and
	## `axis_v` about `center_point`. An ellipse too thin for Brush to invert
	## crashes: a still, the only caller, is never drawn small enough to thin
	## its ellipses past Brush's limit, as `Still.of` checks.
	elliptical_gradient_polygon : List(Screen.Point),
	{
		stops : Brush.TwoStops,
		center_point : Screen.Point,
		axis_u : Screen.Point,
		axis_v : Screen.Point,
	} -> Shapes.Shape
	elliptical_gradient_polygon = |corners, { stops, center_point, axis_u, axis_v }| {
		ellipse = Brush.ellipse({
			stops,
			center: { x: center_point.x.to_f64(), y: center_point.y.to_f64() },
			axis_u: { x: axis_u.x.to_f64(), y: axis_u.y.to_f64() },
			axis_v: { x: axis_v.x.to_f64(), y: axis_v.y.to_f64() },
		})
		fill =
			match ellipse {
				Ok(gradient) => gradient
				Err(TooThin) => crash "Polygon.elliptical_gradient_polygon: an ellipse too thin for Brush to invert"
			}
		Polygon({ corners: polygon_corners(corners), fill })
	}

	## A polygon of one color, in the rider's view.
	FlatPolygon : { color : RgbColor, corners : List(RiderView.RaisedPoint) }

	## A polygon on screen, cut at the near plane, unless it's wholly behind the
	## camera.
	clipped_polygon : Polygon.FlatPolygon, Pixels -> Try(Shapes.Shape, [BehindCamera])
	clipped_polygon = |{ color, corners }, focal_length| {
		in_front = RiderView.clipped_points(corners)
		if in_front.is_empty() {
			Err(BehindCamera)
		} else {
			Ok(Polygon.flat_polygon(Camera.projected_points(in_front, focal_length), color))
		}
	}
}

## A polygon's corners as the painter reads them. Fewer than three corners
## enclose nothing, so asking for that is a bug, and it crashes.
polygon_corners : List(Screen.Point) -> List(Point.Point)
polygon_corners = |corners|
	if corners.len() < 3 {
		crash "Polygon: a polygon needs at least three corners"
	} else {
		corners.map(frame_point)
	}

## A screen point as a frame's point.
frame_point : Screen.Point -> Point.Point
frame_point = |{ x, y }| { x: x.to_f64(), y: y.to_f64() }

## A radial gradient smaller than this is too small to see.
smallest_gradient_radius : Pixels
smallest_gradient_radius = Pixels.of(0.5)

shade_edge_darken : Fraction
shade_edge_darken = Fraction.of(0.4)

shade_middle_lift : Fraction
shade_middle_lift = Fraction.of(0.25)

## A shaded polygon's color at its edges.
width_shade_edge : RgbColor, Fraction -> RgbColor
width_shade_edge = |color, strength|
	ColorShade.shade_color(color, Darkened(shade_edge_darken.times(strength)))

## A shaded polygon's color in its middle.
width_shade_middle : RgbColor, Fraction -> RgbColor
width_shade_middle = |color, strength|
	ColorShade.shade_color(color, Lightened(shade_middle_lift.times(strength)))

narrowest_shaded_width : Pixels
narrowest_shaded_width = Pixels.of(1.0)

is_too_narrow_to_shade : Polygon.Span -> Bool
is_too_narrow_to_shade = |span| span.max_x.minus(span.min_x) < narrowest_shaded_width

## The span of x over a polygon's corners. It has at least one corner.
x_span : List(Screen.Point) -> Polygon.Span
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

three_corners : List(Screen.Point)
three_corners = [
	Screen.point(1.0, 2.0),
	Screen.point(3.0, 4.0),
	Screen.point(5.0, 6.0),
]

triangle_corners : List(Point.Point)
triangle_corners = [{ x: 1.0, y: 2.0 }, { x: 3.0, y: 4.0 }, { x: 5.0, y: 6.0 }]

origin : Screen.Point
origin = Screen.point(0.0, 0.0)

inner_stops : Brush.TwoStops
inner_stops = {
	start_color: Brush.translucent(ArgbColor.of(666)),
	end_color: Brush.translucent(ArgbColor.of(667)),
	start_offset: 0.25,
	end_offset: 0.75,
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

expect polygon_corners(three_corners) == triangle_corners

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
		== Triangle({
			first: { x: 1.0, y: 2.0 },
			second: { x: 3.0, y: 4.0 },
			third: { x: 5.0, y: 6.0 },
			fill: Flat(Brush.opaque_rgba(RgbColor.of(111))),
		})

# A gradient is too small just under the limit, and not at it.
expect radial_polygon(three_corners, Pixels.of(0.49)) == Err(TooSmall)
expect radial_polygon(three_corners, Pixels.of(0.5)) == Ok(
	Polygon({
		corners: triangle_corners,
		fill: Radial({
			inner_color: Brush.translucent(ArgbColor.of(7)),
			outer_color: Brush.translucent(ArgbColor.of(8)),
			center: { x: 0.0, y: 0.0 },
			inner_radius: 0.0,
			outer_radius: 0.5,
		}),
	}),
)

expect Polygon.flat_polygon(three_corners, RgbColor.of(111)) == Polygon({
	corners: triangle_corners,
	fill: Flat(Brush.opaque_rgba(RgbColor.of(111))),
})

expect
	Polygon.shaded_polygon(three_corners, { color: RgbColor.of(222), strength: Fraction.of(0.75) })
		== Polygon({
			corners: triangle_corners,
			fill: Span({
				edge_color: Brush.opaque_rgba(RgbColor.of(155)),
				middle_color: Brush.opaque_rgba(RgbColor.of(255)),
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
			Polygon({
				corners: triangle_corners,
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
			stops: {
				start_color: Brush.translucent(ArgbColor.of(555)),
				end_color: Brush.translucent(ArgbColor.of(556)),
				start_offset: 0.25,
				end_offset: 0.75,
			},
			start_point: Screen.point(1.0, 2.0),
			end_point: Screen.point(3.0, 4.0),
		},
	)
		== Polygon({
			corners: triangle_corners,
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
			stops: inner_stops,
			center_point: Screen.point(1.0, 2.0),
			axis_u: Screen.point(3.0, 4.0),
			axis_v: Screen.point(5.0, 6.0),
		},
	)
		== Polygon({
			corners: triangle_corners,
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
		== Polygon({
			corners: [{ x: 10.0, y: 1.0 }, { x: 30.0, y: 2.0 }, { x: 20.0, y: 3.0 }],
			fill: Span({
				edge_color: Brush.opaque_rgba(RgbColor.of(0x4D2613)),
				middle_color: Brush.opaque_rgba(RgbColor.of(0xA05028)),
				left_x: 10.0,
				right_x: 30.0,
			}),
		})

# No strength, or too narrow a polygon, is a solid fill.
expect
	Polygon.shaded_polygon(wide_corners, { color: sample_color, strength: Fraction.zero })
		== Polygon({
			corners: [{ x: 10.0, y: 1.0 }, { x: 30.0, y: 2.0 }, { x: 20.0, y: 3.0 }],
			fill: Flat(Brush.opaque_rgba(sample_color)),
		})

expect
	Polygon.shaded_polygon(narrow_corners, { color: sample_color, strength: Fraction.whole })
		== Polygon({
			corners: [{ x: 10.0, y: 1.0 }, { x: 10.5, y: 2.0 }, { x: 10.2, y: 3.0 }],
			fill: Flat(Brush.opaque_rgba(sample_color)),
		})
