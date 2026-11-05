## These are the truck's checks: its box and dimensions, its axles, a face's
## depth, the depth sort's ties, and the lights' geometry on screen.
app [main!] {
	lib: "../lib/main.roc",
}

import Camera
import DepthSort
import Geom
import Grade
import TruckBody
import TruckLights
import TruckShape

box_at : { along : F64, across : F64 } -> List(F64)
box_at = |center| {
	box = TruckShape.truck_box(center)
	[
		box.rear,
		box.trailer_front,
		box.nose,
		box.roof_front,
		box.left,
		box.right,
	]
}

box_got : List(F64)
box_got = List.concat(box_at({ along: 0.0, across: 0.0 }), box_at({ along: 40.0, across: 2.0 }))

box_want : List(F64)
box_want = [
	(-4.2),
	4.2,
	7.7,
	5.25,
	(-1.2),
	1.2,
	35.8,
	44.2,
	47.7,
	45.25,
	0.8,
	3.2,
]

bottom_got : List(F64)
bottom_got = [
	TruckShape.tire_radius,
	TruckShape.trailer_bottom,
	TruckShape.cab_bottom,
	TruckShape.truck_height,
	TruckShape.truck_width,
	TruckShape.trailer_length,
]

bottom_want : List(F64)
bottom_want = [0.5, 1.12, 0.5, 3.6, 2.4, 8.4]

axles_got : List(F64)
axles_got = List.concat(
	TruckBody.axles(TruckShape.truck_box({ along: 0.0, across: 0.0 })),
	TruckBody.axles(TruckShape.truck_box({ along: 40.0, across: 2.0 })),
)

axles_want : List(F64)
axles_want = [
	(-3.2),
	(-2.0),
	2.0,
	3.2,
	6.125,
	36.8,
	38.0,
	42.0,
	43.2,
	46.125,
]

axle_count_got : List(I64)
axle_count_got = [
	TruckBody.axles(
		TruckShape.truck_box({
			along: 0.0,
			across: 0.0,
		}),
	).len().to_i64_wrap(),
]

axle_count_want : List(I64)
axle_count_want = [5]

v3 : F64 -> Geom.SpacePoint
v3 = |f| {
	right: 0.0,
	forward: f,
	height: 0.0,
}

quad_face : TruckBody.TruckFace
quad_face = TruckBody.face(
	1846886,
	[
		v3(10.0),
		v3(20.0),
		v3(30.0),
		v3(40.0),
	],
)

tri_face : TruckBody.TruckFace
tri_face = TruckBody.face(
	1381658,
	[
		v3(1.0),
		v3(2.0),
		v3(6.0),
	],
)

face_got : List(F64)
face_got = [quad_face.depth, tri_face.depth]

face_want : List(F64)
face_want = [25.0, 3.0]

face_carry_got : List(I64)
face_carry_got = [
	quad_face.color,
	quad_face.corners.len().to_i64_wrap(),
	tri_face.color,
	tri_face.corners.len().to_i64_wrap(),
]

face_carry_want : List(I64)
face_carry_want = [1846886, 4, 1381658, 3]

# A face that is only a colour and a depth, for the sort.
mark : I64, F64 -> TruckBody.TruckFace
mark = |color, depth| {
	color,
	depth,
	corners: [],
}

colors_by_depth : List(TruckBody.TruckFace) -> List(I64)
colors_by_depth = |faces| DepthSort.sort_by(faces, |face| face.depth).map(|face| face.color)

tied_got : List(I64)
tied_got = colors_by_depth([
	mark(1, 30.0),
	mark(2, 10.0),
	mark(3, 30.0),
	mark(4, 20.0),
	mark(5, 30.0),
])

tied_want : List(I64)
tied_want = [1, 3, 5, 4, 2]

slack_got : List(I64)
slack_got = colors_by_depth([
	mark(1, 20.0),
	mark(2, 20.000001),
	mark(3, 20.01),
	mark(4, 19.0),
])

slack_want : List(I64)
slack_want = [3, 1, 2, 4]

small_got : List(I64)
small_got = [
	colors_by_depth([]).len().to_i64_wrap(),
	colors_by_depth([mark(7, 1.0)]).len().to_i64_wrap(),
	(colors_by_depth([mark(7, 1.0)]).first() ?? crash "TruckDrawSpec: a sort of one face keeps it"),
]

small_want : List(I64)
small_want = [0, 1, 7]

sp : F64, F64 -> Camera.ScreenPt
sp = |x, y| { x, y }

panel : List(Camera.ScreenPt)
panel = [
	sp(3.0, 4.0),
	sp(6.0, 8.0),
	sp(0.0, 0.0),
	sp(7.0, 4.0),
]

triangle : List(Camera.ScreenPt)
triangle = [
	sp(0.0, 0.0),
	sp(3.0, 0.0),
	sp(0.0, 6.0),
]

halo_got : List(F64)
halo_got = {
	panel_center = TruckLights.center_of(panel)
	triangle_center = TruckLights.center_of(triangle)
	[
		panel_center.x,
		panel_center.y,
		triangle_center.x,
		triangle_center.y,
		TruckLights.distance({ from: sp(3.0, 4.0), to: sp(0.0, 0.0) }),
		TruckLights.farthest_from(panel, sp(0.0, 0.0)),
		TruckLights.glow_radius(panel, sp(0.0, 0.0)),
	]
}

halo_want : List(F64)
halo_want = [4.0, 4.0, 1.0, 2.0, 5.0, 10.0, 32.0]

circle_count_got : List(I64)
circle_count_got = [
	TruckLights.glow_outline({ center: sp(0.0, 0.0), radius: 10.0 }).len().to_i64_wrap(),
	TruckLights.glow_sides,
	TruckBody.tire_sides,
]

circle_count_want : List(I64)
circle_count_want = [16, 16, 16]

behind_got : List(Bool)
behind_got = [
	TruckLights.has_point_behind_camera([
		v3(10.0),
		v3(20.0),
		v3(30.0),
	]),
	TruckLights.has_point_behind_camera([
		v3(10.0),
		v3(0.2),
		v3(30.0),
	]),
	TruckLights.has_point_behind_camera([
		v3(10.0),
		v3(0.4),
		v3(30.0),
	]),
	TruckLights.has_point_behind_camera([v3(0.41)]),
	TruckLights.has_point_behind_camera([]),
]

behind_want : List(Bool)
behind_want = [False, True, True, False, False]

mid_got : List(F64)
mid_got = {
	m = TruckLights.midpoint({
		from: {
			right: 1.0,
			forward: 2.0,
			height: 3.0,
		},
		to: {
			right: 5.0,
			forward: 8.0,
			height: 11.0,
		},
	})
	[
		m.right,
		m.forward,
		m.height,
	]
}

mid_want : List(F64)
mid_want = [3.0, 5.0, 7.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "td-box   ",
			got: box_got,
			want: box_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "td-bottom",
			got: bottom_got,
			want: bottom_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "td-axles ",
			got: axles_got,
			want: axles_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "td-naxle ",
			got: axle_count_got,
			want: axle_count_want,
		}),
		Grade.reals({
			name: "td-face  ",
			got: face_got,
			want: face_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "td-carry ",
			got: face_carry_got,
			want: face_carry_want,
		}),
		Grade.ints({
			name: "td-tied  ",
			got: tied_got,
			want: tied_want,
		}),
		Grade.ints({
			name: "td-slack ",
			got: slack_got,
			want: slack_want,
		}),
		Grade.ints({
			name: "td-small ",
			got: small_got,
			want: small_want,
		}),
		Grade.reals({
			name: "td-halo  ",
			got: halo_got,
			want: halo_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "td-circle",
			got: circle_count_got,
			want: circle_count_want,
		}),
		Grade.bools({
			name: "td-behind",
			got: behind_got,
			want: behind_want,
		}),
		Grade.reals({
			name: "td-mid   ",
			got: mid_got,
			want: mid_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
