## Paint turns Safari's screen points and whole-number colours into shapes. A
## colour is 0xRRGGBB for a flat polygon, a shaded polygon and a beacon, and
## 0xAARRGGBB for a gradient. Each builder answers a list, empty when there is
## nothing to draw, so a drawing module can join what it builds.
import Pixels
import Fraction
import Float
import Screen
import lib.Brush
import lib.Shapes

Paint :: [].{

	## The span of x a polygon covers. Either end is negative for a polygon off
	## the left of the screen.
	Span : { min_x : Pixels, max_x : Pixels }

	red_of : I64 -> I64
	red_of = |color| color.shr_wrap(I64.to_u8_wrap(16)).bitwise_and(255)

	green_of : I64 -> I64
	green_of = |color| color.shr_wrap(I64.to_u8_wrap(8)).bitwise_and(255)

	blue_of : I64 -> I64
	blue_of = |color| color.bitwise_and(255)

	## A colour as 0xRRGGBB from its three channels.
	pack_rgb : {
		red : I64,
		green : I64,
		blue : I64,
	} -> I64
	pack_rgb = |{ red, green, blue }| {
		red_bits = red.shl_wrap(16)
		green_bits = green.shl_wrap(8)
		red_bits.bitwise_or(green_bits).bitwise_or(blue)
	}

	## One channel scaled by `factor`, rounded, and held at 255 at most.
	shade_channel : I64, F64 -> I64
	shade_channel = |channel, factor| {
		scaled = Float.round(channel.to_f64() * factor).to_i64_wrap()
		if scaled > 255 {
			255
		} else {
			scaled
		}
	}

	shade_color : I64, F64 -> I64
	shade_color = |color, factor|
		pack_rgb({
			red: shade_channel(red_of(color), factor),
			green: shade_channel(green_of(color), factor),
			blue: shade_channel(blue_of(color), factor),
		})

	shade_edge_darken : Fraction
	shade_edge_darken = Fraction.of(0.4)

	shade_middle_lift : Fraction
	shade_middle_lift = Fraction.of(0.25)

	## A shaded polygon's colour at its edges.
	width_shade_edge : I64, Fraction -> I64
	width_shade_edge = |color, strength|
		shade_color(color, 1.0 - shade_edge_darken.to_f64() * strength.to_f64())

	## A shaded polygon's colour in its middle.
	width_shade_middle : I64, Fraction -> I64
	width_shade_middle = |color, strength| shade_color(
		color,
		1.0 + shade_middle_lift.to_f64() * strength.to_f64(),
	)

	min_shade_width : Pixels
	min_shade_width = Pixels.of(1.0)

	is_too_narrow_to_shade : Paint.Span -> Bool
	is_too_narrow_to_shade = |span| span.max_x.minus(span.min_x) < min_shade_width

	## The span of x over a polygon's points. It has at least one point.
	x_span : List(Screen.Point) -> Paint.Span
	x_span = |ps|
		match ps.map(|p| p.x) {
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
			[] => crash "Paint.x_span: a polygon has a point"
		}

	flatten_screen : List(Screen.Point) -> List(F64)
	flatten_screen = |ps| {
		var $flat = List.with_capacity(2 * ps.len())
		for p in ps {
			$flat = $flat.append(p.x.to_f64()).append(p.y.to_f64())
		}
		$flat
	}

	polygon : I64, List(Screen.Point) -> List(Shapes.Shape)
	polygon = |color, ps| Shapes.polygon(flatten_screen(ps), Flat(Brush.opaque(color)))

	## A polygon shaded across its width, darker at its edges and lighter in
	## its middle, or a solid one where it has no strength or is too narrow.
	round_polygon : List(Screen.Point),
	{
		fill_color : I64,
		round_strength : Fraction,
	} -> List(Shapes.Shape)
	round_polygon = |ps, { fill_color, round_strength }|
		if ps.len() < 3 {
			[]
		} else {
			pts = flatten_screen(ps)
			[Poly({ pts, fill: width_shade(ps, { color: fill_color, strength: round_strength }) })]
		}

	beacon : {
		beacon_color : I64,
		beacon_center : Screen.Point,
		beacon_radius : Pixels,
		beacon_alpha : Fraction,
	} -> List(Shapes.Shape)
	beacon = |{ beacon_color, beacon_center, beacon_radius, beacon_alpha }| {
		opaque = Brush.opaque(beacon_color)
		[
			Disc({
				x: beacon_center.x.to_f64(),
				y: beacon_center.y.to_f64(),
				r: beacon_radius.to_f64(),
				fill: Flat({ ..opaque, a: beacon_alpha.to_f64() }),
				clip: Anywhere,
			}),
		]
	}

	## A gradient's two colours, and where each sits along it.
	ColorStops : {
		start_rgba : I64,
		end_rgba : I64,
		start_offset : F64,
		end_offset : F64,
	}

	## A radial gradient smaller than this is not drawn.
	min_gradient_radius : Pixels
	min_gradient_radius = Pixels.of(0.5)

	gradient_polygon : List(Screen.Point),
	{
		center_rgba : I64,
		edge_rgba : I64,
		gradient_center : Screen.Point,
		gradient_radius : Pixels,
	} -> List(Shapes.Shape)
	gradient_polygon = |ps, { center_rgba, edge_rgba, gradient_center, gradient_radius }|
		if gradient_radius < min_gradient_radius {
			[]
		} else {
			Shapes.polygon(
				flatten_screen(ps),
				Radial({
					inner: Brush.with_alpha(center_rgba),
					outer: Brush.with_alpha(edge_rgba),
					x: gradient_center.x.to_f64(),
					y: gradient_center.y.to_f64(),
					r0: 0.0,
					r1: gradient_radius.to_f64(),
				}),
			)
		}

	## A linear gradient with no length has no direction, so it is not drawn.
	linear_gradient_polygon : List(Screen.Point),
	{
		color_stops : Paint.ColorStops,
		start_point : Screen.Point,
		end_point : Screen.Point,
	} -> List(Shapes.Shape)
	linear_gradient_polygon = |ps, { color_stops, start_point, end_point }| {
		dx = end_point.x.minus(start_point.x).to_f64()
		dy = end_point.y.minus(start_point.y).to_f64()
		if dx * dx + dy * dy == 0.0 {
			[]
		} else {
			offsets = offsets_of(color_stops)
			Shapes.polygon(
				flatten_screen(ps),
				Linear({
					c0: Brush.with_alpha(color_stops.start_rgba),
					c1: Brush.with_alpha(color_stops.end_rgba),
					o0: offsets.first,
					o1: offsets.last,
					ax: start_point.x.to_f64(),
					ay: start_point.y.to_f64(),
					dx,
					dy,
				}),
			)
		}
	}

	## A gradient on an ellipse, which is `axis_u` and `axis_v` about
	## `center_point`. An ellipse too thin to invert is filled with its first
	## colour.
	radial_gradient_polygon : List(Screen.Point),
	{
		color_stops : Paint.ColorStops,
		center_point : Screen.Point,
		axis_u : Screen.Point,
		axis_v : Screen.Point,
	} -> List(Shapes.Shape)
	radial_gradient_polygon = |ps, { color_stops, center_point, axis_u, axis_v }| {
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
		Shapes.polygon(flatten_screen(ps), fill)
	}
}

min_ellipse_determinant : F64
min_ellipse_determinant = 0.0001

## A gradient's offsets held to 0 to 1, the last never before the first.
offsets_of : Paint.ColorStops -> { first : F64, last : F64 }
offsets_of = |stops| {
	first = Brush.clamp01(stops.start_offset)
	{ first, last: first.max(F64.min(1.0, stops.end_offset)) }
}

## The fill of a polygon shaded across its width.
width_shade : List(Screen.Point), { color : I64, strength : Fraction } -> Brush.Fill
width_shade = |ps, { color, strength }| {
	span = Paint.x_span(ps)
	if strength <= Fraction.zero or Paint.is_too_narrow_to_shade(span) {
		Flat(Brush.opaque(color))
	} else {
		Span({
			edge: Brush.opaque(Paint.width_shade_edge(color, strength)),
			middle: Brush.opaque(Paint.width_shade_middle(color, strength)),
			x0: span.min_x.to_f64(),
			x1: span.max_x.to_f64(),
		})
	}
}

triangle : List(Screen.Point)
triangle = [
	Screen.point(1.0, 2.0),
	Screen.point(3.0, 4.0),
	Screen.point(5.0, 6.0),
]

triangle_points : List(F64)
triangle_points = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

line_ends : List(Screen.Point)
line_ends = [Screen.point(1.0, 2.0), Screen.point(3.0, 4.0)]

origin : Screen.Point
origin = Screen.point(0.0, 0.0)

plain_stops : Paint.ColorStops
plain_stops = {
	start_rgba: 7,
	end_rgba: 8,
	start_offset: 0.0,
	end_offset: 1.0,
}

inner_stops : Paint.ColorStops
inner_stops = {
	start_rgba: 666,
	end_rgba: 667,
	start_offset: 0.25,
	end_offset: 0.75,
}

radial_polygon : List(Screen.Point), Pixels -> List(Shapes.Shape)
radial_polygon = |corners, gradient_radius|
	Paint.gradient_polygon(
		corners,
		{
			center_rgba: 7,
			edge_rgba: 8,
			gradient_center: origin,
			gradient_radius,
		},
	)

linear_polygon : List(Screen.Point) -> List(Shapes.Shape)
linear_polygon = |corners|
	Paint.linear_gradient_polygon(
		corners,
		{
			color_stops: plain_stops,
			start_point: origin,
			end_point: Screen.point(1.0, 1.0),
		},
	)

ellipse_polygon : List(Screen.Point) -> List(Shapes.Shape)
ellipse_polygon = |corners|
	Paint.radial_gradient_polygon(
		corners,
		{
			color_stops: plain_stops,
			center_point: origin,
			axis_u: Screen.point(1.0, 0.0),
			axis_v: Screen.point(0.0, 1.0),
		},
	)

expect Paint.flatten_screen(triangle) == triangle_points
expect Paint.flatten_screen([]) == []

# A builder given too few points, or too small a gradient, draws nothing.
expect Paint.polygon(7, triangle).len() == 1
expect Paint.polygon(7, line_ends).len() == 0
expect Paint.polygon(7, []).len() == 0
expect Paint.round_polygon(triangle, { fill_color: 7, round_strength: Fraction.of(0.5) }).len() == 1
expect Paint.round_polygon(
	line_ends,
	{ fill_color: 7, round_strength: Fraction.of(0.5) },
).len() == 0
expect radial_polygon(triangle, Pixels.of(1.0)).len() == 1
expect radial_polygon(line_ends, Pixels.of(1.0)).len() == 0
expect radial_polygon(triangle, Pixels.of(0.5)).len() == 1
expect radial_polygon(triangle, Pixels.of(0.49)).len() == 0
expect linear_polygon(triangle).len() == 1
expect linear_polygon(line_ends).len() == 0
expect ellipse_polygon(triangle).len() == 1
expect ellipse_polygon(line_ends).len() == 0

expect
	Paint.beacon({
		beacon_color: 7,
		beacon_center: Screen.point(1.0, 2.0),
		beacon_radius: Pixels.of(3.0),
		beacon_alpha: Fraction.of(0.5),
	}).len()
		== 1

expect Paint.polygon(111, triangle) == [
	Poly({ pts: triangle_points, fill: Flat(Brush.opaque(111)) }),
]

expect
	Paint.round_polygon(triangle, { fill_color: 222, round_strength: Fraction.of(0.75) })
		== [
			Poly({
				pts: triangle_points,
				fill: Span({
					edge: Brush.opaque(155),
					middle: Brush.opaque(255),
					x0: 1.0,
					x1: 5.0,
				}),
			}),
		]

expect
	Paint.beacon({
		beacon_color: 333,
		beacon_center: Screen.point(10.0, 20.0),
		beacon_radius: Pixels.of(30.0),
		beacon_alpha: Fraction.of(0.25),
	})
		== [
			Disc({
				x: 10.0,
				y: 20.0,
				r: 30.0,
				fill: Flat({ ..Brush.opaque(333), a: 0.25 }),
				clip: Anywhere,
			}),
		]

expect
	Paint.gradient_polygon(
		triangle,
		{
			center_rgba: 444,
			edge_rgba: 445,
			gradient_center: Screen.point(10.0, 20.0),
			gradient_radius: Pixels.of(30.0),
		},
	)
		== [
			Poly({
				pts: triangle_points,
				fill: Radial({
					inner: Brush.with_alpha(444),
					outer: Brush.with_alpha(445),
					x: 10.0,
					y: 20.0,
					r0: 0.0,
					r1: 30.0,
				}),
			}),
		]

expect
	Paint.linear_gradient_polygon(
		triangle,
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
		== [
			Poly({
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
			}),
		]

expect
	Paint.radial_gradient_polygon(
		triangle,
		{
			color_stops: inner_stops,
			center_point: Screen.point(1.0, 2.0),
			axis_u: Screen.point(3.0, 4.0),
			axis_v: Screen.point(5.0, 6.0),
		},
	)
		== [
			Poly({
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
			}),
		]

offset_linear : { start_offset : F64, end_offset : F64 } -> List(Shapes.Shape)
offset_linear = |{ start_offset, end_offset }|
	Paint.linear_gradient_polygon(
		triangle,
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
expect offset_linear({ start_offset: -1.0, end_offset: 2.0 }) == [linear_fill({ o0: 0.0, o1: 1.0 })]
expect offset_linear({ start_offset: 0.0, end_offset: 1.0 }) == [linear_fill({ o0: 0.0, o1: 1.0 })]
expect offset_linear({
	start_offset: 0.75,
	end_offset: 0.25,
}) == [linear_fill({ o0: 0.75, o1: 0.75 })]

linear_to : Screen.Point -> List(Shapes.Shape)
linear_to = |end_point|
	Paint.linear_gradient_polygon(
		triangle,
		{
			color_stops: inner_stops,
			start_point: Screen.point(1.0, 2.0),
			end_point,
		},
	)

# A linear gradient of no length is dropped, however short one with a length is.
expect linear_to(Screen.point(1.0, 2.0)).len() == 0
expect linear_to(Screen.point(1.0, 2.5)).len() == 1

ellipse_of_height : F64 -> List(Shapes.Shape)
ellipse_of_height = |height|
	Paint.radial_gradient_polygon(
		triangle,
		{
			color_stops: inner_stops,
			center_point: Screen.point(1.0, 2.0),
			axis_u: Screen.point(0.01, 0.0),
			axis_v: { x: Pixels.zero, y: Pixels.of(height) },
		},
	)

# An ellipse just under the limit is flat, and one just over it is not.
expect ellipse_of_height(0.009) == [
	Poly({ pts: triangle_points, fill: Flat(Brush.with_alpha(666)) }),
]
expect ellipse_of_height(0.011) != [
	Poly({ pts: triangle_points, fill: Flat(Brush.with_alpha(666)) }),
]

sample_color : I64
sample_color = 0x804020

expect Paint.red_of(sample_color) == 128
expect Paint.green_of(sample_color) == 64
expect Paint.blue_of(sample_color) == 32
expect Paint.pack_rgb({
	red: 128,
	green: 64,
	blue: 32,
}) == sample_color
expect Paint.red_of(0xFFFFFF) == 255
expect Paint.green_of(0xFFFFFF) == 255
expect Paint.blue_of(0xFFFFFF) == 255
expect Paint.red_of(0) == 0
expect Paint.pack_rgb({
	red: 0,
	green: 0,
	blue: 0,
}) == 0
expect Paint.pack_rgb({
	red: 255,
	green: 255,
	blue: 255,
}) == 0xFFFFFF

expect Paint.shade_channel(128, 0.6) == 77
expect Paint.shade_channel(64, 0.6) == 38
expect Paint.shade_channel(32, 0.6) == 19
expect Paint.shade_channel(250, 1.25) == 255
expect Paint.shade_channel(255, 1.0) == 255
expect Paint.shade_channel(255, 2.0) == 255
expect Paint.shade_channel(0, 1.25) == 0
expect Paint.shade_color(sample_color, 0.6) == 0x4D2613

expect Paint.width_shade_edge(sample_color, Fraction.whole) == 0x4D2613
expect Paint.width_shade_middle(sample_color, Fraction.whole) == 0xA05028
expect Paint.width_shade_edge(sample_color, Fraction.of(0.5)) == 0x66331A
expect Paint.width_shade_middle(sample_color, Fraction.of(0.5)) == 0x904824
expect Paint.width_shade_edge(sample_color, Fraction.zero) == sample_color
expect Paint.width_shade_middle(sample_color, Fraction.zero) == sample_color

# A lift past 255 holds at white.
expect Paint.width_shade_middle(0xFAFAFA, Fraction.whole) == 0xFFFFFF

expect Paint.is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(10.5) })
expect !Paint.is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(11.0) })
expect !Paint.is_too_narrow_to_shade({ min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) })

expect Paint.min_shade_width.to_f64() == 1.0
expect Paint.shade_edge_darken.to_f64() == 0.4
expect Paint.shade_middle_lift.to_f64() == 0.25

expect Paint.x_span(wide_corners) == { min_x: Pixels.of(10.0), max_x: Pixels.of(30.0) }
expect Paint.x_span([Screen.point(5.0, 99.0)]) == { min_x: Pixels.of(5.0), max_x: Pixels.of(5.0) }

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
	Paint.round_polygon(wide_corners, { fill_color: sample_color, round_strength: Fraction.whole })
		== [
			Poly({
				pts: [10.0, 1.0, 30.0, 2.0, 20.0, 3.0],
				fill: Span({
					edge: Brush.opaque(0x4D2613),
					middle: Brush.opaque(0xA05028),
					x0: 10.0,
					x1: 30.0,
				}),
			}),
		]

# No strength, or too narrow a polygon, is a solid fill.
expect
	Paint.round_polygon(wide_corners, { fill_color: sample_color, round_strength: Fraction.zero })
		== [
			Poly({
				pts: [
					10.0,
					1.0,
					30.0,
					2.0,
					20.0,
					3.0,
				],
				fill: Flat(Brush.opaque(sample_color)),
			}),
		]

expect
	Paint.round_polygon(
		narrow_corners,
		{ fill_color: sample_color, round_strength: Fraction.whole },
	)
		== [
			Poly({
				pts: [
					10.0,
					1.0,
					10.5,
					2.0,
					10.2,
					3.0,
				],
				fill: Flat(Brush.opaque(sample_color)),
			}),
		]
