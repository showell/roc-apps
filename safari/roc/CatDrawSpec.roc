# CatDrawSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import CatDraw
import CatStills
import Grade
import Stills
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

feet : Camera.ScreenPt
feet = { x: 100.0, y: 200.0 }

pt_got : List(F64)
pt_got = ({
	a = CatDraw.cat_pt(feet, 50.0, 0.0, { x: 0.5, y: 0.4 })
	b = CatDraw.cat_pt(feet, 50.0, 0.0, { x: 0.0, y: 0.0 })
	c = CatDraw.cat_pt(feet, 50.0, 0.0, { x: (-1.0), y: 1.0 })
	[a.x, a.y, b.x, b.y, c.x, c.y]
})

pt_want : List(F64)
pt_want = [125.0, 180.0, 100.0, 200.0, 50.0, 150.0]

lift_got : List(F64)
lift_got = ({
	a = CatDraw.cat_pt(feet, 50.0, 0.2, { x: 0.5, y: 0.4 })
	b = CatDraw.cat_pt(feet, 100.0, 0.2, { x: 0.5, y: 0.4 })
	z = CatDraw.cat_pt(feet, 50.0, 0.0, { x: 0.5, y: 0.4 })
	[a.x, a.y, (z.y - a.y), b.y, (a.x - z.x)]
})

lift_want : List(F64)
lift_want = [125.0, 170.0, 10.0, 140.0, 0.0]

pts_got : List(F64)
pts_got = ({
	ps = CatDraw.cat_pts(feet, 50.0, 0.0, [{ x: 0.0, y: 0.0 }, { x: 0.5, y: 0.4 }], 0)
	[I64.to_f64(U64.to_i64_wrap(List.len(ps))), (List.get(ps, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).y, (List.get(ps, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).y]
})

pts_want : List(F64)
pts_want = [2.0, 100.0, 200.0, 125.0, 180.0]

# many builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
many : I64 -> List(Stills.StillPt)
many = |n| many_acc(n, [])

many_acc : I64, List(Stills.StillPt) -> List(Stills.StillPt)
many_acc = |n, acc| (if (n <= 0) { acc } else { many_acc((n - 1), List.append(acc, { x: 0.0, y: 0.0 })) })

poly_of : I64 -> Stills.StillPoly
poly_of = |n| { color: 9, grad: [], pts: many(n) }

guard_got : List(I64)
guard_got = [CatDraw.max_cat_pts, U64.to_i64_wrap(List.len(CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(3)))), U64.to_i64_wrap(List.len(CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(256)))), U64.to_i64_wrap(List.len(CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(257)))), U64.to_i64_wrap(List.len(CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(2))))]

guard_want : List(I64)
guard_want = [256, 1, 1, 0, 0]

solid_got : List(I64)
solid_got = ({
	c = (List.get(CatDraw.cat_poly(feet, 50.0, 0.0, poly_of(3)), I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	[c.tag, c.color, c.color2, U64.to_i64_wrap(List.len(c.geom)), U64.to_i64_wrap(List.len(c.pts))]
})

solid_want : List(I64)
solid_want = [0, 9, 0, 0, 6]

polys_got : List(I64)
polys_got = [U64.to_i64_wrap(List.len(CatDraw.cat_polys(feet, 50.0, 0.0, [poly_of(3), poly_of(4), poly_of(300)], 0))), U64.to_i64_wrap(List.len(CatDraw.cat_polys(feet, 50.0, 0.0, [], 0))), U64.to_i64_wrap(List.len((List.get(CatDraw.cat_polys(feet, 50.0, 0.0, [poly_of(3), poly_of(4)], 0), I64.to_u64_wrap(1)) ?? crash("list-at out of range")).pts))]

polys_want : List(I64)
polys_want = [2, 0, 8]

drawn : F64, F64 -> I64
drawn = |forward, height| U64.to_i64_wrap(List.len(CatDraw.cat_draw(0.0, forward, height, 0, 0.0, 500.0, 960.0)))

size_got : List(I64)
size_got = [drawn(850.0, 1.7), drawn(851.0, 1.7), drawn(2000.0, 1.7)]

size_want : List(I64)
size_want = [U64.to_i64_wrap(List.len(CatStills.cat_polys_for(0))), 0, 0]

count_got : List(I64)
count_got = [U64.to_i64_wrap(List.len(CatDraw.cat_draw(0.0, 100.0, 1.7, 0, 0.0, 500.0, 960.0))), U64.to_i64_wrap(List.len(CatDraw.cat_draw(0.0, 100.0, 1.7, 0, 0.3, 500.0, 960.0))), U64.to_i64_wrap(List.len(CatDraw.cat_draw(0.0, 100.0, 1.7, 2, 0.0, 500.0, 960.0)))]

count_want : List(I64)
count_want = [U64.to_i64_wrap(List.len(CatStills.cat_polys_for(0))), U64.to_i64_wrap(List.len(CatStills.cat_polys_for(0))), U64.to_i64_wrap(List.len(CatStills.cat_polys_for(2)))]

table_got : List(Bool)
table_got = [(U64.to_i64_wrap(List.len(CatStills.cat_polys_for(0))) > 0), (U64.to_i64_wrap(List.len(CatStills.cat_polys_for(1))) > 0), (U64.to_i64_wrap(List.len(CatStills.cat_polys_for(2))) > 0), (U64.to_i64_wrap(List.len(CatStills.cat_polys_for(3))) > 0), (U64.to_i64_wrap(List.len(CatStills.cat_polys_for(4))) > 0), (U64.to_i64_wrap(List.len(CatStills.cat_polys_for(5))) > 0), (U64.to_i64_wrap(List.len(CatStills.cat_polys_for(6))) > 0)]

table_want : List(Bool)
table_want = [True, True, True, True, True, True, True]

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

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("cd-pt    ", pt_got, pt_want, 0.0))
	line!(Grade.grade_reals("cd-lift  ", lift_got, lift_want, 0.0))
	line!(Grade.grade_reals("cd-pts   ", pts_got, pts_want, 0.0))
	line!(Grade.grade_ints("cd-guard ", guard_got, guard_want))
	line!(Grade.grade_ints("cd-solid ", solid_got, solid_want))
	line!(Grade.grade_ints("cd-polys ", polys_got, polys_want))
	line!(Grade.grade_ints("cd-size  ", size_got, size_want))
	line!(Grade.grade_ints("cd-count ", count_got, count_want))
	line!(Grade.grade_bools("cd-table ", table_got, table_want))
	Ok({})
}
