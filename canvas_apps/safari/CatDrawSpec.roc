# CatDrawSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Camera
import CatDraw
import CatStills
import Grade
import Stills

feet : Camera.ScreenPt
feet = { x: 100.0, y: 200.0 }

pt_got : List(F64)
pt_got = (
	{
		a = CatDraw.cat_pt(feet, 50.0, 0.0, { x: 0.5, y: 0.4 })
		b = CatDraw.cat_pt(feet, 50.0, 0.0, { x: 0.0, y: 0.0 })
		c = CatDraw.cat_pt(feet, 50.0, 0.0, { x: (-1.0), y: 1.0 })
		[a.x, a.y, b.x, b.y, c.x, c.y]
	}
)

pt_want : List(F64)
pt_want = [125.0, 180.0, 100.0, 200.0, 50.0, 150.0]

lift_got : List(F64)
lift_got = (
	{
		a = CatDraw.cat_pt(feet, 50.0, 0.2, { x: 0.5, y: 0.4 })
		b = CatDraw.cat_pt(feet, 100.0, 0.2, { x: 0.5, y: 0.4 })
		z = CatDraw.cat_pt(feet, 50.0, 0.0, { x: 0.5, y: 0.4 })
		[a.x, a.y, (z.y - a.y), b.y, (a.x - z.x)]
	}
)

lift_want : List(F64)
lift_want = [125.0, 170.0, 10.0, 140.0, 0.0]

pts_got : List(F64)
pts_got = (
	{
		ps = CatDraw.cat_pts(feet, 50.0, 0.0, [{ x: 0.0, y: 0.0 }, { x: 0.5, y: 0.4 }], 0)
		[I64.to_f64(ps.len().to_i64_wrap()), (List.get(ps, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(0)) ?? crash ("list-at out of range")).y, (List.get(ps, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).y]
	}
)

pts_want : List(F64)
pts_want = [2.0, 100.0, 200.0, 125.0, 180.0]

# many builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
many : I64 -> List(Stills.StillPt)
many = |n| many_onto(n, [])

many_onto : I64, List(Stills.StillPt) -> List(Stills.StillPt)
many_onto = |n, acc| (
	if (n <= 0) {
		acc
	} else {
		many_onto((n - 1), List.append(acc, { x: 0.0, y: 0.0 }))
	}
)

poly_of : I64 -> Stills.StillPoly
poly_of = |n| { color: 9, grad: [], pts: many(n) }

guard_got : List(I64)
guard_got = [CatDraw.max_cat_pts, CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(3)).len().to_i64_wrap(), CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(256)).len().to_i64_wrap(), CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(257)).len().to_i64_wrap(), CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(2)).len().to_i64_wrap()]

guard_want : List(I64)
guard_want = [256, 1, 1, 0, 0]

solid_got : List(I64)
solid_got = (
	{
		c = (List.get(CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(3)), I64.to_u64_wrap(0)) ?? crash ("list-at out of range"))
		[c.tag, c.color, c.color2, c.geom.len().to_i64_wrap(), c.pts.len().to_i64_wrap()]
	}
)

solid_want : List(I64)
solid_want = [0, 9, 0, 0, 6]

polys_got : List(I64)
polys_got = [CatDraw.cat_polys(feet, 50.0, 0.0, [poly_of(3), poly_of(4), poly_of(300)], 0).len().to_i64_wrap(), CatDraw.cat_polys(feet, 50.0, 0.0, [], 0).len().to_i64_wrap(), (List.get(CatDraw.cat_polys(feet, 50.0, 0.0, [poly_of(3), poly_of(4)], 0), I64.to_u64_wrap(1)) ?? crash ("list-at out of range")).pts.len().to_i64_wrap()]

polys_want : List(I64)
polys_want = [2, 0, 8]

drawn : F64, F64 -> I64
drawn = |forward, height| CatDraw.cat_draw(0.0, forward, height, 0, 0.0, 500.0, 960.0).len().to_i64_wrap()

size_got : List(I64)
size_got = [drawn(850.0, 1.7), drawn(851.0, 1.7), drawn(2000.0, 1.7)]

size_want : List(I64)
size_want = [CatStills.cat_polys_for(0).len().to_i64_wrap(), 0, 0]

count_got : List(I64)
count_got = [CatDraw.cat_draw(0.0, 100.0, 1.7, 0, 0.0, 500.0, 960.0).len().to_i64_wrap(), CatDraw.cat_draw(0.0, 100.0, 1.7, 0, 0.3, 500.0, 960.0).len().to_i64_wrap(), CatDraw.cat_draw(0.0, 100.0, 1.7, 2, 0.0, 500.0, 960.0).len().to_i64_wrap()]

count_want : List(I64)
count_want = [CatStills.cat_polys_for(0).len().to_i64_wrap(), CatStills.cat_polys_for(0).len().to_i64_wrap(), CatStills.cat_polys_for(2).len().to_i64_wrap()]

table_got : List(Bool)
table_got = [(CatStills.cat_polys_for(0).len().to_i64_wrap() > 0), (CatStills.cat_polys_for(1).len().to_i64_wrap() > 0), (CatStills.cat_polys_for(2).len().to_i64_wrap() > 0), (CatStills.cat_polys_for(3).len().to_i64_wrap() > 0), (CatStills.cat_polys_for(4).len().to_i64_wrap() > 0), (CatStills.cat_polys_for(5).len().to_i64_wrap() > 0), (CatStills.cat_polys_for(6).len().to_i64_wrap() > 0)]

table_want : List(Bool)
table_want = [True, True, True, True, True, True, True]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "cd-pt    ",
			got: pt_got,
			want: pt_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cd-lift  ",
			got: lift_got,
			want: lift_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "cd-pts   ",
			got: pts_got,
			want: pts_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "cd-guard ",
			got: guard_got,
			want: guard_want,
		}),
		Grade.ints({
			name: "cd-solid ",
			got: solid_got,
			want: solid_want,
		}),
		Grade.ints({
			name: "cd-polys ",
			got: polys_got,
			want: polys_want,
		}),
		Grade.ints({
			name: "cd-size  ",
			got: size_got,
			want: size_want,
		}),
		Grade.ints({
			name: "cd-count ",
			got: count_got,
			want: count_want,
		}),
		Grade.bools({
			name: "cd-table ",
			got: table_got,
			want: table_want,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
