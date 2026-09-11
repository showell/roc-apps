# CatStillsSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CatStills
import Grade
import Stills
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

pts_in : List(Stills.StillPoly), I64 -> I64
pts_in = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { 0 } else { ({
	p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	(U64.to_i64_wrap(List.len(p.pts)) + pts_in(ps, (i + 1)))
}) })

grads_in : List(Stills.StillPoly), I64 -> I64
grads_in = |ps, i| (if (i >= U64.to_i64_wrap(List.len(ps))) { 0 } else { ({
	p = (List.get(ps, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
	(U64.to_i64_wrap(List.len(p.grad)) + grads_in(ps, (i + 1)))
}) })

facts : List(Stills.StillPoly) -> List(I64)
facts = |ps| [U64.to_i64_wrap(List.len(ps)), pts_in(ps, 0), grads_in(ps, 0)]

pose_facts : I64 -> List(I64)
pose_facts = |i| facts(CatStills.cat_polys_for(i))

table_got : List(I64)
table_got = List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(pose_facts(0), pose_facts(1)), pose_facts(2)), pose_facts(3)), pose_facts(4)), pose_facts(5)), pose_facts(6)), pose_facts(7)), pose_facts((0 - 1)))

table_want : List(I64)
table_want = [46, 2198, 0, 46, 2198, 0, 47, 2197, 0, 34, 1715, 0, 34, 1715, 0, 34, 1715, 0, 34, 1715, 0, 0, 0, 0, 0, 0, 0]

first_x : I64 -> F64
first_x = |i| ({
	ps = CatStills.cat_polys_for(i)
	(List.get((List.get(ps, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).pts, I64.to_u64_wrap(0)) ?? crash("list-at out of range")).x
})

spot_got : List(F64)
spot_got = [first_x(3), first_x(4), first_x(5), first_x(6)]

spot_want : List(F64)
spot_want = [0.5062, 0.6873, 0.6467, 0.6377]

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
	line!(Grade.grade_ints("cs-table", table_got, table_want))
	line!(Grade.grade_reals("cs-spot ", spot_got, spot_want, 0.0))
	Ok({})
}
