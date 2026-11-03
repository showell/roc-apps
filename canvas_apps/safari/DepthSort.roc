# DepthSort -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import lib.DeviceMath
import ListUtils

DepthSort :: [].{
	# KBird is Roc's, and the reason this file is no longer an emission: the
	# Roc build has a bird on a treetop and the Codex program does not.
	Kind : [KTree, KTower, KCow, KCat, KTruck, KRail, KBird]

	## A thing to draw, as the sort sees it: how far ahead it is, and which it
	## is (its kind, and its place in that kind's list).
	DepthKey : { fwd : F64, kind : DepthSort.Kind, i : I64 }

	# rest builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	rest : List(item), I64 -> List(item)
	rest = |ys, j| rest_onto(ys, j, [])

	rest_onto : List(item), I64, List(item) -> List(item)
	rest_onto = |ys, j, acc| (
		if (j >= ys.len().to_i64_wrap()) {
			acc
		} else {
			rest_onto(ys, (j + 1), List.append(acc, (List.get(ys, I64.to_u64_wrap(j)) ?? crash ("list-at out of range"))))
		}
	)

	# merge_items builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	merge_items : List(item), List(item), I64, I64, (item -> F64) -> List(item)
	merge_items = |a, b, i, j, depth_of| merge_items_onto(a, b, i, j, depth_of, [])

	merge_items_onto : List(item), List(item), I64, I64, (item -> F64), List(item) -> List(item)
	merge_items_onto = |a, b, i, j, depth_of, acc| (
		if (i >= a.len().to_i64_wrap()) {
			List.concat(acc, rest(b, j))
		} else {
			(
				if (j >= b.len().to_i64_wrap()) {
					List.concat(acc, rest(a, i))
				} else {
					(
						if deeper_than(depth_of((List.get(b, I64.to_u64_wrap(j)) ?? crash ("list-at out of range"))), depth_of((List.get(a, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")))) {
							merge_items_onto(a, b, i, (j + 1), depth_of, List.append(acc, (List.get(b, I64.to_u64_wrap(j)) ?? crash ("list-at out of range"))))
						} else {
							merge_items_onto(a, b, (i + 1), j, depth_of, List.append(acc, (List.get(a, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))))
						}
					)
				}
			)
		}
	)

	sort_tie : F64
	sort_tie = F64.from_bits(4499125899939309867)

	deeper_than : F64, F64 -> Bool
	deeper_than = |x, y| ((x - y) > (sort_tie * DeviceMath.real_max(DeviceMath.real_abs(y), 1.0)))

	sort_by : List(item), (item -> F64) -> List(item)
	sort_by = |xs, depth_of| {
		n = xs.len().to_i64_wrap()
		if n <= 1 {
			xs
		} else {
			half = I64.div_trunc_by(n, 2)
			front = sort_by(ListUtils.list_take(xs, half), depth_of)
			back = sort_by(ListUtils.list_drop(xs, half), depth_of)
			merge_items(front, back, 0, 0, depth_of)
		}
	}

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
