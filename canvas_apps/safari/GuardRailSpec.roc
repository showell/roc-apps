## These are GuardRail's checks: its dimensions and colours, the bars and
## posts along a straight path and a diagonal one, and the paths too short
## for a rail.
app [main!] {
	lib: "../lib/main.roc",
}

import Geom
import Grade
import GuardRail

dims_got : List(F64)
dims_got = [
	GuardRail.rail_height,
	GuardRail.rail_thickness,
	GuardRail.rail_post_width,
	GuardRail.bar_top,
	GuardRail.bar_bot,
	GuardRail.half_post,
]

dims_want : List(F64)
dims_want = [0.5, 0.1, 0.02, 0.55, 0.45, 0.01]

fixed_got : List(I64)
fixed_got = [
	GuardRail.rail_metal,
	GuardRail.rail_post_metal,
	GuardRail.rail_runout.to_i64(),
	GuardRail.max_rail_polys.to_i64_wrap(),
]

fixed_want : List(I64)
fixed_want = [12765135, 10133672, 10, 3072]

pt : F64, F64 -> Geom.RiderPoint
pt = |right, forward| { right, forward }

quad_at : List(GuardRail.RailPoly), U64 -> GuardRail.RailPoly
quad_at = |quads, i| quads.get(i) ?? crash "GuardRailSpec: an index past the rail's end"

corner_at : GuardRail.RailPoly, U64 -> Geom.SpacePoint
corner_at = |quad, i| quad.corners.get(i) ?? crash "GuardRailSpec: a quad has four corners"

straight : List(Geom.RiderPoint)
straight = [
	pt(0.0, 10.0),
	pt(0.0, 20.0),
	pt(0.0, 30.0),
]

rails : List(GuardRail.RailPoly)
rails = GuardRail.quads_along(straight)

shape_got : List(I64)
shape_got = [
	rails.len().to_i64_wrap(),
	GuardRail.bars(straight).len().to_i64_wrap(),
	GuardRail.posts(straight).len().to_i64_wrap(),
	quad_at(rails, 0).corners.len().to_i64_wrap(),
	quad_at(rails, 4).corners.len().to_i64_wrap(),
]

shape_want : List(I64)
shape_want = [5, 2, 3, 4, 4]

colour_got : List(I64)
colour_got = rails.map(|quad| quad.color)

colour_want : List(I64)
colour_want = [12765135, 12765135, 10133672, 10133672, 10133672]

fwd_got : List(F64)
fwd_got = rails.map(|quad| quad.forward)

fwd_want : List(F64)
fwd_want = [15.0, 25.0, 10.0, 20.0, 30.0]

bar_got : List(F64)
bar_got = {
	corners = quad_at(rails, 0).corners
	List.concat(corners.map(|corner| corner.forward), corners.map(|corner| corner.height))
}

bar_want : List(F64)
bar_want = [10.0, 20.0, 20.0, 10.0, 0.45, 0.45, 0.55, 0.55]

post_got : List(F64)
post_got = {
	post = quad_at(rails, 2)
	List.concat(
		post.corners.map(|corner| corner.forward),
		[
			corner_at(post, 0).height,
			corner_at(post, 2).height,
			corner_at(post, 0).right,
			corner_at(post, 1).right,
		],
	)
}

post_want : List(F64)
post_want = [9.99, 10.01, 10.01, 9.99, 0.0, 0.55, 0.0, 0.0]

diagonal : List(Geom.RiderPoint)
diagonal = [pt(0.0, 10.0), pt(30.0, 50.0)]

diag_got : List(F64)
diag_got = {
	post = quad_at(GuardRail.posts(diagonal), 0)
	[
		corner_at(post, 0).right,
		corner_at(post, 1).right,
		corner_at(post, 0).forward,
		corner_at(post, 1).forward,
	]
}

diag_want : List(F64)
diag_want = [
	(-0.006),
	0.006,
	9.992,
	10.008,
]

doubled : List(Geom.RiderPoint)
doubled = [pt(0.0, 10.0), pt(0.0, 10.0)]

doubled_got : List(F64)
doubled_got = {
	post = quad_at(GuardRail.posts(doubled), 0)
	[
		GuardRail.quads_along(doubled).len().to_f64(),
		corner_at(post, 0).right,
		corner_at(post, 1).right,
		corner_at(post, 0).forward,
		corner_at(post, 1).forward,
		corner_at(post, 2).height,
	]
}

doubled_want : List(F64)
doubled_want = [3.0, 0.0, 0.0, 10.0, 10.0, 0.55]

short_got : List(I64)
short_got = [
	GuardRail.quads_along([]).len().to_i64_wrap(),
	GuardRail.quads_along([pt(0.0, 10.0)]).len().to_i64_wrap(),
	GuardRail.quads_along(doubled).len().to_i64_wrap(),
	GuardRail.bars([pt(0.0, 10.0)]).len().to_i64_wrap(),
]

short_want : List(I64)
short_want = [0, 0, 3, 0]

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "gu-dims  ",
			got: dims_got,
			want: dims_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "gu-fixed ",
			got: fixed_got,
			want: fixed_want,
		}),
		Grade.ints({
			name: "gu-shape ",
			got: shape_got,
			want: shape_want,
		}),
		Grade.ints({
			name: "gu-colour",
			got: colour_got,
			want: colour_want,
		}),
		Grade.reals({
			name: "gu-fwd   ",
			got: fwd_got,
			want: fwd_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gu-bar   ",
			got: bar_got,
			want: bar_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gu-post  ",
			got: post_got,
			want: post_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gu-diag  ",
			got: diag_got,
			want: diag_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "gu-double",
			got: doubled_got,
			want: doubled_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "gu-short ",
			got: short_got,
			want: short_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
