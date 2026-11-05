# PaintSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import Paint
import Screen

sp : F64, F64 -> Screen.Point
sp = |x, y| { x: x, y: y }

tri : List(Screen.Point)
tri = [
	sp(1.0, 2.0),
	sp(3.0, 4.0),
	sp(5.0, 6.0),
]

line_ends : List(Screen.Point)
line_ends = [sp(1.0, 2.0), sp(3.0, 4.0)]

flat_got : List(F64)
flat_got = List.concat(Paint.flatten_screen(tri), Paint.flatten_screen([]))

flat_want : List(F64)
flat_want = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

count_got : List(I64)
count_got = [
	Paint.push_poly(7, tri).len().to_i64_wrap(),
	Paint.push_poly(7, line_ends).len().to_i64_wrap(),
	Paint.push_poly(7, []).len().to_i64_wrap(),
	Paint.push_round_poly(tri, { fill_color: 7, round_strength: 0.5 }).len().to_i64_wrap(),
	Paint.push_round_poly(line_ends, { fill_color: 7, round_strength: 0.5 }).len().to_i64_wrap(),
	Paint.push_grad_poly(
		tri,
		{
			center_rgba: 7,
			edge_rgba: 8,
			gradient_center: sp(0.0, 0.0),
			gradient_radius: 1.0,
		},
	).len().to_i64_wrap(),
	Paint.push_grad_poly(
		line_ends,
		{
			center_rgba: 7,
			edge_rgba: 8,
			gradient_center: sp(0.0, 0.0),
			gradient_radius: 1.0,
		},
	).len().to_i64_wrap(),
	Paint.push_grad_poly(
		tri,
		{
			center_rgba: 7,
			edge_rgba: 8,
			gradient_center: sp(0.0, 0.0),
			gradient_radius: 0.5,
		},
	).len().to_i64_wrap(),
	Paint.push_grad_poly(
		tri,
		{
			center_rgba: 7,
			edge_rgba: 8,
			gradient_center: sp(0.0, 0.0),
			gradient_radius: 0.49,
		},
	).len().to_i64_wrap(),
	Paint.push_linear_grad_poly(
		tri,
		{
			color_stops: {
				start_rgba: 7,
				end_rgba: 8,
				start_offset: 0.0,
				end_offset: 1.0,
			},
			start_point: sp(0.0, 0.0),
			end_point: sp(1.0, 1.0),
		},
	).len().to_i64_wrap(),
	Paint.push_linear_grad_poly(
		line_ends,
		{
			color_stops: {
				start_rgba: 7,
				end_rgba: 8,
				start_offset: 0.0,
				end_offset: 1.0,
			},
			start_point: sp(0.0, 0.0),
			end_point: sp(1.0, 1.0),
		},
	).len().to_i64_wrap(),
	Paint.push_radial_grad_poly(
		tri,
		{
			color_stops: {
				start_rgba: 7,
				end_rgba: 8,
				start_offset: 0.0,
				end_offset: 1.0,
			},
			center_point: sp(0.0, 0.0),
			axis_u: sp(1.0, 0.0),
			axis_v: sp(0.0, 1.0),
		},
	).len().to_i64_wrap(),
	Paint.push_radial_grad_poly(
		line_ends,
		{
			color_stops: {
				start_rgba: 7,
				end_rgba: 8,
				start_offset: 0.0,
				end_offset: 1.0,
			},
			center_point: sp(0.0, 0.0),
			axis_u: sp(1.0, 0.0),
			axis_v: sp(0.0, 1.0),
		},
	).len().to_i64_wrap(),
	Paint.push_beacon({
		beacon_color: 7,
		beacon_center: sp(1.0, 2.0),
		beacon_radius: 3.0,
		beacon_alpha: 0.5,
	}).len().to_i64_wrap(),
]

count_want : List(I64)
count_want = [1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]

shape_of : List(Paint.DrawCmd) -> List(I64)
shape_of = |cs| (
	{
		c = (List.get(cs, I64.to_u64_wrap(0)) ?? crash ("list-at out of range"))
		[
			c.tag,
			c.color,
			c.color2,
			c.geom.len().to_i64_wrap(),
			c.pts.len().to_i64_wrap(),
		]
	}
)

solid : List(Paint.DrawCmd)
solid = Paint.push_poly(111, tri)

round : List(Paint.DrawCmd)
round = Paint.push_round_poly(tri, { fill_color: 222, round_strength: 0.75 })

beacon : List(Paint.DrawCmd)
beacon = Paint.push_beacon({
	beacon_color: 333,
	beacon_center: sp(10.0, 20.0),
	beacon_radius: 30.0,
	beacon_alpha: 0.25,
})

radial4 : List(Paint.DrawCmd)
radial4 = Paint.push_grad_poly(
	tri,
	{
		center_rgba: 444,
		edge_rgba: 445,
		gradient_center: sp(10.0, 20.0),
		gradient_radius: 30.0,
	},
)

linear5 : List(Paint.DrawCmd)
linear5 = Paint.push_linear_grad_poly(
	tri,
	{
		color_stops: {
			start_rgba: 555,
			end_rgba: 556,
			start_offset: 0.25,
			end_offset: 0.75,
		},
		start_point: sp(1.0, 2.0),
		end_point: sp(3.0, 4.0),
	},
)

radial6 : List(Paint.DrawCmd)
radial6 = Paint.push_radial_grad_poly(
	tri,
	{
		color_stops: {
			start_rgba: 666,
			end_rgba: 667,
			start_offset: 0.25,
			end_offset: 0.75,
		},
		center_point: sp(1.0, 2.0),
		axis_u: sp(3.0, 4.0),
		axis_v: sp(5.0, 6.0),
	},
)

tags_got : List(I64)
tags_got = List.join([
	shape_of(solid),
	shape_of(round),
	shape_of(beacon),
	shape_of(radial4),
	shape_of(linear5),
	shape_of(radial6),
])

tags_want : List(I64)
tags_want = [
	0,
	111,
	0,
	0,
	6,
	2,
	155,
	255,
	2,
	6,
	3,
	333,
	0,
	3,
	0,
	4,
	444,
	445,
	3,
	6,
	5,
	555,
	556,
	6,
	6,
	6,
	666,
	667,
	8,
	6,
]

strength_got : List(F64)
strength_got = [
	(List.get(solid, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).strength,
	(List.get(round, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).strength,
	(List.get(beacon, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).strength,
	(List.get(radial4, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).strength,
	(List.get(linear5, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).strength,
	(List.get(radial6, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).strength,
]

strength_want : List(F64)
strength_want = [0.0, 0.0, 0.25, 0.0, 0.0, 0.0]

geom_got : List(F64)
geom_got = List.join([
	(List.get(beacon, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).geom,
	(List.get(radial4, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).geom,
	(List.get(linear5, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).geom,
	(List.get(radial6, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).geom,
])

geom_want : List(F64)
geom_want = [
	10.0,
	20.0,
	30.0,
	10.0,
	20.0,
	30.0,
	0.25,
	0.75,
	1.0,
	2.0,
	3.0,
	4.0,
	0.25,
	0.75,
	1.0,
	2.0,
	3.0,
	4.0,
	5.0,
	6.0,
]

pts_got : List(F64)
pts_got = List.join([
	(List.get(solid, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts,
	(List.get(radial6, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts,
	(List.get(beacon, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).pts,
])

pts_want : List(F64)
pts_want = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

color : I64
color = 8405024

chan_got : List(I64)
chan_got = [
	Paint.red_of(color),
	Paint.green_of(color),
	Paint.blue_of(color),
	Paint.pack_rgb({
		red: Paint.red_of(color),
		green: Paint.green_of(color),
		blue: Paint.blue_of(color),
	}),
	Paint.red_of(16777215),
	Paint.green_of(16777215),
	Paint.blue_of(16777215),
	Paint.red_of(0),
	Paint.pack_rgb({
		red: 0,
		green: 0,
		blue: 0,
	}),
	Paint.pack_rgb({
		red: 255,
		green: 255,
		blue: 255,
	}),
]

chan_want : List(I64)
chan_want = [128, 64, 32, 8405024, 255, 255, 255, 0, 0, 16777215]

shade_got : List(I64)
shade_got = [
	Paint.shade_channel(128, 0.6),
	Paint.shade_channel(64, 0.6),
	Paint.shade_channel(32, 0.6),
	Paint.shade_channel(250, 1.25),
	Paint.shade_channel(255, 1.0),
	Paint.shade_channel(255, 2.0),
	Paint.shade_channel(0, 1.25),
	Paint.shade_color(color, 0.6),
]

shade_want : List(I64)
shade_want = [77, 38, 19, 255, 255, 255, 0, 5056019]

shade_ends_got : List(I64)
shade_ends_got = [
	Paint.width_shade_edge(color, 1.0),
	Paint.width_shade_middle(color, 1.0),
	Paint.width_shade_edge(color, 0.5),
	Paint.width_shade_middle(color, 0.5),
	Paint.width_shade_edge(color, 0.0),
	Paint.width_shade_middle(color, 0.0),
]

shade_ends_want : List(I64)
shade_ends_want = [5056019, 10506280, 6697754, 9455652, 8405024, 8405024]

glow_got : List(I64)
glow_got = [Paint.shade_channel(250, 1.25), Paint.width_shade_middle(16448250, 1.0)]

glow_want : List(I64)
glow_want = [255, 16777215]

visible_got : List(Bool)
visible_got = [
	Paint.is_too_narrow_to_shade({ min_x: 10.0, max_x: 10.5 }),
	Paint.is_too_narrow_to_shade({ min_x: 10.0, max_x: 11.0 }),
	Paint.is_too_narrow_to_shade({ min_x: 10.0, max_x: 30.0 }),
]

visible_want : List(Bool)
visible_want = [True, False, False]

limits_got : List(F64)
limits_got = [
	Paint.min_shade_width,
	Paint.shade_edge_darken,
	Paint.shade_middle_lift,
]

limits_want : List(F64)
limits_want = [1.0, 0.4, 0.25]

# Three points, flat: (10, 1), (30, 2) and (20, 3).
poly : List(F64)
poly = [10.0, 1.0, 30.0, 2.0, 20.0, 3.0]

span_got : List(F64)
span_got = {
	wide_span = Paint.x_span(poly)
	one_point = Paint.x_span([5.0, 99.0])
	[
		wide_span.min_x,
		wide_span.max_x,
		one_point.min_x,
		one_point.max_x,
	]
}

span_want : List(F64)
span_want = [10.0, 30.0, 5.0, 5.0]

poly_points : List(Screen.Point)
poly_points = [
	sp(10.0, 1.0),
	sp(30.0, 2.0),
	sp(20.0, 3.0),
]

narrow_points : List(Screen.Point)
narrow_points = [
	sp(10.0, 1.0),
	sp(10.5, 2.0),
	sp(10.2, 3.0),
]

wide : Paint.DrawCmd
wide =
	Paint.push_round_poly(poly_points, { fill_color: color, round_strength: 1.0 }).first()
		?? crash "PaintSpec: a wide polygon is one command"

wide_got : List(I64)
wide_got = [
	wide.tag,
	wide.color,
	wide.color2,
	wide.geom.len().to_i64_wrap(),
	wide.pts.len().to_i64_wrap(),
]

wide_want : List(I64)
wide_want = [2, 5056019, 10506280, 2, 6]

wide_geom_got : List(F64)
wide_geom_got = List.join([
	wide.geom,
	wide.pts,
	[wide.strength],
])

wide_geom_want : List(F64)
wide_geom_want = [10.0, 30.0, 10.0, 1.0, 30.0, 2.0, 20.0, 3.0, 0.0]

unshaded_got : List(I64)
unshaded_got = [
	Paint.push_round_poly(poly_points, { fill_color: color, round_strength: 0.0 }),
	Paint.push_round_poly(narrow_points, { fill_color: color, round_strength: 1.0 }),
].join_map(shape_of)

unshaded_want : List(I64)
unshaded_want = [0, 8405024, 0, 0, 6, 0, 8405024, 0, 0, 6]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "pa-flat  ",
			got: flat_got,
			want: flat_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "pa-guard ",
			got: count_got,
			want: count_want,
		}),
		Grade.ints({
			name: "pa-tags  ",
			got: tags_got,
			want: tags_want,
		}),
		Grade.reals({
			name: "pa-streng",
			got: strength_got,
			want: strength_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "pa-geom  ",
			got: geom_got,
			want: geom_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "pa-pts   ",
			got: pts_got,
			want: pts_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "pa-chan  ",
			got: chan_got,
			want: chan_want,
		}),
		Grade.ints({
			name: "pa-shade ",
			got: shade_got,
			want: shade_want,
		}),
		Grade.ints({
			name: "pa-ends  ",
			got: shade_ends_got,
			want: shade_ends_want,
		}),
		Grade.ints({
			name: "pa-glow  ",
			got: glow_got,
			want: glow_want,
		}),
		Grade.bools({
			name: "pa-narrow",
			got: visible_got,
			want: visible_want,
		}),
		Grade.reals({
			name: "pa-limits",
			got: limits_got,
			want: limits_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "pa-span  ",
			got: span_got,
			want: span_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "pa-wide  ",
			got: wide_got,
			want: wide_want,
		}),
		Grade.reals({
			name: "pa-wgeom ",
			got: wide_geom_got,
			want: wide_geom_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "pa-solid ",
			got: unshaded_got,
			want: unshaded_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
