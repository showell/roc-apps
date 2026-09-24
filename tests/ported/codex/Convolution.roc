# Convolution -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Convolution :: [].{

	convolve : List(I64), List(I64) -> List(I64)
	convolve = |signal, kernel| ({
		slen : I64
		slen = U64.to_i64_wrap(List.len(signal))
		klen : I64
		klen = U64.to_i64_wrap(List.len(kernel))
		conv_loop(signal, kernel, slen, klen, 0, [])
	})

	conv_loop : List(I64), List(I64), I64, I64, I64, List(I64) -> List(I64)
	conv_loop = |signal, kernel, slen, klen, i, acc| (if (i >= slen) { acc } else { ({
		val : I64
		val = conv_dot(signal, kernel, slen, klen, i, 0, 0)
		conv_loop(signal, kernel, slen, klen, (i + 1), List.append(acc, val))
	}) })

	conv_dot : List(I64), List(I64), I64, I64, I64, I64, I64 -> I64
	conv_dot = |signal, kernel, slen, klen, center, k, acc| (if (k >= klen) { I64.div_trunc_by(acc, 1000) } else { ({
		offset : I64
		offset = ((center - I64.div_trunc_by(klen, 2)) + k)
		sample : I64
		sample = (if (offset < 0) { 0 } else { (if (offset >= slen) { 0 } else { (List.get(signal, I64.to_u64_wrap(offset)) ?? crash("list-at out of range")) }) })
		conv_dot(signal, kernel, slen, klen, center, (k + 1), (acc + (sample * (List.get(kernel, I64.to_u64_wrap(k)) ?? crash("list-at out of range")))))
	}) })

	kernel_box_3 : List(I64)
	kernel_box_3 = [333, 333, 333]

	kernel_box_5 : List(I64)
	kernel_box_5 = [200, 200, 200, 200, 200]

	kernel_triangle_5 : List(I64)
	kernel_triangle_5 = [100, 250, 300, 250, 100]

	kernel_gaussian_5 : List(I64)
	kernel_gaussian_5 = [62, 244, 388, 244, 62]

	kernel_edge_3 : List(I64)
	kernel_edge_3 = [(0 - 1000), 2000, (0 - 1000)]

	kernel_diff_3 : List(I64)
	kernel_diff_3 = [(0 - 500), 0, 500]

	window_hamming : I64 -> List(I64)
	window_hamming = |n| window_hamming_loop(n, 0, [])

	window_hamming_loop : I64, I64, List(I64) -> List(I64)
	window_hamming_loop = |n, i, acc| (if (i >= n) { acc } else { ({
		denom : I64
		denom = (if (n <= 1) { 1 } else { (n - 1) })
		cos_val : I64
		cos_val = window_cos_approx(I64.div_trunc_by((i * 6283), denom))
		w : I64
		w = (540 - I64.div_trunc_by((460 * cos_val), 1000))
		window_hamming_loop(n, (i + 1), List.append(acc, w))
	}) })

	window_hanning : I64 -> List(I64)
	window_hanning = |n| window_hanning_loop(n, 0, [])

	window_hanning_loop : I64, I64, List(I64) -> List(I64)
	window_hanning_loop = |n, i, acc| (if (i >= n) { acc } else { ({
		denom : I64
		denom = (if (n <= 1) { 1 } else { (n - 1) })
		cos_val : I64
		cos_val = window_cos_approx(I64.div_trunc_by((i * 6283), denom))
		w : I64
		w = (500 - I64.div_trunc_by((500 * cos_val), 1000))
		window_hanning_loop(n, (i + 1), List.append(acc, w))
	}) })

	window_cos_approx : I64 -> I64
	window_cos_approx = |milli_rad| ({
		x2 : I64
		x2 = I64.div_trunc_by((milli_rad * milli_rad), 1000)
		x4 : I64
		x4 = I64.div_trunc_by((x2 * x2), 1000)
		((1000 - I64.div_trunc_by(x2, 2)) + I64.div_trunc_by(x4, 24))
	})

	apply_window : List(I64), List(I64) -> List(I64)
	apply_window = |signal, win| apply_window_loop(signal, win, 0, U64.to_i64_wrap(List.len(signal)), [])

	apply_window_loop : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	apply_window_loop = |signal, win, i, len, acc| (if (i >= len) { acc } else { apply_window_loop(signal, win, (i + 1), len, List.append(acc, I64.div_trunc_by(((List.get(signal, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * (List.get(win, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 1000))) })
}
