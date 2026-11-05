# Paint -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
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

	push_round_poly : List(Screen.Point),
	{
		fill_color : I64,
		round_strength : F64,
	} -> List(Paint.DrawCmd)
	push_round_poly = |ps, { fill_color, round_strength }| (
		if ps.len().to_i64_wrap() < 3 {
			[]
		} else {
			[
				{
					tag: 1,
					color: fill_color,
					color2: 0,
					strength: round_strength,
					geom: [],
					pts: flatten_screen(ps),
				},
			]
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
		if ps.len().to_i64_wrap() < 3 {
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
