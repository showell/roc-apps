# PaintSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import Grade
import Paint
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

sp : F64, F64 -> Camera.ScreenPt
sp = |x, y| { x: x, y: y }

tri : List(Camera.ScreenPt)
tri = [sp(1.0, 2.0), sp(3.0, 4.0), sp(5.0, 6.0)]

two : List(Camera.ScreenPt)
two = [sp(1.0, 2.0), sp(3.0, 4.0)]

flat_got : List(F64)
flat_got = List.concat(Paint.flatten_screen(tri, 0), Paint.flatten_screen([], 0))

flat_want : List(F64)
flat_want = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

count_got : List(I64)
count_got = [U64.to_i64_wrap(List.len(Paint.push_poly(7, tri))), U64.to_i64_wrap(List.len(Paint.push_poly(7, two))), U64.to_i64_wrap(List.len(Paint.push_poly(7, []))), U64.to_i64_wrap(List.len(Paint.push_round_poly(7, 0.5, tri))), U64.to_i64_wrap(List.len(Paint.push_round_poly(7, 0.5, two))), U64.to_i64_wrap(List.len(Paint.push_grad_poly(7, 8, 0.0, 0.0, 1.0, tri))), U64.to_i64_wrap(List.len(Paint.push_grad_poly(7, 8, 0.0, 0.0, 1.0, two))), U64.to_i64_wrap(List.len(Paint.push_linear_grad_poly(7, 8, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, tri))), U64.to_i64_wrap(List.len(Paint.push_linear_grad_poly(7, 8, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, two))), U64.to_i64_wrap(List.len(Paint.push_radial_grad_poly(7, 8, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, tri))), U64.to_i64_wrap(List.len(Paint.push_radial_grad_poly(7, 8, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, two))), U64.to_i64_wrap(List.len(Paint.push_beacon(7, 1.0, 2.0, 3.0, 0.5)))]

count_want : List(I64)
count_want = [1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]

shape_of : List(Paint.DrawCmd) -> List(I64)
shape_of = |cs| ({
	c = (List.get(cs, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	[c.tag, c.color, c.color2, U64.to_i64_wrap(List.len(c.geom)), U64.to_i64_wrap(List.len(c.pts))]
})

solid : List(Paint.DrawCmd)
solid = Paint.push_poly(111, tri)

round : List(Paint.DrawCmd)
round = Paint.push_round_poly(222, 0.75, tri)

beacon : List(Paint.DrawCmd)
beacon = Paint.push_beacon(333, 10.0, 20.0, 30.0, 0.25)

radial4 : List(Paint.DrawCmd)
radial4 = Paint.push_grad_poly(444, 445, 10.0, 20.0, 30.0, tri)

linear5 : List(Paint.DrawCmd)
linear5 = Paint.push_linear_grad_poly(555, 556, 0.25, 0.75, 1.0, 2.0, 3.0, 4.0, tri)

radial6 : List(Paint.DrawCmd)
radial6 = Paint.push_radial_grad_poly(666, 667, 0.25, 0.75, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, tri)

tags_got : List(I64)
tags_got = List.concat(List.concat(List.concat(List.concat(List.concat(shape_of(solid), shape_of(round)), shape_of(beacon)), shape_of(radial4)), shape_of(linear5)), shape_of(radial6))

tags_want : List(I64)
tags_want = [0, 111, 0, 0, 6, 1, 222, 0, 0, 6, 3, 333, 0, 3, 0, 4, 444, 445, 3, 6, 5, 555, 556, 6, 6, 6, 666, 667, 8, 6]

strength_got : List(F64)
strength_got = [(List.get(solid, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).strength, (List.get(round, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).strength, (List.get(beacon, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).strength, (List.get(radial4, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).strength, (List.get(linear5, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).strength, (List.get(radial6, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).strength]

strength_want : List(F64)
strength_want = [0.0, 0.75, 0.25, 0.0, 0.0, 0.0]

geom_got : List(F64)
geom_got = List.concat(List.concat(List.concat((List.get(beacon, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).geom, (List.get(radial4, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).geom), (List.get(linear5, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).geom), (List.get(radial6, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).geom)

geom_want : List(F64)
geom_want = [10.0, 20.0, 30.0, 10.0, 20.0, 30.0, 0.25, 0.75, 1.0, 2.0, 3.0, 4.0, 0.25, 0.75, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

pts_got : List(F64)
pts_got = List.concat(List.concat((List.get(solid, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts, (List.get(radial6, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts), (List.get(beacon, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts)

pts_want : List(F64)
pts_want = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]

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
	line!(Grade.grade_reals("pa-flat  ", flat_got, flat_want, 0.0))
	line!(Grade.grade_ints("pa-guard ", count_got, count_want))
	line!(Grade.grade_ints("pa-tags  ", tags_got, tags_want))
	line!(Grade.grade_reals("pa-streng", strength_got, strength_want, 0.0))
	line!(Grade.grade_reals("pa-geom  ", geom_got, geom_want, 0.0))
	line!(Grade.grade_reals("pa-pts   ", pts_got, pts_want, 0.0))
	Ok({})
}
