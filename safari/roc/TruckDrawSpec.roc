# TruckDrawSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import DepthSort
import Geom
import Grade
import Maybe
import Scenery
import TruckDraw
import Tuple

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
colours_of_acc = |fs, i, acc| (if (i >= U64.to_i64_wrap(List.len(fs))) { acc } else { colours_of_acc(fs, (i + 1), List.concat(acc, [(List.get(fs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).color])) })

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

eq_tup2 : Tuple.Tup2(a, b), Tuple.Tup2(a, b) -> Bool
eq_tup2 = |ex, ey| (match ex {
	MkTup2(exf0, exf1) => (match ey {
		MkTup2(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
		_ => False
	})
})

eq_tup3 : Tuple.Tup3(a, b, c), Tuple.Tup3(a, b, c) -> Bool
eq_tup3 = |ex, ey| (match ex {
	MkTup3(exf0, exf1, exf2) => (match ey {
		MkTup3(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
		_ => False
	})
})

eq_tup4 : Tuple.Tup4(a, b, c, d), Tuple.Tup4(a, b, c, d) -> Bool
eq_tup4 = |ex, ey| (match ex {
	MkTup4(exf0, exf1, exf2, exf3) => (match ey {
		MkTup4(eyf0, eyf1, eyf2, eyf3) => ((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3))
		_ => False
	})
})

eq_tup5 : Tuple.Tup5(a, b, c, d, e), Tuple.Tup5(a, b, c, d, e) -> Bool
eq_tup5 = |ex, ey| (match ex {
	MkTup5(exf0, exf1, exf2, exf3, exf4) => (match ey {
		MkTup5(eyf0, eyf1, eyf2, eyf3, eyf4) => (((((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2)) and (exf3 == eyf3)) and (exf4 == eyf4))
		_ => False
	})
})

eq_maybe : Maybe.Maybe(a), Maybe.Maybe(a) -> Bool
eq_maybe = |ex, ey| (match ex {
	Just(exf0) => (match ey {
		Just(eyf0) => (exf0 == eyf0)
		_ => False
	})
	None => (match ey {
		None => True
		_ => False
	})
})

eq_scheme : Scenery.Scheme, Scenery.Scheme -> Bool
eq_scheme = |ex, ey| (match ex {
	AllGreen => (match ey {
		AllGreen => True
		_ => False
	})
	YellowGreen => (match ey {
		YellowGreen => True
		_ => False
	})
	RedGreen => (match ey {
		RedGreen => True
		_ => False
	})
})

eq_creature : Scenery.Creature, Scenery.Creature -> Bool
eq_creature = |ex, ey| (match ex {
	NoCreature => (match ey {
		NoCreature => True
		_ => False
	})
	Elephant => (match ey {
		Elephant => True
		_ => False
	})
	Giraffe => (match ey {
		Giraffe => True
		_ => False
	})
	Zebra => (match ey {
		Zebra => True
		_ => False
	})
	Rhino => (match ey {
		Rhino => True
		_ => False
	})
	DuckPond => (match ey {
		DuckPond => True
		_ => False
	})
})

eq_kind : DepthSort.Kind, DepthSort.Kind -> Bool
eq_kind = |ex, ey| (match ex {
	KTree => (match ey {
		KTree => True
		_ => False
	})
	KTower => (match ey {
		KTower => True
		_ => False
	})
	KCow => (match ey {
		KCow => True
		_ => False
	})
	KCat => (match ey {
		KCat => True
		_ => False
	})
	KTruck => (match ey {
		KTruck => True
		_ => False
	})
	KRail => (match ey {
		KRail => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("td-box   ", box_got, box_want, 0.0))
	line!(Grade.grade_reals("td-bottom", bottom_got, bottom_want, 0.0))
	line!(Grade.grade_reals("td-axles ", axles_got, axles_want, 0.0))
	line!(Grade.grade_ints("td-naxle ", axle_count_got, axle_count_want))
	line!(Grade.grade_reals("td-face  ", face_got, face_want, 0.0))
	line!(Grade.grade_ints("td-carry ", face_carry_got, face_carry_want))
	line!(Grade.grade_ints("td-tied  ", tied_got, tied_want))
	line!(Grade.grade_ints("td-slack ", slack_got, slack_want))
	line!(Grade.grade_ints("td-small ", small_got, small_want))
	line!(Grade.grade_reals("td-halo  ", halo_got, halo_want, 0.0))
	line!(Grade.grade_ints("td-circle", circle_count_got, circle_count_want))
	line!(Grade.grade_bools("td-behind", behind_got, behind_want))
	Ok({})
}
