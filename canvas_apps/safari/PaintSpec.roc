# PaintSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Camera
import Grade
import Paint

sp : F64, F64 -> Camera.ScreenPt
sp = |x, y| { x: x, y: y }

tri : List(Camera.ScreenPt)
tri = [
	sp(1.0, 2.0),
	sp(3.0, 4.0),
	sp(5.0, 6.0),
]

line_ends : List(Camera.ScreenPt)
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
count_want = [1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]

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
	1,
	222,
	0,
	0,
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
strength_want = [0.0, 0.75, 0.25, 0.0, 0.0, 0.0]

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
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
