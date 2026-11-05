## Paint turns Safari's screen points and whole-number colours into shapes. A
## colour is 0xRRGGBB for a flat polygon, a shaded polygon and a beacon, and
## 0xAARRGGBB for a gradient. Each builder answers a list, empty when there is
## nothing to draw, so a drawing module can join what it builds.
import Fraction
import Num_
import Screen
import lib.Brush
import lib.Shapes

Paint :: [].{

	## The span of x a polygon covers.
	Span : { min_x : F64, max_x : F64 }

	red_of : I64 -> I64
	red_of = |color| I64.bitwise_and(I64.shr_wrap(color, I64.to_u8_wrap(16)), 255)

	green_of : I64 -> I64
	green_of = |color| I64.bitwise_and(I64.shr_wrap(color, I64.to_u8_wrap(8)), 255)

	blue_of : I64 -> I64
	blue_of = |color| I64.bitwise_and(color, 255)

	## A colour as 0xRRGGBB from its three channels.
	pack_rgb : {
		red : I64,
		green : I64,
		blue : I64,
	} -> I64
	pack_rgb = |
		{
			red,
			green,
			blue,
		},
	| {
		red_bits = I64.shl_wrap(red, 16)
		green_bits = I64.shl_wrap(green, 8)
		I64.bitwise_or(I64.bitwise_or(red_bits, green_bits), blue)
	}

	## One channel scaled by `factor`, rounded, and held at 255 at most.
	shade_channel : I64, F64 -> I64
	shade_channel = |channel, factor| {
		scaled = F64.to_i64_wrap(Num_.round_real((I64.to_f64(channel) * factor)))
		if (scaled > 255) 255 else scaled
	}

	shade_color : I64, F64 -> I64
	shade_color = |color, factor|
		pack_rgb({
			red: shade_channel(red_of(color), factor),
			green: shade_channel(green_of(color), factor),
			blue: shade_channel(blue_of(color), factor),
		})

	shade_edge_darken : F64
	shade_edge_darken = 0.4

	shade_middle_lift : F64
	shade_middle_lift = 0.25

	## A shaded polygon's colour at its edges.
	width_shade_edge : I64, Fraction -> I64
	width_shade_edge = |color, strength|
		shade_color(color, (1.0 - (shade_edge_darken * strength.to_f64())))

	## A shaded polygon's colour in its middle.
	width_shade_middle : I64, Fraction -> I64
	width_shade_middle = |color, strength| shade_color(
		color,
		(1.0 + (shade_middle_lift * strength.to_f64())),
	)

	min_shade_width : F64
	min_shade_width = 1.0

	is_too_narrow_to_shade : Paint.Span -> Bool
	is_too_narrow_to_shade = |span| ((span.max_x - span.min_x) < min_shade_width)

	## The span of x over a polygon's points, given flat as x0, y0, x1, y1, ...
	## It has at least one point.
	x_span : List(F64) -> Paint.Span
	x_span = |pts|
		match xs_of(pts) {
			[first, .. as rest] => {
				min_x: rest.fold(first, |least, x| if (x < least) x else least),
				max_x: rest.fold(first, |most, x| if (x > most) x else most),
			}
			[] => crash "Paint.x_span: a polygon has a point"
		}

	flatten_screen : List(Screen.Point) -> List(F64)
	flatten_screen = |ps| {
		var $flat = List.with_capacity(2 * ps.len())
		for p in ps {
			$flat = $flat.append(p.x).append(p.y)
		}
		$flat
	}

	push_poly : I64, List(Screen.Point) -> List(Shapes.Shape)
	push_poly = |color, ps| Shapes.polygon(flatten_screen(ps), Flat(Brush.opaque(color)))

	## A polygon shaded across its width, darker at its edges and lighter in
	## its middle, or a solid one where it has no strength or is too narrow.
	push_round_poly : List(Screen.Point),
	{
		fill_color : I64,
		round_strength : Fraction,
	} -> List(Shapes.Shape)
	push_round_poly = |ps, { fill_color, round_strength }|
		if ps.len() < 3 {
			[]
		} else {
			pts = flatten_screen(ps)
			[Poly({ pts, fill: width_shade(pts, { color: fill_color, strength: round_strength }) })]
		}

	push_beacon : {
		beacon_color : I64,
		beacon_center : Screen.Point,
		beacon_radius : F64,
		beacon_alpha : Fraction,
	} -> List(Shapes.Shape)
	push_beacon = |
		{
			beacon_color,
			beacon_center,
			beacon_radius,
			beacon_alpha,
		},
	| {
		opaque = Brush.opaque(beacon_color)
		[
			Disc({
				x: beacon_center.x,
				y: beacon_center.y,
				r: beacon_radius,
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
	min_gradient_radius : F64
	min_gradient_radius = 0.5

	push_grad_poly : List(Screen.Point),
	{
		center_rgba : I64,
		edge_rgba : I64,
		gradient_center : Screen.Point,
		gradient_radius : F64,
	} -> List(Shapes.Shape)
	push_grad_poly = |
		ps,
		{
			center_rgba,
			edge_rgba,
			gradient_center,
			gradient_radius,
		},
	|
		if gradient_radius < min_gradient_radius {
			[]
		} else {
			Shapes.polygon(
				flatten_screen(ps),
				Radial({
					inner: Brush.with_alpha(center_rgba),
					outer: Brush.with_alpha(edge_rgba),
					x: gradient_center.x,
					y: gradient_center.y,
					r0: 0.0,
					r1: gradient_radius,
				}),
			)
		}

	## A linear gradient with no length has no direction, so it is not drawn.
	push_linear_grad_poly : List(Screen.Point),
	{
		color_stops : Paint.ColorStops,
		start_point : Screen.Point,
		end_point : Screen.Point,
	} -> List(Shapes.Shape)
	push_linear_grad_poly = |
		ps,
		{
			color_stops,
			start_point,
			end_point,
		},
	| {
		dx = end_point.x - start_point.x
		dy = end_point.y - start_point.y
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
					ax: start_point.x,
					ay: start_point.y,
					dx,
					dy,
				}),
			)
		}
	}

	## A gradient on an ellipse, which is `axis_u` and `axis_v` about
	## `center_point`. An ellipse too thin to invert is filled with its first
	## colour.
	push_radial_grad_poly : List(Screen.Point),
	{
		color_stops : Paint.ColorStops,
		center_point : Screen.Point,
		axis_u : Screen.Point,
		axis_v : Screen.Point,
	} -> List(Shapes.Shape)
	push_radial_grad_poly = |
		ps,
		{
			color_stops,
			center_point,
			axis_u,
			axis_v,
		},
	| {
		det = axis_u.x * axis_v.y - axis_u.y * axis_v.x
		first_color = Brush.with_alpha(color_stops.start_rgba)
		fill =
			if F64.abs(det) < min_ellipse_determinant {
				Flat(first_color)
			} else {
				offsets = offsets_of(color_stops)
				Ellipse({
					c0: first_color,
					c1: Brush.with_alpha(color_stops.end_rgba),
					o0: offsets.first,
					o1: offsets.last,
					x: center_point.x,
					y: center_point.y,
					ia: axis_v.y / det,
					ib: (0.0 - axis_v.x) / det,
					ic: (0.0 - axis_u.y) / det,
					id: axis_u.x / det,
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
	{ first, last: F64.max(first, F64.min(1.0, stops.end_offset)) }
}

## The fill of a polygon shaded across its width.
width_shade : List(F64), { color : I64, strength : Fraction } -> Brush.Fill
width_shade = |pts, { color, strength }| {
	span = Paint.x_span(pts)
	if strength <= Fraction.zero or Paint.is_too_narrow_to_shade(span) {
		Flat(Brush.opaque(color))
	} else {
		Span({
			edge: Brush.opaque(Paint.width_shade_edge(color, strength)),
			middle: Brush.opaque(Paint.width_shade_middle(color, strength)),
			x0: span.min_x,
			x1: span.max_x,
		})
	}
}

## The x of each point in a flat list of x, y pairs.
xs_of : List(F64) -> List(F64)
xs_of = |pts|
	pts.chunks_of(2).map(
		|point|
			match point {
				[x, ..] => x
				[] => crash "Paint.xs_of: a chunk of points holds an x"
			},
	)
