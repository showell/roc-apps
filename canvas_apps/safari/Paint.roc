# Paint -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Num_
import Screen

Paint :: [].{
	DrawCmd : {
		tag : I64,
		color : I64,
		color2 : I64,
		strength : F64,
		geom : List(F64),
		pts : List(F64),
	}

	# An accumulator loop is linear, where appending a recursive call is quadratic.
	flatten_screen : List(Screen.Point) -> List(F64)
	flatten_screen = |ps| flatten_screen_onto(ps, { at_index: 0, flat_coords: [] })

	flatten_screen_onto : List(Screen.Point),
	{
		at_index : I64,
		flat_coords : List(F64),
	} -> List(F64)
	flatten_screen_onto = |ps, { at_index: i, flat_coords: acc }| (
		if i >= ps.len().to_i64_wrap() {
			acc
		} else {
			(
				{
					p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))
					flatten_screen_onto(
						ps,
						{
							at_index: (i + 1),
							flat_coords: List.append(List.append(acc, p.x), p.y),
						},
					)
				}
			)
		}
	)

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
	width_shade_edge : I64, F64 -> I64
	width_shade_edge = |color, strength| shade_color(color, (1.0 - (shade_edge_darken * strength)))

	## A shaded polygon's colour in its middle.
	width_shade_middle : I64, F64 -> I64
	width_shade_middle = |color, strength| shade_color(
		color,
		(1.0 + (shade_middle_lift * strength)),
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

	push_poly : I64, List(Screen.Point) -> List(Paint.DrawCmd)
	push_poly = |color, ps| (
		if ps.len().to_i64_wrap() < 3 {
			[]
		} else {
			[
				{
					tag: 0,
					color: color,
					color2: 0,
					strength: 0.0,
					geom: [],
					pts: flatten_screen(ps),
				},
			]
		}
	)

	## A polygon shaded across its width, darker at its edges and lighter in
	## its middle, or a solid one where it has no strength or is too narrow.
	push_round_poly : List(Screen.Point),
	{
		fill_color : I64,
		round_strength : F64,
	} -> List(Paint.DrawCmd)
	push_round_poly = |ps, { fill_color, round_strength }| (
		if ps.len().to_i64_wrap() < 3 {
			[]
		} else {
			pts = flatten_screen(ps)
			span = x_span(pts)
			if round_strength <= 0.0 or is_too_narrow_to_shade(span) {
				push_poly(fill_color, ps)
			} else {
				[
					{
						tag: 2,
						color: width_shade_edge(fill_color, round_strength),
						color2: width_shade_middle(fill_color, round_strength),
						strength: 0.0,
						geom: [span.min_x, span.max_x],
						pts,
					},
				]
			}
		}
	)

	## The tag of a beacon: a disc whose geometry is its x, y and radius, and
	## whose strength is its alpha.
	beacon_tag : I64
	beacon_tag = 3

	push_beacon : {
		beacon_color : I64,
		beacon_center : Screen.Point,
		beacon_radius : F64,
		beacon_alpha : F64,
	} -> List(Paint.DrawCmd)
	push_beacon = |
		{
			beacon_color,
			beacon_center,
			beacon_radius,
			beacon_alpha,
		},
	| [
		{
			tag: beacon_tag,
			color: beacon_color,
			color2: 0,
			strength: beacon_alpha,
			geom: [
				beacon_center.x,
				beacon_center.y,
				beacon_radius,
			],
			pts: [],
		},
	]

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
	} -> List(Paint.DrawCmd)
	push_grad_poly = |
		ps,
		{
			center_rgba,
			edge_rgba,
			gradient_center,
			gradient_radius,
		},
	| (
		if ps.len().to_i64_wrap() < 3 or gradient_radius < min_gradient_radius {
			[]
		} else {
			[
				{
					tag: 4,
					color: center_rgba,
					color2: edge_rgba,
					strength: 0.0,
					geom: [
						gradient_center.x,
						gradient_center.y,
						gradient_radius,
					],
					pts: flatten_screen(ps),
				},
			]
		}
	)

	push_linear_grad_poly : List(Screen.Point),
	{
		color_stops : Paint.ColorStops,
		start_point : Screen.Point,
		end_point : Screen.Point,
	} -> List(Paint.DrawCmd)
	push_linear_grad_poly = |
		ps,
		{
			color_stops,
			start_point,
			end_point,
		},
	| (
		if ps.len().to_i64_wrap() < 3 {
			[]
		} else {
			[
				{
					tag: 5,
					color: color_stops.start_rgba,
					color2: color_stops.end_rgba,
					strength: 0.0,
					geom: [
						color_stops.start_offset,
						color_stops.end_offset,
						start_point.x,
						start_point.y,
						end_point.x,
						end_point.y,
					],
					pts: flatten_screen(ps),
				},
			]
		}
	)

	push_radial_grad_poly : List(Screen.Point),
	{
		color_stops : Paint.ColorStops,
		center_point : Screen.Point,
		axis_u : Screen.Point,
		axis_v : Screen.Point,
	} -> List(Paint.DrawCmd)
	push_radial_grad_poly = |
		ps,
		{
			color_stops,
			center_point,
			axis_u,
			axis_v,
		},
	| (
		if ps.len().to_i64_wrap() < 3 {
			[]
		} else {
			[
				{
					tag: 6,
					color: color_stops.start_rgba,
					color2: color_stops.end_rgba,
					strength: 0.0,
					geom: [
						color_stops.start_offset,
						color_stops.end_offset,
						center_point.x,
						center_point.y,
						axis_u.x,
						axis_u.y,
						axis_v.x,
						axis_v.y,
					],
					pts: flatten_screen(ps),
				},
			]
		}
	)
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
