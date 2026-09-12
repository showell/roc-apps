# Sort -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Sort :: [].{
	SortPartition(a) : { list : List(a), pivot : I64 }

	sort_by : List(a), (a, a -> I64) -> List(a)
	sort_by = |xs, cmp| ({
		len = U64.to_i64_wrap(List.len(xs))
		(if (len <= 1) { xs } else { qsort_by(xs, cmp, 0, (len - 1)) })
	})

	qsort_by : List(a), (a, a -> I64), I64, I64 -> List(a)
	qsort_by = |xs, cmp, lo, hi| (if (lo >= hi) { xs } else { ({
		xs2 = sort_med3(xs, cmp, lo, (lo + I64.div_trunc_by((hi - lo), 2)), hi)
		pr = sort_partition(xs2, cmp, lo, hi, lo, (List.get(xs2, I64.to_u64_wrap(hi)) ?? crash("list-at out of range")))
		xs3 = qsort_by(pr.list, cmp, lo, (pr.pivot - 1))
		qsort_by(xs3, cmp, (pr.pivot + 1), hi)
	}) })

	sort_med3 : List(a), (a, a -> I64), I64, I64, I64 -> List(a)
	sort_med3 = |xs, cmp, a, b, c| ({
		va = (List.get(xs, I64.to_u64_wrap(a)) ?? crash("list-at out of range"))
		vb = (List.get(xs, I64.to_u64_wrap(b)) ?? crash("list-at out of range"))
		vc = (List.get(xs, I64.to_u64_wrap(c)) ?? crash("list-at out of range"))
		(if (cmp(va, vb) <= 0) { (if (cmp(vb, vc) <= 0) { sort_swap(xs, b, c) } else { (if (cmp(va, vc) <= 0) { xs } else { sort_swap(xs, a, c) }) }) } else { (if (cmp(va, vc) <= 0) { sort_swap(xs, a, c) } else { (if (cmp(vb, vc) <= 0) { xs } else { sort_swap(xs, b, c) }) }) })
	})

	sort_swap : List(a), I64, I64 -> List(a)
	sort_swap = |xs, i, j| (if (i == j) { xs } else { ({
		vi = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(List.set((List.set(xs, I64.to_u64_wrap(i), (List.get(xs, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end")), I64.to_u64_wrap(j), vi) ?? crash("list-set-at past the end"))
	}) })

	sort_partition : List(a), (a, a -> I64), I64, I64, I64, a -> Sort.SortPartition(a)
	sort_partition = |xs, cmp, j, hi, i, pv| (if (j >= hi) { ({
		xs2 = sort_swap(xs, i, hi)
		{ list: xs2, pivot: i }
	}) } else { (if (cmp((List.get(xs, I64.to_u64_wrap(j)) ?? crash("list-at out of range")), pv) < 0) { sort_partition(sort_swap(xs, i, j), cmp, (j + 1), hi, (i + 1), pv) } else { sort_partition(xs, cmp, (j + 1), hi, i, pv) }) })
}
