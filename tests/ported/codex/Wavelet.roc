# Wavelet -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Wavelet :: [].{
	DwtStepResult := { averages : List(I64), details : List(I64) }.{
		is_eq : Wavelet.DwtStepResult, Wavelet.DwtStepResult -> Bool
		is_eq = |a, b| a.averages == b.averages and a.details == b.details
	}

	dwt_forward : List(I64) -> List(I64)
	dwt_forward = |signal| ({
		n : I64
		n = U64.to_i64_wrap(List.len(signal))
		(if (n < 2) { signal } else { dwt_forward_levels(signal, n) })
	})

	dwt_forward_levels : List(I64), I64 -> List(I64)
	dwt_forward_levels = |data, len| (if (len < 2) { data } else { ({
		stepped : List(I64)
		stepped = dwt_forward_step(data, len)
		dwt_forward_levels(stepped, I64.div_trunc_by(len, 2))
	}) })

	dwt_forward_step : List(I64), I64 -> List(I64)
	dwt_forward_step = |data, len| ({
		half : I64
		half = I64.div_trunc_by(len, 2)
		result = dwt_fwd_pairs(data, half, 0, [], [])
		tail : List(I64)
		tail = dwt_copy_tail(data, len, U64.to_i64_wrap(List.len(data)), [])
		List.concat(List.concat(result.averages, result.details), tail)
	})

	dwt_fwd_pairs : List(I64), I64, I64, List(I64), List(I64) -> Wavelet.DwtStepResult
	dwt_fwd_pairs = |data, half, i, avgs, dets| (if (i >= half) { Wavelet.DwtStepResult.{ averages: avgs, details: dets } } else { ({
		a : I64
		a = (List.get(data, I64.to_u64_wrap((2 * i))) ?? crash("list-at out of range"))
		b : I64
		b = (List.get(data, I64.to_u64_wrap(((2 * i) + 1))) ?? crash("list-at out of range"))
		det : I64
		det = (a - b)
		avg : I64
		avg = (b + I64.div_trunc_by(det, 2))
		dwt_fwd_pairs(data, half, (i + 1), List.append(avgs, avg), List.append(dets, det))
	}) })

	dwt_copy_tail : List(I64), I64, I64, List(I64) -> List(I64)
	dwt_copy_tail = |data, start, len, acc| (if (start >= len) { acc } else { dwt_copy_tail(data, (start + 1), len, List.append(acc, (List.get(data, I64.to_u64_wrap(start)) ?? crash("list-at out of range")))) })

	dwt_inverse : List(I64) -> List(I64)
	dwt_inverse = |coeffs| ({
		n : I64
		n = U64.to_i64_wrap(List.len(coeffs))
		(if (n < 2) { coeffs } else { dwt_inverse_levels(coeffs, n, 2) })
	})

	dwt_inverse_levels : List(I64), I64, I64 -> List(I64)
	dwt_inverse_levels = |data, n, len| (if (len > n) { data } else { ({
		stepped : List(I64)
		stepped = dwt_inverse_step(data, len)
		dwt_inverse_levels(stepped, n, (len * 2))
	}) })

	dwt_inverse_step : List(I64), I64 -> List(I64)
	dwt_inverse_step = |data, len| ({
		half : I64
		half = I64.div_trunc_by(len, 2)
		result : List(I64)
		result = dwt_inv_pairs(data, half, 0, [])
		tail : List(I64)
		tail = dwt_copy_tail(data, len, U64.to_i64_wrap(List.len(data)), [])
		List.concat(result, tail)
	})

	dwt_inv_pairs : List(I64), I64, I64, List(I64) -> List(I64)
	dwt_inv_pairs = |data, half, i, acc| (if (i >= half) { acc } else { ({
		avg : I64
		avg = (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		det : I64
		det = (List.get(data, I64.to_u64_wrap((half + i))) ?? crash("list-at out of range"))
		b : I64
		b = (avg - I64.div_trunc_by(det, 2))
		a : I64
		a = (b + det)
		dwt_inv_pairs(data, half, (i + 1), List.append(List.append(acc, a), b))
	}) })

	dwt_denoise : List(I64), I64 -> List(I64)
	dwt_denoise = |signal, threshold| ({
		coeffs : List(I64)
		coeffs = dwt_forward(signal)
		thresholded : List(I64)
		thresholded = dwt_soft_threshold(coeffs, threshold, 0, U64.to_i64_wrap(List.len(coeffs)), [])
		dwt_inverse(thresholded)
	})

	dwt_soft_threshold : List(I64), I64, I64, I64, List(I64) -> List(I64)
	dwt_soft_threshold = |coeffs, threshold, i, len, acc| (if (i >= len) { acc } else { ({
		c : I64
		c = (List.get(coeffs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		abs_c : I64
		abs_c = (if (c < 0) { (0 - c) } else { c })
		t : I64
		t = (if (abs_c <= threshold) { 0 } else { (if (c > 0) { (c - threshold) } else { (c + threshold) }) })
		dwt_soft_threshold(coeffs, threshold, (i + 1), len, List.append(acc, t))
	}) })

	dwt_compress : List(I64), I64 -> List(I64)
	dwt_compress = |signal, keep_percent| ({
		coeffs : List(I64)
		coeffs = dwt_forward(signal)
		n : I64
		n = U64.to_i64_wrap(List.len(coeffs))
		dwt_sort_abs_v1 = dwt_sort_abs(coeffs, 0, n, [])
		sorted_abs : List(I64)
		sorted_abs = dwt_sort_abs_v1.0
		cutoff_idx : I64
		cutoff_idx = (n - I64.div_trunc_by((n * keep_percent), 100))
		threshold : I64
		threshold = (if (cutoff_idx >= n) { 0 } else { (List.get(sorted_abs, I64.to_u64_wrap(cutoff_idx)) ?? crash("list-at out of range")) })
		dwt_hard_threshold(coeffs, threshold, 0, n, [])
	})

	dwt_hard_threshold : List(I64), I64, I64, I64, List(I64) -> List(I64)
	dwt_hard_threshold = |coeffs, threshold, i, len, acc| (if (i >= len) { acc } else { ({
		c : I64
		c = (List.get(coeffs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		abs_c : I64
		abs_c = (if (c < 0) { (0 - c) } else { c })
		dwt_hard_threshold(coeffs, threshold, (i + 1), len, List.append(acc, (if (abs_c < threshold) { 0 } else { c })))
	}) })

	dwt_sort_abs : List(I64), I64, I64, List(I64) -> (List(I64), List(I64))
	dwt_sort_abs = |coeffs, i, len, acc| (if (i >= len) { ({
		dwt_insertion_sort_v1 : List(I64)
		dwt_insertion_sort_v1 = dwt_insertion_sort(acc, 0, U64.to_i64_wrap(List.len(acc)))
		(dwt_insertion_sort_v1, dwt_insertion_sort_v1)
	}) } else { ({
		c : I64
		c = (List.get(coeffs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		dwt_sort_abs_v2 = dwt_sort_abs(coeffs, (i + 1), len, List.append(acc, (if (c < 0) { (0 - c) } else { c })))
		(dwt_sort_abs_v2.0, acc)
	}) })

	dwt_insertion_sort : List(I64), I64, I64 -> List(I64)
	dwt_insertion_sort = |xs, i, len| (if (i >= len) { xs } else { ({
		dwt_insert_v1 : List(I64)
		dwt_insert_v1 = dwt_insert(xs, i)
		dwt_insertion_sort(dwt_insert_v1, (i + 1), len)
	}) })

	dwt_insert : List(I64), I64 -> List(I64)
	dwt_insert = |xs, i| (if (i <= 0) { xs } else { (if ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) < (List.get(xs, I64.to_u64_wrap((i - 1))) ?? crash("list-at out of range"))) { ({
		vi : I64
		vi = (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		xs_v1 : List(I64)
		xs_v1 = (List.set(xs, I64.to_u64_wrap(i), (List.get(xs, I64.to_u64_wrap((i - 1))) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		xs_v2 : List(I64)
		xs_v2 = (List.set(xs_v1, I64.to_u64_wrap((i - 1)), vi) ?? crash("list-set-at past the end"))
		dwt_insert(xs_v2, (i - 1))
	}) } else { xs }) })

	dwt_energy : List(I64) -> I64
	dwt_energy = |coeffs| dwt_energy_loop(coeffs, 0, U64.to_i64_wrap(List.len(coeffs)), 0)

	dwt_energy_loop : List(I64), I64, I64, I64 -> I64
	dwt_energy_loop = |coeffs, i, len, acc| (if (i >= len) { acc } else { ({
		c : I64
		c = (List.get(coeffs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		dwt_energy_loop(coeffs, (i + 1), len, (acc + I64.div_trunc_by((c * c), 1000)))
	}) })

	dwt_sparsity : List(I64) -> I64
	dwt_sparsity = |coeffs| ({
		n : I64
		n = U64.to_i64_wrap(List.len(coeffs))
		(if (n == 0) { 0 } else { ({
			zeros : I64
			zeros = dwt_count_zeros(coeffs, 0, n, 0)
			I64.div_trunc_by((zeros * 1000), n)
		}) })
	})

	dwt_count_zeros : List(I64), I64, I64, I64 -> I64
	dwt_count_zeros = |coeffs, i, len, acc| (if (i >= len) { acc } else { dwt_count_zeros(coeffs, (i + 1), len, (acc + (if ((List.get(coeffs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == 0) { 1 } else { 0 }))) })
}
