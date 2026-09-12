# Iterate -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Iterate :: [].{

	list_fold_indexed : List(a), b, (b, a, I64 -> b) -> b
	list_fold_indexed = |xs, init, f| list_fold_indexed_loop(xs, init, f, 0, U64.to_i64_wrap(List.len(xs)))

	list_fold_indexed_loop : List(a), b, (b, a, I64 -> b), I64, I64 -> b
	list_fold_indexed_loop = |xs, acc, f, i, len| (if (i >= len) { acc } else { list_fold_indexed_loop(xs, f(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), i), f, (i + 1), len) })

	list_map_generic : (a -> b), List(a) -> List(b)
	list_map_generic = |f, xs| list_map_generic_loop(f, xs, 0, U64.to_i64_wrap(List.len(xs)), [])

	list_map_generic_loop : (a -> b), List(a), I64, I64, List(b) -> List(b)
	list_map_generic_loop = |f, xs, i, len, acc| (if (i >= len) { acc } else { list_map_generic_loop(f, xs, (i + 1), len, List.append(acc, f((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	list_filter_generic : (a -> Bool), List(a) -> List(a)
	list_filter_generic = |pred, xs| list_filter_generic_loop(pred, xs, 0, U64.to_i64_wrap(List.len(xs)), [])

	list_filter_generic_loop : (a -> Bool), List(a), I64, I64, List(a) -> List(a)
	list_filter_generic_loop = |pred, xs, i, len, acc| (if (i >= len) { acc } else { ({
		x = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if pred(x) { list_filter_generic_loop(pred, xs, (i + 1), len, List.append(acc, x)) } else { list_filter_generic_loop(pred, xs, (i + 1), len, acc) })
	}) })

	list_find_index : (a -> Bool), List(a) -> I64
	list_find_index = |pred, xs| list_find_index_loop(pred, xs, 0, U64.to_i64_wrap(List.len(xs)))

	list_find_index_loop : (a -> Bool), List(a), I64, I64 -> I64
	list_find_index_loop = |pred, xs, i, len| (if (i >= len) { (-1) } else { (if pred((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { i } else { list_find_index_loop(pred, xs, (i + 1), len) }) })

	list_any_generic : (a -> Bool), List(a) -> Bool
	list_any_generic = |pred, xs| (list_find_index(pred, xs) >= 0)

	list_all_generic : (a -> Bool), List(a) -> Bool
	list_all_generic = |pred, xs| list_all_generic_loop(pred, xs, 0, U64.to_i64_wrap(List.len(xs)))

	list_all_generic_loop : (a -> Bool), List(a), I64, I64 -> Bool
	list_all_generic_loop = |pred, xs, i, len| (if (i >= len) { True } else { (if pred((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { list_all_generic_loop(pred, xs, (i + 1), len) } else { False }) })

	list_count_where : (a -> Bool), List(a) -> I64
	list_count_where = |pred, xs| list_count_where_loop(pred, xs, 0, U64.to_i64_wrap(List.len(xs)), 0)

	list_count_where_loop : (a -> Bool), List(a), I64, I64, I64 -> I64
	list_count_where_loop = |pred, xs, i, len, count| (if (i >= len) { count } else { (if pred((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { list_count_where_loop(pred, xs, (i + 1), len, (count + 1)) } else { list_count_where_loop(pred, xs, (i + 1), len, count) }) })

	list_take_generic : List(a), I64 -> List(a)
	list_take_generic = |xs, n| list_take_generic_loop(xs, 0, n, [])

	list_take_generic_loop : List(a), I64, I64, List(a) -> List(a)
	list_take_generic_loop = |xs, i, n, acc| (if (i >= n) { acc } else { (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { list_take_generic_loop(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	list_drop_generic : List(a), I64 -> List(a)
	list_drop_generic = |xs, n| list_drop_generic_loop(xs, n, U64.to_i64_wrap(List.len(xs)), [])

	list_drop_generic_loop : List(a), I64, I64, List(a) -> List(a)
	list_drop_generic_loop = |xs, i, len, acc| (if (i >= len) { acc } else { list_drop_generic_loop(xs, (i + 1), len, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	list_zip_with_generic : (a, b -> c), List(a), List(b) -> List(c)
	list_zip_with_generic = |f, xs, ys| ({
		len = (if (U64.to_i64_wrap(List.len(xs)) < U64.to_i64_wrap(List.len(ys))) { U64.to_i64_wrap(List.len(xs)) } else { U64.to_i64_wrap(List.len(ys)) })
		list_zip_loop(f, xs, ys, 0, len, [])
	})

	list_zip_loop : (a, b -> c), List(a), List(b), I64, I64, List(c) -> List(c)
	list_zip_loop = |f, xs, ys, i, len, acc| (if (i >= len) { acc } else { list_zip_loop(f, xs, ys, (i + 1), len, List.append(acc, f((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(ys, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })
}
