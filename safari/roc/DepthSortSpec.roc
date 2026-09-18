# DepthSortSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import DepthSort
import Grade
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mixed : List(DepthSort.Item)
mixed = [{ fwd: 30.0, kind: KTree, i: 0 }, { fwd: 10.0, kind: KCow, i: 1 }, { fwd: 30.0, kind: KRail, i: 2 }, { fwd: 50.0, kind: KTower, i: 3 }, { fwd: 10.0, kind: KCat, i: 4 }, { fwd: 20.0, kind: KTruck, i: 5 }, { fwd: 30.0, kind: KTree, i: 6 }, { fwd: 40.0, kind: KRail, i: 7 }, { fwd: 10.0, kind: KCow, i: 8 }, { fwd: 5.0, kind: KCat, i: 9 }]

# fwds builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
fwds : List(DepthSort.Item), I64 -> List(F64)
fwds = |xs, i| fwds_acc(xs, i, [])

fwds_acc : List(DepthSort.Item), I64, List(F64) -> List(F64)
fwds_acc = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { fwds_acc(xs, (i + 1), List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd)) })

# idxs builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
idxs : List(DepthSort.Item), I64 -> List(I64)
idxs = |xs, i| idxs_acc(xs, i, [])

idxs_acc : List(DepthSort.Item), I64, List(I64) -> List(I64)
idxs_acc = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { idxs_acc(xs, (i + 1), List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).i)) })

kind_code : DepthSort.Kind -> I64
kind_code = |k| (match k {
	KTree => 0
	KTower => 1
	KCow => 2
	KCat => 3
	KTruck => 4
	KRail => 5
})

# kinds builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
kinds : List(DepthSort.Item), I64 -> List(I64)
kinds = |xs, i| kinds_acc(xs, i, [])

kinds_acc : List(DepthSort.Item), I64, List(I64) -> List(I64)
kinds_acc = |xs, i, acc| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { kinds_acc(xs, (i + 1), List.append(acc, kind_code((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).kind))) })

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

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([22, 73, 16, 21, 22, 13, 21, 2], fwds(DepthSort.sort_items(mixed), 0), order_want, 0.0)))
	line!(Text.printed(Grade.grade_ints([22, 73, 19, 14, 15, 32, 23, 13], idxs(DepthSort.sort_items(mixed), 0), stable_want)))
	line!(Text.printed(Grade.grade_ints([22, 73, 34, 17, 18, 22, 2, 2], kinds(DepthSort.sort_items(mixed), 0), kind_want)))
	line!(Text.printed(Grade.grade_ints([22, 73, 19, 23, 15, 24, 34, 2], slack_got, slack_want)))
	Ok({})
}
