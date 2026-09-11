# DepthSort -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DeviceMath
import ListUtils

DepthSort :: [].{
	Kind : [KTree, KTower, KCow, KCat, KTruck, KRail]
	Item : { fwd : F64, kind : DepthSort.Kind, i : I64 }

	rest_from : List(DepthSort.Item), I64 -> List(DepthSort.Item)
	rest_from = |ys, j| (if (j >= U64.to_i64_wrap(List.len(ys))) { [] } else { List.concat([(List.get(ys, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))], rest_from(ys, (j + 1))) })

	merge_items : List(DepthSort.Item), List(DepthSort.Item), I64, I64 -> List(DepthSort.Item)
	merge_items = |a, b, i, j| (if (i >= U64.to_i64_wrap(List.len(a))) { rest_from(b, j) } else { (if (j >= U64.to_i64_wrap(List.len(b))) { rest_from(a, i) } else { (if deeper_than((List.get(b, I64.to_u64_wrap(j)) ?? crash("list-at out of range")).fwd, (List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).fwd) { List.concat([(List.get(b, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))], merge_items(a, b, i, (j + 1))) } else { List.concat([(List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))], merge_items(a, b, (i + 1), j)) }) }) })

	sort_tie : F64
	sort_tie = F64.from_bits(4499125899939309867)

	deeper_than : F64, F64 -> Bool
	deeper_than = |x, y| ((x - y) > (sort_tie * DeviceMath.real_max(DeviceMath.real_abs(y), 1.0)))

	sort_items : List(DepthSort.Item) -> List(DepthSort.Item)
	sort_items = |xs| (if (U64.to_i64_wrap(List.len(xs)) <= 1) { xs } else { merge_items(sort_items(ListUtils.list_take(xs, I64.div_trunc_by(U64.to_i64_wrap(List.len(xs)), 2))), sort_items(ListUtils.list_drop(xs, I64.div_trunc_by(U64.to_i64_wrap(List.len(xs)), 2))), 0, 0) })
}
