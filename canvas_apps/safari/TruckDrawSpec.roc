# TruckDrawSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Camera
import Geom
import Grade
import TruckDraw

box_at : F64, F64 -> List(F64)
box_at = |c, hw| (
	{
		b = TruckDraw.truck_box(c, hw)
		[b.a0, b.a1, b.a2, b.a_roof, b.xl, b.xr]
	}
)

box_got : List(F64)
box_got = List.concat(box_at(0.0, 0.0), box_at(40.0, 2.0))

box_want : List(F64)
box_want = [(-4.2), 4.2, 7.7, 5.25, (-1.2), 1.2, 35.8, 44.2, 47.7, 45.25, 0.8, 3.2]

bottom_got : List(F64)
bottom_got = [TruckDraw.tire_radius, TruckDraw.trailer_bottom, TruckDraw.cab_bottom, TruckDraw.truck_height, TruckDraw.truck_width, TruckDraw.truck_length]

bottom_want : List(F64)
bottom_want = [0.5, 1.12, 0.5, 3.6, 2.4, 8.4]

axles_got : List(F64)
axles_got = List.concat(TruckDraw.truck_axles(TruckDraw.truck_box(0.0, 0.0)), TruckDraw.truck_axles(TruckDraw.truck_box(40.0, 2.0)))

axles_want : List(F64)
axles_want = [(-3.2), (-2.0), 2.0, 3.2, 6.125, 36.8, 38.0, 42.0, 43.2, 46.125]

axle_count_got : List(I64)
axle_count_got = [TruckDraw.truck_axles(TruckDraw.truck_box(0.0, 0.0)).len().to_i64_wrap()]

axle_count_want : List(I64)
axle_count_want = [5]

v3 : F64 -> Geom.Vec3
v3 = |f| { right: 0.0, forward: f, height: 0.0 }

quad_face : TruckDraw.TruckFace
quad_face = TruckDraw.truck_face(1846886, [v3(10.0), v3(20.0), v3(30.0), v3(40.0)])

tri_face : TruckDraw.TruckFace
tri_face = TruckDraw.truck_face(1381658, [v3(1.0), v3(2.0), v3(6.0)])

face_got : List(F64)
face_got = [quad_face.fwd, tri_face.fwd]

face_want : List(F64)
face_want = [25.0, 3.0]

face_carry_got : List(I64)
face_carry_got = [quad_face.color, quad_face.v.len().to_i64_wrap(), tri_face.color, tri_face.v.len().to_i64_wrap()]

face_carry_want : List(I64)
face_carry_want = [1846886, 4, 1381658, 3]

mark : I64, F64 -> TruckDraw.TruckFace
mark = |c, f| { color: c, fwd: f, v: [] }

# colours builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
colours : List(TruckDraw.TruckFace), I64 -> List(I64)
colours = |fs, i| colours_onto(fs, i, [])

colours_onto : List(TruckDraw.TruckFace), I64, List(I64) -> List(I64)
colours_onto = |fs, i, acc| (
	if (i >= fs.len().to_i64_wrap()) {
		acc
	} else {
		colours_onto(fs, (i + 1), List.append(acc, (List.get(fs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")).color))
	}
)

tied : List(TruckDraw.TruckFace)
tied = [mark(1, 30.0), mark(2, 10.0), mark(3, 30.0), mark(4, 20.0), mark(5, 30.0)]

tied_got : List(I64)
tied_got = colours(TruckDraw.sort_faces(tied), 0)

tied_want : List(I64)
tied_want = [1, 3, 5, 4, 2]

slack : List(TruckDraw.TruckFace)
slack = [mark(1, 20.0), mark(2, 20.000001), mark(3, 20.01), mark(4, 19.0)]

slack_got : List(I64)
slack_got = colours(TruckDraw.sort_faces(slack), 0)

slack_want : List(I64)
slack_want = [3, 1, 2, 4]

small_got : List(I64)
small_got = [TruckDraw.sort_faces([]).len().to_i64_wrap(), TruckDraw.sort_faces([mark(7, 1.0)]).len().to_i64_wrap(), (List.get(TruckDraw.sort_faces([mark(7, 1.0)]), I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).color]

small_want : List(I64)
small_want = [0, 1, 7]

sp : F64, F64 -> Camera.ScreenPt
sp = |x, y| { x: x, y: y }

panel : List(Camera.ScreenPt)
panel = [sp(3.0, 4.0), sp(6.0, 8.0), sp(0.0, 0.0), sp(7.0, 4.0)]

halo_got : List(F64)
halo_got = (
	{
		cx = (TruckDraw.sum_x(panel, 0) / 4.0)
		cy = (TruckDraw.sum_y(panel, 0) / 4.0)
		[TruckDraw.sum_x(panel, 0), TruckDraw.sum_y(panel, 0), cx, cy, TruckDraw.pt_dist(sp(3.0, 4.0), sp(0.0, 0.0)), TruckDraw.max_radius(panel, sp(0.0, 0.0)), (TruckDraw.max_radius(panel, sp(0.0, 0.0)) * 3.2)]
	}
)

halo_want : List(F64)
halo_want = [16.0, 16.0, 4.0, 4.0, 5.0, 10.0, 32.0]

circle_count_got : List(I64)
circle_count_got = [TruckDraw.glow_circle(0.0, 0.0, 10.0, 0).len().to_i64_wrap(), TruckDraw.glow_sides, TruckDraw.tire_sides]

circle_count_want : List(I64)
circle_count_want = [16, 16, 16]

behind_got : List(Bool)
behind_got = [TruckDraw.any_behind([v3(10.0), v3(20.0), v3(30.0)]), TruckDraw.any_behind([v3(10.0), v3(0.2), v3(30.0)]), TruckDraw.any_behind([v3(10.0), v3(0.4), v3(30.0)]), TruckDraw.any_behind([v3(0.41)]), TruckDraw.any_behind([])]

behind_want : List(Bool)
behind_want = [False, True, True, False, False]

mid_got : List(F64)
mid_got = (
	{
		m = TruckDraw.mid_vec({ right: 1.0, forward: 2.0, height: 3.0 }, { right: 5.0, forward: 8.0, height: 11.0 })
		[m.right, m.forward, m.height]
	}
)

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
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
