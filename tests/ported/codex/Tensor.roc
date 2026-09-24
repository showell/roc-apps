# Tensor -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

Tensor :: [].{
	Tensor : { data : List(I64), rows : I64, cols : I64 }

	tensor_new : I64, I64 -> Tensor.Tensor
	tensor_new = |rows, cols| { data: tensor_zeros((rows * cols), 0, []), rows: rows, cols: cols }

	tensor_from : I64, I64, List(I64) -> Tensor.Tensor
	tensor_from = |rows, cols, data| { data: data, rows: rows, cols: cols }

	tensor_zeros : I64, I64, List(I64) -> List(I64)
	tensor_zeros = |n, i, acc| (if (i >= n) { acc } else { tensor_zeros(n, (i + 1), List.append(acc, 0)) })

	tensor_vector : List(I64) -> Tensor.Tensor
	tensor_vector = |data| { data: data, rows: U64.to_i64_wrap(List.len(data)), cols: 1 }

	tensor_get : Tensor.Tensor, I64, I64 -> I64
	tensor_get = |t, row, col| (List.get(t.data, I64.to_u64_wrap(((row * t.cols) + col))) ?? crash("list-at out of range"))

	tensor_set : Tensor.Tensor, I64, I64, I64 -> Tensor.Tensor
	tensor_set = |t, row, col, val| { data: (List.set(t.data, I64.to_u64_wrap(((row * t.cols) + col)), val) ?? crash("list-set-at past the end")), rows: t.rows, cols: t.cols }

	tensor_matmul : Tensor.Tensor, Tensor.Tensor -> Tensor.Tensor
	tensor_matmul = |a, b| tensor_mm_build(a, b, 0, 0, [])

	tensor_mm_build : Tensor.Tensor, Tensor.Tensor, I64, I64, List(I64) -> Tensor.Tensor
	tensor_mm_build = |a, b, r, c, acc| (if (r >= a.rows) { { data: acc, rows: a.rows, cols: b.cols } } else { (if (c >= b.cols) { tensor_mm_build(a, b, (r + 1), 0, acc) } else { ({
		val = tensor_mm_dot(a, b, r, c, 0, 0)
		tensor_mm_build(a, b, r, (c + 1), List.append(acc, val))
	}) }) })

	tensor_mm_dot : Tensor.Tensor, Tensor.Tensor, I64, I64, I64, I64 -> I64
	tensor_mm_dot = |a, b, r, c, k, acc| (if (k >= a.cols) { acc } else { tensor_mm_dot(a, b, r, c, (k + 1), (acc + I64.div_trunc_by((tensor_get(a, r, k) * tensor_get(b, k, c)), 1000))) })

	tensor_add : Tensor.Tensor, Tensor.Tensor -> Tensor.Tensor
	tensor_add = |a, b| { data: tensor_ewise_add(a.data, b.data, 0, (a.rows * a.cols), []), rows: a.rows, cols: a.cols }

	tensor_ewise_add : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	tensor_ewise_add = |a, b, i, len, acc| (if (i >= len) { acc } else { tensor_ewise_add(a, b, (i + 1), len, List.append(acc, ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) + (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	tensor_scale : Tensor.Tensor, I64 -> Tensor.Tensor
	tensor_scale = |t, s| { data: tensor_scale_loop(t.data, s, 0, (t.rows * t.cols), []), rows: t.rows, cols: t.cols }

	tensor_scale_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	tensor_scale_loop = |data, s, i, len, acc| (if (i >= len) { acc } else { tensor_scale_loop(data, s, (i + 1), len, List.append(acc, I64.div_trunc_by(((List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * s), 1000))) })

	tensor_ewise_mul : Tensor.Tensor, Tensor.Tensor -> Tensor.Tensor
	tensor_ewise_mul = |a, b| { data: tensor_hadamard(a.data, b.data, 0, (a.rows * a.cols), []), rows: a.rows, cols: a.cols }

	tensor_hadamard : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	tensor_hadamard = |a, b, i, len, acc| (if (i >= len) { acc } else { tensor_hadamard(a, b, (i + 1), len, List.append(acc, I64.div_trunc_by(((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 1000))) })

	tensor_transpose : Tensor.Tensor -> Tensor.Tensor
	tensor_transpose = |t| tensor_trans_build(t, 0, 0, [])

	tensor_trans_build : Tensor.Tensor, I64, I64, List(I64) -> Tensor.Tensor
	tensor_trans_build = |t, r, c, acc| (if (r >= t.cols) { { data: acc, rows: t.cols, cols: t.rows } } else { (if (c >= t.rows) { tensor_trans_build(t, (r + 1), 0, acc) } else { tensor_trans_build(t, r, (c + 1), List.append(acc, tensor_get(t, c, r))) }) })

	tensor_dot : Tensor.Tensor, Tensor.Tensor -> I64
	tensor_dot = |a, b| tensor_dot_loop(a.data, b.data, 0, U64.to_i64_wrap(List.len(a.data)), 0)

	tensor_dot_loop : List(I64), List(I64), I64, I64, I64 -> I64
	tensor_dot_loop = |a, b, i, len, acc| (if (i >= len) { acc } else { tensor_dot_loop(a, b, (i + 1), len, (acc + I64.div_trunc_by(((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 1000))) })

	tensor_sum : Tensor.Tensor -> I64
	tensor_sum = |t| tensor_sum_loop(t.data, 0, U64.to_i64_wrap(List.len(t.data)), 0)

	tensor_sum_loop : List(I64), I64, I64, I64 -> I64
	tensor_sum_loop = |data, i, len, acc| (if (i >= len) { acc } else { tensor_sum_loop(data, (i + 1), len, (acc + (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	tensor_max : Tensor.Tensor -> I64
	tensor_max = |t| tensor_max_loop(t.data, 1, U64.to_i64_wrap(List.len(t.data)), (List.get(t.data, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))

	tensor_max_loop : List(I64), I64, I64, I64 -> I64
	tensor_max_loop = |data, i, len, best| (if (i >= len) { best } else { ({
		v = (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		tensor_max_loop(data, (i + 1), len, (if (v > best) { v } else { best }))
	}) })

	tensor_argmax : Tensor.Tensor -> I64
	tensor_argmax = |t| tensor_argmax_loop(t.data, 1, U64.to_i64_wrap(List.len(t.data)), 0, (List.get(t.data, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))

	tensor_argmax_loop : List(I64), I64, I64, I64, I64 -> I64
	tensor_argmax_loop = |data, i, len, best_idx, best_val| (if (i >= len) { best_idx } else { ({
		v = (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (v > best_val) { tensor_argmax_loop(data, (i + 1), len, i, v) } else { tensor_argmax_loop(data, (i + 1), len, best_idx, best_val) })
	}) })

	tensor_size : Tensor.Tensor -> I64
	tensor_size = |t| (t.rows * t.cols)

	tensor_shape : Tensor.Tensor -> CceText
	tensor_shape = |t| CceText.concat(CceText.concat(CceText.show_int(t.rows), "x"), CceText.show_int(t.cols))
}
