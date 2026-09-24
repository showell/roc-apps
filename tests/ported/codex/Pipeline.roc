# Pipeline -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Pipeline :: [].{

	pipe_map : (I64 -> I64), List(I64) -> List(I64)
	pipe_map = |f, xs| pipe_map_loop(f, xs, 0, U64.to_i64_wrap(List.len(xs)), [])

	pipe_map_loop : (I64 -> I64), List(I64), I64, I64, List(I64) -> List(I64)
	pipe_map_loop = |f, xs, i, n, acc| (if (i >= n) { acc } else { pipe_map_loop(f, xs, (i + 1), n, List.append(acc, f((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	pipe_filter : (I64 -> Bool), List(I64) -> List(I64)
	pipe_filter = |pred, xs| pipe_filter_loop(pred, xs, 0, U64.to_i64_wrap(List.len(xs)), [])

	pipe_filter_loop : (I64 -> Bool), List(I64), I64, I64, List(I64) -> List(I64)
	pipe_filter_loop = |pred, xs, i, n, acc| (if (i >= n) { acc } else { ({
		v : I64
		v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if pred(v) { pipe_filter_loop(pred, xs, (i + 1), n, List.append(acc, v)) } else { pipe_filter_loop(pred, xs, (i + 1), n, acc) })
	}) })

	pipe_reduce : (I64, I64 -> I64), I64, List(I64) -> I64
	pipe_reduce = |f, init, xs| pipe_reduce_loop(f, xs, init, 0, U64.to_i64_wrap(List.len(xs)))

	pipe_reduce_loop : (I64, I64 -> I64), List(I64), I64, I64, I64 -> I64
	pipe_reduce_loop = |f, xs, acc, i, n| (if (i >= n) { acc } else { pipe_reduce_loop(f, xs, f(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), (i + 1), n) })

	pipe_take : I64, List(I64) -> List(I64)
	pipe_take = |n, xs| pipe_take_loop(xs, 0, n, [])

	pipe_take_loop : List(I64), I64, I64, List(I64) -> List(I64)
	pipe_take_loop = |xs, i, n, acc| (if (i >= n) { acc } else { (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { pipe_take_loop(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	pipe_drop : I64, List(I64) -> List(I64)
	pipe_drop = |n, xs| pipe_drop_loop(xs, n, U64.to_i64_wrap(List.len(xs)), [])

	pipe_drop_loop : List(I64), I64, I64, List(I64) -> List(I64)
	pipe_drop_loop = |xs, i, len, acc| (if (i >= len) { acc } else { pipe_drop_loop(xs, (i + 1), len, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	pipe_take_while : (I64 -> Bool), List(I64) -> List(I64)
	pipe_take_while = |pred, xs| pipe_tw_loop(pred, xs, 0, U64.to_i64_wrap(List.len(xs)), [])

	pipe_tw_loop : (I64 -> Bool), List(I64), I64, I64, List(I64) -> List(I64)
	pipe_tw_loop = |pred, xs, i, n, acc| (if (i >= n) { acc } else { ({
		v : I64
		v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if pred(v) { pipe_tw_loop(pred, xs, (i + 1), n, List.append(acc, v)) } else { acc })
	}) })

	pipe_zip : List(I64), List(I64) -> List(I64)
	pipe_zip = |xs, ys| pipe_zip_loop(xs, ys, 0, pipe_min(U64.to_i64_wrap(List.len(xs)), U64.to_i64_wrap(List.len(ys))), [])

	pipe_zip_loop : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	pipe_zip_loop = |xs, ys, i, n, acc| (if (i >= n) { acc } else { pipe_zip_loop(xs, ys, (i + 1), n, List.append(List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), (List.get(ys, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	pipe_enumerate : List(I64) -> List(I64)
	pipe_enumerate = |xs| pipe_enum_loop(xs, 0, U64.to_i64_wrap(List.len(xs)), [])

	pipe_enum_loop : List(I64), I64, I64, List(I64) -> List(I64)
	pipe_enum_loop = |xs, i, n, acc| (if (i >= n) { acc } else { pipe_enum_loop(xs, (i + 1), n, List.append(List.append(acc, i), (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	pipe_partition : (I64 -> Bool), List(I64) -> List(I64)
	pipe_partition = |pred, xs| ({
		yes : List(I64)
		yes = pipe_filter(pred, xs)
		no : List(I64)
		no = pipe_filter(({
			dev__1 = pred
			|dev__2| lam_0(dev__1, dev__2)
		}), xs)
		List.concat(yes, no)
	})

	pipe_unique : List(I64) -> List(I64)
	pipe_unique = |xs| ({
		sorted : List(I64)
		sorted = pipe_sort(xs)
		pipe_dedup_adjacent(sorted, 0, U64.to_i64_wrap(List.len(sorted)), [])
	})

	pipe_dedup_adjacent : List(I64), I64, I64, List(I64) -> List(I64)
	pipe_dedup_adjacent = |xs, i, n, acc| (if (i >= n) { acc } else { ({
		v : I64
		v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (i > 0) { (if ((List.get(xs, I64.to_u64_wrap((i - 1))) ?? crash("list-at out of range")) == v) { pipe_dedup_adjacent(xs, (i + 1), n, acc) } else { pipe_dedup_adjacent(xs, (i + 1), n, List.append(acc, v)) }) } else { pipe_dedup_adjacent(xs, (i + 1), n, List.append(acc, v)) })
	}) })

	pipe_contains : List(I64), I64 -> Bool
	pipe_contains = |xs, val| pipe_cont_loop(xs, val, 0, U64.to_i64_wrap(List.len(xs)))

	pipe_cont_loop : List(I64), I64, I64, I64 -> Bool
	pipe_cont_loop = |xs, val, i, n| (if (i >= n) { False } else { (if ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == val) { True } else { pipe_cont_loop(xs, val, (i + 1), n) }) })

	pipe_scan : (I64, I64 -> I64), I64, List(I64) -> List(I64)
	pipe_scan = |f, init, xs| pipe_scan_loop(f, xs, init, 0, U64.to_i64_wrap(List.len(xs)), [init])

	pipe_scan_loop : (I64, I64 -> I64), List(I64), I64, I64, I64, List(I64) -> List(I64)
	pipe_scan_loop = |f, xs, acc, i, n, result| (if (i >= n) { result } else { ({
		new_acc : I64
		new_acc = f(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		pipe_scan_loop(f, xs, new_acc, (i + 1), n, List.append(result, new_acc))
	}) })

	pipe_sort : List(I64) -> List(I64)
	pipe_sort = |xs| ({
		n : I64
		n = U64.to_i64_wrap(List.len(xs))
		(if (n <= 1) { xs } else { ({
			mid : I64
			mid = I64.div_trunc_by(n, 2)
			left : List(I64)
			left = pipe_sort(pipe_take(mid, xs))
			right : List(I64)
			right = pipe_sort(pipe_drop(mid, xs))
			pipe_merge(left, right)
		}) })
	})

	# pipe_merge builds its list by appending a recursive call; emitted as an accumulator loop, which is linear where the direct shape is quadratic.
	pipe_merge : List(I64), List(I64) -> List(I64)
	pipe_merge = |left, right| pipe_merge_acc(left, right, [])

	pipe_merge_acc : List(I64), List(I64), List(I64) -> List(I64)
	pipe_merge_acc = |left, right, acc| (if (U64.to_i64_wrap(List.len(left)) == 0) { List.concat(acc, right) } else { (if (U64.to_i64_wrap(List.len(right)) == 0) { List.concat(acc, left) } else { ({
		l : I64
		l = (List.get(left, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		r : I64
		r = (List.get(right, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		(if (l <= r) { pipe_merge_acc(pipe_drop(1, left), right, List.append(acc, l)) } else { pipe_merge_acc(left, pipe_drop(1, right), List.append(acc, r)) })
	}) }) })

	pipe_reverse : List(I64) -> List(I64)
	pipe_reverse = |xs| pipe_rev_loop(xs, (U64.to_i64_wrap(List.len(xs)) - 1), [])

	pipe_rev_loop : List(I64), I64, List(I64) -> List(I64)
	pipe_rev_loop = |xs, i, acc| (if (i < 0) { acc } else { pipe_rev_loop(xs, (i - 1), List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	pipe_min : I64, I64 -> I64
	pipe_min = |a, b| (if (a < b) { a } else { b })

	pipe_sum : List(I64) -> I64
	pipe_sum = |xs| pipe_reduce(lam_1, 0, xs)

	pipe_product : List(I64) -> I64
	pipe_product = |xs| pipe_reduce(lam_2, 1, xs)

	pipe_any : (I64 -> Bool), List(I64) -> Bool
	pipe_any = |pred, xs| pipe_any_loop(pred, xs, 0, U64.to_i64_wrap(List.len(xs)))

	pipe_any_loop : (I64 -> Bool), List(I64), I64, I64 -> Bool
	pipe_any_loop = |pred, xs, i, n| (if (i >= n) { False } else { (if pred((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { True } else { pipe_any_loop(pred, xs, (i + 1), n) }) })

	pipe_all : (I64 -> Bool), List(I64) -> Bool
	pipe_all = |pred, xs| pipe_all_loop(pred, xs, 0, U64.to_i64_wrap(List.len(xs)))

	pipe_all_loop : (I64 -> Bool), List(I64), I64, I64 -> Bool
	pipe_all_loop = |pred, xs, i, n| (if (i >= n) { True } else { (if pred((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { pipe_all_loop(pred, xs, (i + 1), n) } else { False }) })

	pipe_count_where : (I64 -> Bool), List(I64) -> I64
	pipe_count_where = |pred, xs| U64.to_i64_wrap(List.len(pipe_filter(pred, xs)))

	lam_0 : (I64 -> Bool), I64 -> Bool
	lam_0 = |pred, x| (if pred(x) { False } else { True })

	lam_1 : I64, I64 -> I64
	lam_1 = |a, b| (a + b)

	lam_2 : I64, I64 -> I64
	lam_2 = |a, b| (a * b)
}
