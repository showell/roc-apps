## These are Paint's checks: the shape each builder makes, what each one drops,
## and the arithmetic behind a shaded polygon.
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import Paint
import Screen
import ShapeRead
import lib.Brush
import lib.Shapes

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

solid : List(Shapes.Shape)
solid = Paint.push_poly(111, tri)

round : List(Shapes.Shape)
round = Paint.push_round_poly(tri, { fill_color: 222, round_strength: 0.75 })

beacon : List(Shapes.Shape)
beacon = Paint.push_beacon({
	beacon_color: 333,
	beacon_center: sp(10.0, 20.0),
	beacon_radius: 30.0,
	beacon_alpha: 0.25,
})

radial4 : List(Shapes.Shape)
radial4 = Paint.push_grad_poly(
	tri,
	{
		center_rgba: 444,
		edge_rgba: 445,
		gradient_center: sp(10.0, 20.0),
		gradient_radius: 30.0,
	},
)

linear5 : List(Shapes.Shape)
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

radial6 : List(Shapes.Shape)
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

tri_pts : List(F64)
tri_pts = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

stops : Paint.ColorStops
stops = {
	start_rgba: 666,
	end_rgba: 667,
	start_offset: 0.25,
	end_offset: 0.75,
}

ellipse_on : { axis_u : Screen.Point, axis_v : Screen.Point } -> List(Shapes.Shape)
ellipse_on = |{ axis_u, axis_v }|
	Paint.push_radial_grad_poly(
		tri,
		{
			color_stops: stops,
			center_point: sp(1.0, 2.0),
			axis_u,
			axis_v,
		},
	)

line_with : { start_offset : F64, end_offset : F64 } -> List(Shapes.Shape)
line_with = |{ start_offset, end_offset }|
	Paint.push_linear_grad_poly(
		tri,
		{
			color_stops: {
				..stops,
				start_offset,
				end_offset,
			},
			start_point: sp(1.0, 2.0),
			end_point: sp(3.0, 4.0),
		},
	)

linear_fill : { o0 : F64, o1 : F64 } -> Shapes.Shape
linear_fill = |{ o0, o1 }|
	Poly({
		pts: tri_pts,
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

built_got : List(Bool)
built_got = [
	solid == [Poly({ pts: tri_pts, fill: Flat(Brush.opaque(111)) })],
	round
		== [
			Poly({
				pts: tri_pts,
				fill: Span({
					edge: Brush.opaque(155),
					middle: Brush.opaque(255),
					x0: 1.0,
					x1: 5.0,
				}),
			}),
		],
	beacon
		== [
			Disc({
				x: 10.0,
				y: 20.0,
				r: 30.0,
				fill: Flat({ ..Brush.opaque(333), a: 0.25 }),
				clip: Anywhere,
			}),
		],
	radial4
		== [
			Poly({
				pts: tri_pts,
				fill: Radial({
					inner: Brush.with_alpha(444),
					outer: Brush.with_alpha(445),
					x: 10.0,
					y: 20.0,
					r0: 0.0,
					r1: 30.0,
				}),
			}),
		],
	linear5
		== [
			Poly({
				pts: tri_pts,
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
		],
	radial6
		== [
			Poly({
				pts: tri_pts,
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
		],
]

built_want : List(Bool)
built_want = [True, True, True, True, True, True]

## An offset outside 0 to 1 is held there, and the last is never before the first.
offsets_got : List(Bool)
offsets_got = [
	line_with({ start_offset: -1.0, end_offset: 2.0 }) == [linear_fill({ o0: 0.0, o1: 1.0 })],
	line_with({ start_offset: 0.0, end_offset: 1.0 }) == [linear_fill({ o0: 0.0, o1: 1.0 })],
	line_with({ start_offset: 0.75, end_offset: 0.25 }) == [linear_fill({ o0: 0.75, o1: 0.75 })],
]

offsets_want : List(Bool)
offsets_want = [True, True, True]

## A linear gradient of no length is dropped, however short one with a length is.
no_length_got : List(I64)
no_length_got = [sp(1.0, 2.0), sp(1.0, 2.5)].map(
	|end_point|
		Paint.push_linear_grad_poly(
			tri,
			{
				color_stops: stops,
				start_point: sp(1.0, 2.0),
				end_point,
			},
		).len().to_i64_wrap(),
)

no_length_want : List(I64)
no_length_want = [0, 1]

## An ellipse just under the limit is flat, and one just over it is not.
thin_got : List(Bool)
thin_got = {
	thin = ellipse_on({ axis_u: sp(0.01, 0.0), axis_v: sp(0.0, 0.009) })
	wide_enough = ellipse_on({ axis_u: sp(0.01, 0.0), axis_v: sp(0.0, 0.011) })
	[
		thin == [Poly({ pts: tri_pts, fill: Flat(Brush.with_alpha(666)) })],
		wide_enough == [Poly({ pts: tri_pts, fill: Flat(Brush.with_alpha(666)) })],
	]
}

thin_want : List(Bool)
thin_want = [True, False]

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

wide_got : List(Bool)
wide_got = [
	Paint.push_round_poly(poly_points, { fill_color: color, round_strength: 1.0 })
		== [
			Poly({
				pts: [10.0, 1.0, 30.0, 2.0, 20.0, 3.0],
				fill: Span({
					edge: Brush.opaque(5056019),
					middle: Brush.opaque(10506280),
					x0: 10.0,
					x1: 30.0,
				}),
			}),
		],
]

wide_want : List(Bool)
wide_want = [True]

unshaded_got : List(I64)
unshaded_got = [
	Paint.push_round_poly(poly_points, { fill_color: color, round_strength: 0.0 }),
	Paint.push_round_poly(narrow_points, { fill_color: color, round_strength: 1.0 }),
].map(
	|shapes| ShapeRead.flat_color_of(shapes.first() ?? crash "PaintSpec: three points are one polygon"),
)

unshaded_want : List(I64)
unshaded_want = [8405024, 8405024]

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
		Grade.bools({
			name: "pa-built ",
			got: built_got,
			want: built_want,
		}),
		Grade.bools({
			name: "pa-offset",
			got: offsets_got,
			want: offsets_want,
		}),
		Grade.ints({
			name: "pa-nolen ",
			got: no_length_got,
			want: no_length_want,
		}),
		Grade.bools({
			name: "pa-thin  ",
			got: thin_got,
			want: thin_want,
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
		Grade.bools({
			name: "pa-wide  ",
			got: wide_got,
			want: wide_want,
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
