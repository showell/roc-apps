# Statistics -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import ListUtils
import MathLib
import Sort

Statistics :: [].{

	stat_mean : List(I64) -> I64
	stat_mean = |xs| ({
		n : I64
		n = U64.to_i64_wrap(List.len(xs))
		(if (n == 0) { 0 } else { I64.div_trunc_by(stat_sum(xs, 0, n, 0), n) })
	})

	stat_median : List(I64) -> (I64, List(I64))
	stat_median = |xs| ({
		stat_sort_v1 = stat_sort(xs)
		xs_v2 : List(I64)
		xs_v2 = stat_sort_v1.1
		sorted : List(I64)
		sorted = stat_sort_v1.0
		n : I64
		n = U64.to_i64_wrap(List.len(sorted))
		(if (n == 0) { (0, xs_v2) } else { (if ((n - (I64.div_trunc_by(n, 2) * 2)) == 1) { ((List.get(sorted, I64.to_u64_wrap(I64.div_trunc_by(n, 2))) ?? crash("list-at out of range")), xs_v2) } else { (I64.div_trunc_by(((List.get(sorted, I64.to_u64_wrap((I64.div_trunc_by(n, 2) - 1))) ?? crash("list-at out of range")) + (List.get(sorted, I64.to_u64_wrap(I64.div_trunc_by(n, 2))) ?? crash("list-at out of range"))), 2), xs_v2) }) })
	})

	stat_mode : List(I64) -> (I64, List(I64))
	stat_mode = |xs| ({
		stat_sort_v1 = stat_sort(xs)
		xs_v2 : List(I64)
		xs_v2 = stat_sort_v1.1
		sorted : List(I64)
		sorted = stat_sort_v1.0
		(stat_mode_scan(sorted, 0, U64.to_i64_wrap(List.len(sorted)), 0, 0, 0, 0), xs_v2)
	})

	stat_mode_scan : List(I64), I64, I64, I64, I64, I64, I64 -> I64
	stat_mode_scan = |sorted, i, n, cur_val, cur_count, best_val, best_count| (if (i >= n) { (if (cur_count > best_count) { cur_val } else { best_val }) } else { ({
		val : I64
		val = (List.get(sorted, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (val == cur_val) { stat_mode_scan(sorted, (i + 1), n, cur_val, (cur_count + 1), best_val, best_count) } else { (if (cur_count > best_count) { stat_mode_scan(sorted, (i + 1), n, val, 1, cur_val, cur_count) } else { stat_mode_scan(sorted, (i + 1), n, val, 1, best_val, best_count) }) })
	}) })

	stat_variance : List(I64) -> I64
	stat_variance = |xs| ({
		n : I64
		n = U64.to_i64_wrap(List.len(xs))
		(if (n <= 1) { 0 } else { ({
			m : I64
			m = stat_mean(xs)
			I64.div_trunc_by(stat_var_sum(xs, m, 0, n, 0), (n - 1))
		}) })
	})

	stat_var_sum : List(I64), I64, I64, I64, I64 -> I64
	stat_var_sum = |xs, mean, i, n, acc| (if (i >= n) { acc } else { ({
		diff : I64
		diff = ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - mean)
		stat_var_sum(xs, mean, (i + 1), n, (acc + (diff * diff)))
	}) })

	stat_std_dev : List(I64) -> I64
	stat_std_dev = |xs| MathLib.math_isqrt(stat_variance(xs))

	stat_range : List(I64) -> I64
	stat_range = |xs| ({
		n : I64
		n = U64.to_i64_wrap(List.len(xs))
		(if (n == 0) { 0 } else { (stat_max_val(xs) - stat_min_val(xs)) })
	})

	stat_min_val : List(I64) -> I64
	stat_min_val = |xs| stat_fold_min(xs, 0, U64.to_i64_wrap(List.len(xs)), 999999999)

	stat_max_val : List(I64) -> I64
	stat_max_val = |xs| stat_fold_max(xs, 0, U64.to_i64_wrap(List.len(xs)), (0 - 999999999))

	stat_fold_min : List(I64), I64, I64, I64 -> I64
	stat_fold_min = |xs, i, n, best| (if (i >= n) { best } else { ({
		v : I64
		v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		stat_fold_min(xs, (i + 1), n, (if (v < best) { v } else { best }))
	}) })

	stat_fold_max : List(I64), I64, I64, I64 -> I64
	stat_fold_max = |xs, i, n, best| (if (i >= n) { best } else { ({
		v : I64
		v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		stat_fold_max(xs, (i + 1), n, (if (v > best) { v } else { best }))
	}) })

	stat_percentile : List(I64), I64 -> (I64, List(I64))
	stat_percentile = |xs, p| ({
		stat_sort_v1 = stat_sort(xs)
		xs_v2 : List(I64)
		xs_v2 = stat_sort_v1.1
		sorted : List(I64)
		sorted = stat_sort_v1.0
		n : I64
		n = U64.to_i64_wrap(List.len(sorted))
		(if (n == 0) { (0, xs_v2) } else { ({
			idx : I64
			idx = I64.div_trunc_by((p * (n - 1)), 100)
			((List.get(sorted, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")), xs_v2)
		}) })
	})

	stat_histogram : List(I64), I64 -> List(I64)
	stat_histogram = |xs, num_bins| ({
		lo : I64
		lo = stat_min_val(xs)
		hi : I64
		hi = stat_max_val(xs)
		range : I64
		range = ((hi - lo) + 1)
		bin_width : I64
		bin_width = (if (range <= num_bins) { 1 } else { (I64.div_trunc_by(range, num_bins) + 1) })
		stat_hist_fill(xs, lo, bin_width, num_bins, 0, U64.to_i64_wrap(List.len(xs)), ListUtils.list_zeros(num_bins))
	})

	stat_hist_fill : List(I64), I64, I64, I64, I64, I64, List(I64) -> List(I64)
	stat_hist_fill = |xs, lo, bin_width, num_bins, i, n, bins| (if (i >= n) { bins } else { ({
		val : I64
		val = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		bin : I64
		bin = I64.div_trunc_by((val - lo), bin_width)
		clamped : I64
		clamped = (if (bin >= num_bins) { (num_bins - 1) } else { (if (bin < 0) { 0 } else { bin }) })
		bins_v1 : List(I64)
		bins_v1 = (List.set(bins, I64.to_u64_wrap(clamped), ((List.get(bins, I64.to_u64_wrap(clamped)) ?? crash("list-at out of range")) + 1)) ?? crash("list-set-at past the end"))
		stat_hist_fill(xs, lo, bin_width, num_bins, (i + 1), n, bins_v1)
	}) })

	stat_correlation : List(I64), List(I64) -> I64
	stat_correlation = |xs, ys| ({
		n : I64
		n = MathLib.math_min(U64.to_i64_wrap(List.len(xs)), U64.to_i64_wrap(List.len(ys)))
		(if (n <= 1) { 0 } else { ({
			mx : I64
			mx = stat_mean(xs)
			my : I64
			my = stat_mean(ys)
			cov : I64
			cov = stat_covariance(xs, ys, mx, my, n)
			sx : I64
			sx = stat_std_dev(xs)
			sy : I64
			sy = stat_std_dev(ys)
			(if (sx == 0) { 0 } else { (if (sy == 0) { 0 } else { I64.div_trunc_by((I64.div_trunc_by((cov * 1000), sx) * 1000), sy) }) })
		}) })
	})

	stat_covariance : List(I64), List(I64), I64, I64, I64 -> I64
	stat_covariance = |xs, ys, mx, my, n| I64.div_trunc_by(stat_cov_loop(xs, ys, mx, my, 0, n, 0), (n - 1))

	stat_cov_loop : List(I64), List(I64), I64, I64, I64, I64, I64 -> I64
	stat_cov_loop = |xs, ys, mx, my, i, n, acc| (if (i >= n) { acc } else { stat_cov_loop(xs, ys, mx, my, (i + 1), n, (acc + (((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - mx) * ((List.get(ys, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - my)))) })

	stat_sum : List(I64), I64, I64, I64 -> I64
	stat_sum = |xs, i, n, acc| (if (i >= n) { acc } else { stat_sum(xs, (i + 1), n, (acc + (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	stat_count_where : List(I64), I64, I64 -> I64
	stat_count_where = |xs, lo, hi| stat_cw_loop(xs, lo, hi, 0, U64.to_i64_wrap(List.len(xs)), 0)

	stat_cw_loop : List(I64), I64, I64, I64, I64, I64 -> I64
	stat_cw_loop = |xs, lo, hi, i, n, acc| (if (i >= n) { acc } else { ({
		v : I64
		v = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		stat_cw_loop(xs, lo, hi, (i + 1), n, (if (v >= lo) { (if (v <= hi) { (acc + 1) } else { acc }) } else { acc }))
	}) })

	stat_sort : List(I64) -> (List(I64), List(I64))
	stat_sort = |xs| Sort.sort_by(xs, stat_compare)

	stat_compare : I64, I64 -> I64
	stat_compare = |a, b| (a - b)
}
