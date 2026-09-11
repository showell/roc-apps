# DepthSortSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DepthSort
import Grade
import Tuple

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mixed : List(DepthSort.Item)
mixed = [{ fwd: 30.0, kind: KTree, i: 0 }, { fwd: 10.0, kind: KCow, i: 1 }, { fwd: 30.0, kind: KRail, i: 2 }, { fwd: 50.0, kind: KTower, i: 3 }, { fwd: 10.0, kind: KCat, i: 4 }, { fwd: 20.0, kind: KTruck, i: 5 }, { fwd: 30.0, kind: KTree, i: 6 }, { fwd: 40.0, kind: KRail, i: 7 }, { fwd: 10.0, kind: KCow, i: 8 }, { fwd: 5.0, kind: KCat, i: 9 }]

fwds : List(DepthSort.Item), I64 -> List(F64)
fwds = |xs, i| (if (i >= U64.to_i64_wrap(List.len(xs))) { [] } else { List.concat([(List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd], fwds(xs, (i + 1))) })

idxs : List(DepthSort.Item), I64 -> List(I64)
idxs = |xs, i| (if (i >= U64.to_i64_wrap(List.len(xs))) { [] } else { List.concat([(List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).i], idxs(xs, (i + 1))) })

kind_code : DepthSort.Kind -> I64
kind_code = |k| (match k {
	KTree => 0
	KTower => 1
	KCow => 2
	KCat => 3
	KTruck => 4
	KRail => 5
})

kinds : List(DepthSort.Item), I64 -> List(I64)
kinds = |xs, i| (if (i >= U64.to_i64_wrap(List.len(xs))) { [] } else { List.concat([kind_code((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).kind)], kinds(xs, (i + 1))) })

order_want : List(F64)
order_want = [50.0, 40.0, 30.0, 30.0, 30.0, 20.0, 10.0, 10.0, 10.0, 5.0]

stable_want : List(I64)
stable_want = [3, 7, 0, 2, 6, 5, 1, 4, 8, 9]

kind_want : List(I64)
kind_want = [1, 5, 0, 5, 0, 4, 2, 3, 2, 3]

tie_near : List(DepthSort.Item)
tie_near = [{ fwd: 100.0, kind: KTree, i: 0 }, { fwd: 100.000004, kind: KTree, i: 1 }]

tie_far : List(DepthSort.Item)
tie_far = [{ fwd: 100.0, kind: KTree, i: 0 }, { fwd: 100.00001, kind: KTree, i: 1 }]

zero_near : List(DepthSort.Item)
zero_near = [{ fwd: 0.5, kind: KTree, i: 0 }, { fwd: 0.50000004, kind: KTree, i: 1 }]

zero_far : List(DepthSort.Item)
zero_far = [{ fwd: 0.5, kind: KTree, i: 0 }, { fwd: 0.5000001, kind: KTree, i: 1 }]

slack_got : List(I64)
slack_got = List.concat(List.concat(List.concat(idxs(DepthSort.sort_items(tie_near), 0), idxs(DepthSort.sort_items(tie_far), 0)), idxs(DepthSort.sort_items(zero_near), 0)), idxs(DepthSort.sort_items(zero_far), 0))

slack_want : List(I64)
slack_want = [0, 1, 1, 0, 0, 1, 1, 0]

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
	line!(Grade.grade_reals("d-order ", fwds(DepthSort.sort_items(mixed), 0), order_want, 0.0))
	line!(Grade.grade_ints("d-stable", idxs(DepthSort.sort_items(mixed), 0), stable_want))
	line!(Grade.grade_ints("d-kind  ", kinds(DepthSort.sort_items(mixed), 0), kind_want))
	line!(Grade.grade_ints("d-slack ", slack_got, slack_want))
	Ok({})
}
