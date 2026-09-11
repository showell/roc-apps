# CritterSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Camera
import Critter
import EmojiStills
import Grade
import Stills
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

facing_got : List(F64)
facing_got = [Critter.facing(True), Critter.facing(False)]

facing_want : List(F64)
facing_want = [(-1.0), 1.0]

feet : Camera.ScreenPt
feet = { x: 100.0, y: 200.0 }

point_got : List(F64)
point_got = ({
	a = Critter.map_p(feet, 1.0, 50.0, 0.5, 0.4)
	b = Critter.map_p(feet, (0.0 - 1.0), 50.0, 0.5, 0.4)
	c = Critter.map_p(feet, 1.0, 50.0, 0.0, 0.0)
	[a.x, a.y, b.x, b.y, c.x, c.y]
})

point_want : List(F64)
point_want = [125.0, 180.0, 75.0, 180.0, 100.0, 200.0]

vector_got : List(F64)
vector_got = ({
	a = Critter.map_v(1.0, 50.0, 0.5, 0.4)
	b = Critter.map_v((0.0 - 1.0), 50.0, 0.5, 0.4)
	c = Critter.map_v(1.0, 50.0, 0.0, 0.0)
	[a.x, a.y, b.x, b.y, c.x, c.y]
})

vector_want : List(F64)
vector_want = [25.0, (-20.0), (-25.0), (-20.0), 0.0, 0.0]

anchor_got : List(F64)
anchor_got = ({
	p = Critter.map_p(feet, 1.0, 50.0, 0.5, 0.4)
	v = Critter.map_v(1.0, 50.0, 0.5, 0.4)
	[(p.x - v.x), (p.y - v.y)]
})

anchor_want : List(F64)
anchor_want = [100.0, 200.0]

mapped_got : List(F64)
mapped_got = ({
	ps = Critter.mapped_pts(feet, 1.0, 50.0, [{ x: 0.0, y: 0.0 }, { x: 0.5, y: 0.4 }, { x: 1.0, y: 1.0 }], 0)
	[I64.to_f64(U64.to_i64_wrap(List.len(ps))), (List.get(ps, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).y, (List.get(ps, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(1)) ?? crash("list-at out of range")).y, (List.get(ps, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).x, (List.get(ps, I64.to_u64_wrap(2)) ?? crash("list-at out of range")).y]
})

mapped_want : List(F64)
mapped_want = [3.0, 100.0, 200.0, 125.0, 180.0, 150.0, 150.0]

# many builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
many : I64 -> List(Stills.StillPt)
many = |n| many_acc(n, [])

many_acc : I64, List(Stills.StillPt) -> List(Stills.StillPt)
many_acc = |n, acc| (if (n <= 0) { acc } else { many_acc((n - 1), List.append(acc, { x: 0.0, y: 0.0 })) })

flat_poly : I64 -> Stills.StillPoly
flat_poly = |n| { color: 7, grad: [], pts: many(n) }

guard_got : List(I64)
guard_got = [Critter.max_critter_pts, U64.to_i64_wrap(List.len(Critter.critter_poly(feet, 1.0, 50.0, flat_poly(3)))), U64.to_i64_wrap(List.len(Critter.critter_poly(feet, 1.0, 50.0, flat_poly(512)))), U64.to_i64_wrap(List.len(Critter.critter_poly(feet, 1.0, 50.0, flat_poly(513)))), U64.to_i64_wrap(List.len(Critter.critter_poly(feet, 1.0, 50.0, flat_poly(2))))]

guard_want : List(I64)
guard_want = [512, 1, 1, 0, 0]

solid_got : List(I64)
solid_got = ({
	c = (List.get(Critter.critter_poly(feet, 1.0, 50.0, flat_poly(3)), I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
	[c.tag, c.color, U64.to_i64_wrap(List.len(c.pts))]
})

solid_want : List(I64)
solid_want = [0, 7, 6]

drawn : F64, F64 -> I64
drawn = |forward, height| U64.to_i64_wrap(List.len(Critter.critter_draw(0.0, forward, height, 128024, False, 500.0, 960.0)))

size_got : List(I64)
size_got = [drawn(1000.0, 2.0), drawn(2000.0, 2.0), drawn(1000.0, 1.9), drawn(100.0, 2.0)]

size_want : List(I64)
size_want = [6, 0, 0, 6]

unknown_got : List(I64)
unknown_got = [U64.to_i64_wrap(List.len(EmojiStills.emoji_polys_for(1))), U64.to_i64_wrap(List.len(Critter.critter_draw(0.0, 100.0, 2.0, 1, False, 500.0, 960.0))), U64.to_i64_wrap(List.len(EmojiStills.emoji_polys_for(128024)))]

unknown_want : List(I64)
unknown_want = [0, 0, 6]

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
	line!(Grade.grade_reals("cr-facing", facing_got, facing_want, 0.0))
	line!(Grade.grade_reals("cr-point ", point_got, point_want, 0.0))
	line!(Grade.grade_reals("cr-vector", vector_got, vector_want, 0.0))
	line!(Grade.grade_reals("cr-anchor", anchor_got, anchor_want, 0.0))
	line!(Grade.grade_reals("cr-mapped", mapped_got, mapped_want, 0.0))
	line!(Grade.grade_ints("cr-guard ", guard_got, guard_want))
	line!(Grade.grade_ints("cr-solid ", solid_got, solid_want))
	line!(Grade.grade_ints("cr-size  ", size_got, size_want))
	line!(Grade.grade_ints("cr-unknwn", unknown_got, unknown_want))
	Ok({})
}
