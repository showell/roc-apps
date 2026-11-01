# ListUtils -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).

ListUtils :: [].{

	list_zeros : I64 -> List(I64)
	list_zeros = |n| list_zeros_onto(n, 0, [])

	list_zeros_onto : I64, I64, List(I64) -> List(I64)
	list_zeros_onto = |n, i, acc| (
		if (i >= n) {
			acc
		} else {
			list_zeros_onto(n, (i + 1), List.append(acc, 0))
		}
	)

	list_tail : List(a) -> List(a)
	list_tail = |xs| list_tail_onto(xs, 1, xs.len().to_i64_wrap(), [])

	list_tail_onto : List(a), I64, I64, List(a) -> List(a)
	list_tail_onto = |xs, i, len, acc| (
		if (i >= len) {
			acc
		} else {
			list_tail_onto(xs, (i + 1), len, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))))
		}
	)

	list_take : List(a), I64 -> List(a)
	list_take = |xs, n| list_take_onto(
		xs,
		0,
		(
			if (n > xs.len().to_i64_wrap()) {
				xs.len().to_i64_wrap()
			} else {
				n
			}
		),
		[],
	)

	list_take_onto : List(a), I64, I64, List(a) -> List(a)
	list_take_onto = |xs, i, n, acc| (
		if (i >= n) {
			acc
		} else {
			list_take_onto(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))))
		}
	)

	list_drop : List(a), I64 -> List(a)
	list_drop = |xs, n| list_tail_onto(
		xs,
		(
			if (n > xs.len().to_i64_wrap()) {
				xs.len().to_i64_wrap()
			} else {
				n
			}
		),
		xs.len().to_i64_wrap(),
		[],
	)

	list_map : (a -> b), List(a) -> List(b)
	list_map = |f, xs| map_list(f, xs)

	map_list : (a -> b), List(a) -> List(b)
	map_list = |f, xs| map_list_onto(f, xs, 0, xs.len().to_i64_wrap(), [])

	map_list_onto : (a -> b), List(a), I64, I64, List(b) -> List(b)
	map_list_onto = |f, xs, i, len, acc| (
		if (i == len) {
			acc
		} else {
			map_list_onto(f, xs, (i + 1), len, List.append(acc, f((List.get(xs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range")))))
		}
	)

	fold_list : (a, b -> a), a, List(b) -> a
	fold_list = |f, z, xs| fold_list_from(f, z, xs, 0, xs.len().to_i64_wrap())

	fold_list_from : (a, b -> a), a, List(b), I64, I64 -> a
	fold_list_from = |f, z, xs, i, len| (
		if (i == len) {
			z
		} else {
			fold_list_from(f, f(z, (List.get(xs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))), xs, (i + 1), len)
		}
	)

	list_filter : List(a), (a -> Bool) -> List(a)
	list_filter = |xs, pred| list_filter_onto(xs, pred, 0, xs.len().to_i64_wrap(), [])

	list_filter_onto : List(a), (a -> Bool), I64, I64, List(a) -> List(a)
	list_filter_onto = |xs, pred, i, len, acc| (
		if (i >= len) {
			acc
		} else {
			(
				{
					x = (List.get(xs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))
					(
						if pred(x) {
							list_filter_onto(xs, pred, (i + 1), len, List.append(acc, x))
						} else {
							list_filter_onto(xs, pred, (i + 1), len, acc)
						}
					)
				}
			)
		}
	)

	list_contains : List(a), (a -> Bool) -> Bool
	list_contains = |xs, pred| list_contains_from(xs, pred, 0, xs.len().to_i64_wrap())

	list_contains_from : List(a), (a -> Bool), I64, I64 -> Bool
	list_contains_from = |xs, pred, i, len| (
		if (i >= len) {
			False
		} else {
			(
				if pred((List.get(xs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))) {
					True
				} else {
					list_contains_from(xs, pred, (i + 1), len)
				}
			)
		}
	)

	list_remove : List(a), (a -> Bool) -> List(a)
	list_remove = |xs, pred| list_remove_onto(xs, pred, 0, xs.len().to_i64_wrap(), [], False)

	list_remove_onto : List(a), (a -> Bool), I64, I64, List(a), Bool -> List(a)
	list_remove_onto = |xs, pred, i, len, acc, found| (
		if (i >= len) {
			acc
		} else {
			(
				{
					x = (List.get(xs, I64.to_u64_wrap(i)) ?? crash ("list-at out of range"))
					(
						if found {
							list_remove_onto(xs, pred, (i + 1), len, List.append(acc, x), True)
						} else {
							(
								if pred(x) {
									list_remove_onto(xs, pred, (i + 1), len, acc, True)
								} else {
									list_remove_onto(xs, pred, (i + 1), len, List.append(acc, x), False)
								}
							)
						}
					)
				}
			)
		}
	)
}
