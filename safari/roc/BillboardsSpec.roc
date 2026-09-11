# BillboardsSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Billboards
import Grade
import ListUtils
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fwd_in : List(F64)
fwd_in = [(-5.0), 0.3, 0.4, 0.5, 300.0, 342.0, 343.0, 400.0, 10.0, 50.0]

h_in : List(F64)
h_in = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.9]

placed_at : I64 -> Billboards.Placed
placed_at = |i| ({
	p = { right: 2.5, forward: (List.get(fwd_in, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) }
	Billboards.verdict(p, (List.get(h_in, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 128004, True)
})

# placed_all builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
placed_all : I64 -> List(Billboards.Placed)
placed_all = |i| placed_all_acc(i, [])

placed_all_acc : I64, List(Billboards.Placed) -> List(Billboards.Placed)
placed_all_acc = |i, acc| (if (i >= U64.to_i64_wrap(List.len(fwd_in))) { acc } else { placed_all_acc((i + 1), List.append(acc, placed_at(i))) })

kept_got : List(Bool)
kept_got = ListUtils.list_map(lam_0, placed_all(0))

kept_want : List(Bool)
kept_want = [False, False, False, True, True, True, False, False, False, True]

culled_got : List(Bool)
culled_got = ListUtils.list_map(lam_1, placed_all(0))

culled_want : List(Bool)
culled_want = [False, False, False, False, False, False, True, True, True, False]

carried_real_got : List(F64)
carried_real_got = ({
	k = placed_at(3)
	n = placed_at(1)
	[k.b.right, k.b.fwd, k.b.height, n.b.right, n.b.fwd, n.b.height]
})

carried_real_want : List(F64)
carried_real_want = [2.5, 0.5, 1.0, 0.0, 0.0, 0.0]

carried_int_got : List(I64)
carried_int_got = [placed_at(3).b.cp, placed_at(1).b.cp]

carried_int_want : List(I64)
carried_int_want = [128004, 0]

carried_bool_got : List(Bool)
carried_bool_got = [placed_at(3).b.face_right, placed_at(1).b.face_right]

carried_bool_want : List(Bool)
carried_bool_want = [True, False]

harvest_got : List(I64)
harvest_got = [U64.to_i64_wrap(List.len(Billboards.kept_of(placed_all(0), 0))), Billboards.size_culled_of(placed_all(0), 0), U64.to_i64_wrap(List.len(placed_all(0)))]

harvest_want : List(I64)
harvest_want = [4, 3, 10]

floor_got : List(F64)
floor_got = [Billboards.min_critter_px]

floor_want : List(F64)
floor_want = [2.0]

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

lam_0 : Billboards.Placed -> Bool
lam_0 = |p| p.kept

lam_1 : Billboards.Placed -> Bool
lam_1 = |p| p.size_culled

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_bools("bb-kept ", kept_got, kept_want))
	line!(Grade.grade_bools("bb-culled", culled_got, culled_want))
	line!(Grade.grade_reals("bb-carry", carried_real_got, carried_real_want, 0.0))
	line!(Grade.grade_ints("bb-cp   ", carried_int_got, carried_int_want))
	line!(Grade.grade_bools("bb-face ", carried_bool_got, carried_bool_want))
	line!(Grade.grade_ints("bb-count", harvest_got, harvest_want))
	line!(Grade.grade_reals("bb-floor", floor_got, floor_want, 0.0))
	Ok({})
}
