# TruckDrawSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Camera
import Geom
import Grade
import Text
import TruckDraw

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

box_at : F64, F64 -> List(F64)
box_at = |c, hw| ({
	b = TruckDraw.truck_box(c, hw)
	[b.a0, b.a1, b.a2, b.a_roof, b.xl, b.xr]
})

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
axle_count_got = [U64.to_i64_wrap(List.len(TruckDraw.truck_axles(TruckDraw.truck_box(0.0, 0.0))))]

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
face_carry_got = [quad_face.color, U64.to_i64_wrap(List.len(quad_face.v)), tri_face.color, U64.to_i64_wrap(List.len(tri_face.v))]

face_carry_want : List(I64)
face_carry_want = [1846886, 4, 1381658, 3]

mark : I64, F64 -> TruckDraw.TruckFace
mark = |c, f| { color: c, fwd: f, v: [] }

# colours_of builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
colours_of : List(TruckDraw.TruckFace), I64 -> List(I64)
colours_of = |fs, i| colours_of_acc(fs, i, [])

colours_of_acc : List(TruckDraw.TruckFace), I64, List(I64) -> List(I64)
colours_of_acc = |fs, i, acc| (if (i >= U64.to_i64_wrap(List.len(fs))) { acc } else { colours_of_acc(fs, (i + 1), List.append(acc, (List.get(fs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).color)) })

tied : List(TruckDraw.TruckFace)
tied = [mark(1, 30.0), mark(2, 10.0), mark(3, 30.0), mark(4, 20.0), mark(5, 30.0)]

tied_got : List(I64)
tied_got = colours_of(TruckDraw.sort_faces(tied), 0)

tied_want : List(I64)
tied_want = [1, 3, 5, 4, 2]

slack : List(TruckDraw.TruckFace)
slack = [mark(1, 20.0), mark(2, 20.000001), mark(3, 20.01), mark(4, 19.0)]

slack_got : List(I64)
slack_got = colours_of(TruckDraw.sort_faces(slack), 0)

slack_want : List(I64)
slack_want = [3, 1, 2, 4]

small_got : List(I64)
small_got = [U64.to_i64_wrap(List.len(TruckDraw.sort_faces([]))), U64.to_i64_wrap(List.len(TruckDraw.sort_faces([mark(7, 1.0)]))), (List.get(TruckDraw.sort_faces([mark(7, 1.0)]), I64.to_u64_wrap(0)) ?? crash("list-at out of range")).color]

small_want : List(I64)
small_want = [0, 1, 7]

sp : F64, F64 -> Camera.ScreenPt
sp = |x, y| { x: x, y: y }

panel : List(Camera.ScreenPt)
panel = [sp(3.0, 4.0), sp(6.0, 8.0), sp(0.0, 0.0), sp(7.0, 4.0)]

halo_got : List(F64)
halo_got = ({
	cx = (TruckDraw.sum_x(panel, 0) / 4.0)
	cy = (TruckDraw.sum_y(panel, 0) / 4.0)
	[TruckDraw.sum_x(panel, 0), TruckDraw.sum_y(panel, 0), cx, cy, TruckDraw.pt_dist(sp(3.0, 4.0), sp(0.0, 0.0)), TruckDraw.max_radius(panel, sp(0.0, 0.0), 0), (TruckDraw.max_radius(panel, sp(0.0, 0.0), 0) * 3.2)]
})

halo_want : List(F64)
halo_want = [16.0, 16.0, 4.0, 4.0, 5.0, 10.0, 32.0]

circle_count_got : List(I64)
circle_count_got = [U64.to_i64_wrap(List.len(TruckDraw.glow_circle(0.0, 0.0, 10.0, 0))), TruckDraw.glow_sides, TruckDraw.tire_sides]

circle_count_want : List(I64)
circle_count_want = [16, 16, 16]

behind_got : List(Bool)
behind_got = [TruckDraw.any_behind([v3(10.0), v3(20.0), v3(30.0)], 0), TruckDraw.any_behind([v3(10.0), v3(0.2), v3(30.0)], 0), TruckDraw.any_behind([v3(10.0), v3(0.4), v3(30.0)], 0), TruckDraw.any_behind([v3(0.41)], 0), TruckDraw.any_behind([], 0)]

behind_want : List(Bool)
behind_want = [False, True, True, False, False]

mid_got : List(F64)
mid_got = ({
	m = TruckDraw.mid_vec({ right: 1.0, forward: 2.0, height: 3.0 }, { right: 5.0, forward: 8.0, height: 11.0 })
	[m.right, m.forward, m.height]
})

mid_want : List(F64)
mid_want = [3.0, 5.0, 7.0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([14, 22, 73, 32, 16, 36, 2, 2, 2], box_got, box_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 22, 73, 32, 16, 14, 14, 16, 26], bottom_got, bottom_want, 0.0)))
	line!(Text.printed(Grade.grade_reals([14, 22, 73, 15, 36, 23, 13, 19, 2], axles_got, axles_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 22, 73, 18, 15, 36, 23, 13, 2], axle_count_got, axle_count_want)))
	line!(Text.printed(Grade.grade_reals([14, 22, 73, 28, 15, 24, 13, 2, 2], face_got, face_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 22, 73, 24, 15, 21, 21, 30, 2], face_carry_got, face_carry_want)))
	line!(Text.printed(Grade.grade_ints([14, 22, 73, 14, 17, 13, 22, 2, 2], tied_got, tied_want)))
	line!(Text.printed(Grade.grade_ints([14, 22, 73, 19, 23, 15, 24, 34, 2], slack_got, slack_want)))
	line!(Text.printed(Grade.grade_ints([14, 22, 73, 19, 26, 15, 23, 23, 2], small_got, small_want)))
	line!(Text.printed(Grade.grade_reals([14, 22, 73, 20, 15, 23, 16, 2, 2], halo_got, halo_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([14, 22, 73, 24, 17, 21, 24, 23, 13], circle_count_got, circle_count_want)))
	line!(Text.printed(Grade.grade_bools([14, 22, 73, 32, 13, 20, 17, 18, 22], behind_got, behind_want)))
	Ok({})
}
