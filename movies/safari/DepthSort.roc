# DepthSort -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import DeviceMath
import ListUtils

DepthSort :: [].{
	# KBird is Roc's, and the reason this file is no longer an emission: the
	# Roc build has a bird on a treetop and the Codex program does not.
	Kind : [KTree, KTower, KCow, KCat, KTruck, KRail, KBird]
	Item : { fwd : F64, kind : DepthSort.Kind, i : I64 }

	# rest_from builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	rest_from : List(DepthSort.Item), I64 -> List(DepthSort.Item)
	rest_from = |ys, j| rest_from_acc(ys, j, [])

	rest_from_acc : List(DepthSort.Item), I64, List(DepthSort.Item) -> List(DepthSort.Item)
	rest_from_acc = |ys, j, acc| (if (j >= U64.to_i64_wrap(List.len(ys))) { acc } else { rest_from_acc(ys, (j + 1), List.append(acc, (List.get(ys, I64.to_u64_wrap(j)) ?? crash("list-at out of range")))) })

	# merge_items builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	merge_items : List(DepthSort.Item), List(DepthSort.Item), I64, I64 -> List(DepthSort.Item)
	merge_items = |a, b, i, j| merge_items_acc(a, b, i, j, [])

	merge_items_acc : List(DepthSort.Item), List(DepthSort.Item), I64, I64, List(DepthSort.Item) -> List(DepthSort.Item)
	merge_items_acc = |a, b, i, j, acc| (if (i >= U64.to_i64_wrap(List.len(a))) { List.concat(acc, rest_from(b, j)) } else { (if (j >= U64.to_i64_wrap(List.len(b))) { List.concat(acc, rest_from(a, i)) } else { (if deeper_than((List.get(b, I64.to_u64_wrap(j)) ?? crash("list-at out of range")).fwd, (List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd) { merge_items_acc(a, b, i, (j + 1), List.append(acc, (List.get(b, I64.to_u64_wrap(j)) ?? crash("list-at out of range")))) } else { merge_items_acc(a, b, (i + 1), j, List.append(acc, (List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) }) })

	sort_tie : F64
	sort_tie = F64.from_bits(4499125899939309867)

	deeper_than : F64, F64 -> Bool
	deeper_than = |x, y| ((x - y) > (sort_tie * DeviceMath.real_max(DeviceMath.real_abs(y), 1.0)))

	sort_items : List(DepthSort.Item) -> List(DepthSort.Item)
	sort_items = |xs| (if (U64.to_i64_wrap(List.len(xs)) <= 1) { xs } else { merge_items(sort_items(ListUtils.list_take(xs, I64.div_trunc_by(U64.to_i64_wrap(List.len(xs)), 2))), sort_items(ListUtils.list_drop(xs, I64.div_trunc_by(U64.to_i64_wrap(List.len(xs)), 2))), 0, 0) })

	eq_Kind : DepthSort.Kind, DepthSort.Kind -> Bool
	eq_Kind = |ex, ey| (match ex {
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
		KBird => (match ey {
			KBird => True
			_ => False
		})
	})
}
