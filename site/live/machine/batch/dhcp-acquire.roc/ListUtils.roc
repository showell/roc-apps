# ListUtils -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

ListUtils :: [].{

	list_zeros : I64 -> List(I64)
	list_zeros = |n| list_zeros_loop(n, 0, [])

	list_zeros_loop : I64, I64, List(I64) -> List(I64)
	list_zeros_loop = |n, i, acc| (if (i >= n) { acc } else { list_zeros_loop(n, (i + 1), List.append(acc, 0)) })

	list_tail : List(a) -> List(a)
	list_tail = |xs| list_tail_loop(xs, 1, U64.to_i64_wrap(List.len(xs)), [])

	list_tail_loop : List(a), I64, I64, List(a) -> List(a)
	list_tail_loop = |xs, i, len, acc| (if (i >= len) { acc } else { list_tail_loop(xs, (i + 1), len, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	list_take : List(a), I64 -> List(a)
	list_take = |xs, n| list_take_loop(xs, 0, (if (n > U64.to_i64_wrap(List.len(xs))) { U64.to_i64_wrap(List.len(xs)) } else { n }), [])

	list_take_loop : List(a), I64, I64, List(a) -> List(a)
	list_take_loop = |xs, i, n, acc| (if (i >= n) { acc } else { list_take_loop(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	list_drop : List(a), I64 -> List(a)
	list_drop = |xs, n| list_tail_loop(xs, (if (n > U64.to_i64_wrap(List.len(xs))) { U64.to_i64_wrap(List.len(xs)) } else { n }), U64.to_i64_wrap(List.len(xs)), [])

	list_map : (a -> b), List(a) -> List(b)
	list_map = |f, xs| map_list(f, xs)

	map_list : (a -> b), List(a) -> List(b)
	map_list = |f, xs| map_list_loop(f, xs, 0, U64.to_i64_wrap(List.len(xs)), [])

	map_list_loop : (a -> b), List(a), I64, I64, List(b) -> List(b)
	map_list_loop = |f, xs, i, len, acc| (if (i == len) { acc } else { map_list_loop(f, xs, (i + 1), len, List.append(acc, f((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	fold_list : (a, b -> a), a, List(b) -> a
	fold_list = |f, z, xs| fold_list_loop(f, z, xs, 0, U64.to_i64_wrap(List.len(xs)))

	fold_list_loop : (a, b -> a), a, List(b), I64, I64 -> a
	fold_list_loop = |f, z, xs, i, len| (if (i == len) { z } else { fold_list_loop(f, f(z, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), xs, (i + 1), len) })

	list_filter : List(a), (a -> Bool) -> List(a)
	list_filter = |xs, pred| list_filter_loop(xs, pred, 0, U64.to_i64_wrap(List.len(xs)), [])

	list_filter_loop : List(a), (a -> Bool), I64, I64, List(a) -> List(a)
	list_filter_loop = |xs, pred, i, len, acc| (if (i >= len) { acc } else { ({
		x = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if pred(x) { list_filter_loop(xs, pred, (i + 1), len, List.append(acc, x)) } else { list_filter_loop(xs, pred, (i + 1), len, acc) })
	}) })

	list_contains : List(a), (a -> Bool) -> Bool
	list_contains = |xs, pred| list_contains_loop(xs, pred, 0, U64.to_i64_wrap(List.len(xs)))

	list_contains_loop : List(a), (a -> Bool), I64, I64 -> Bool
	list_contains_loop = |xs, pred, i, len| (if (i >= len) { False } else { (if pred((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { True } else { list_contains_loop(xs, pred, (i + 1), len) }) })

	list_remove : List(a), (a -> Bool) -> List(a)
	list_remove = |xs, pred| list_remove_loop(xs, pred, 0, U64.to_i64_wrap(List.len(xs)), [], False)

	list_remove_loop : List(a), (a -> Bool), I64, I64, List(a), Bool -> List(a)
	list_remove_loop = |xs, pred, i, len, acc, found| (if (i >= len) { acc } else { ({
		x = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if found { list_remove_loop(xs, pred, (i + 1), len, List.append(acc, x), True) } else { (if pred(x) { list_remove_loop(xs, pred, (i + 1), len, acc, True) } else { list_remove_loop(xs, pred, (i + 1), len, List.append(acc, x), False) }) })
	}) })
}
