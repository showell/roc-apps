# LinearAlgebra -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import ListUtils
import Text

LinearAlgebra :: [].{
	Matrix : { mat_rows : I64, mat_cols : I64, mat_data : List(I64) }
	LuResult : { lu_lower : LinearAlgebra.Matrix, lu_upper : LinearAlgebra.Matrix, lu_pivot : List(I64) }

	mat_new : I64, I64 -> LinearAlgebra.Matrix
	mat_new = |rows, cols| { mat_rows: rows, mat_cols: cols, mat_data: mat_zeros((rows * cols), 0, []) }

	mat_identity : I64 -> LinearAlgebra.Matrix
	mat_identity = |n| { mat_rows: n, mat_cols: n, mat_data: mat_ident_data(n, 0, (n * n), []) }

	mat_from_list : I64, I64, List(I64) -> LinearAlgebra.Matrix
	mat_from_list = |rows, cols, data| { mat_rows: rows, mat_cols: cols, mat_data: data }

	mat_zeros : I64, I64, List(I64) -> List(I64)
	mat_zeros = |n, i, acc| (if (i >= n) { acc } else { mat_zeros(n, (i + 1), List.append(acc, 0)) })

	mat_ident_data : I64, I64, I64, List(I64) -> List(I64)
	mat_ident_data = |n, i, total, acc| (if (i >= total) { acc } else { ({
		row = I64.div_trunc_by(i, n)
		col = (i - (row * n))
		mat_ident_data(n, (i + 1), total, List.append(acc, (if (row == col) { 1000 } else { 0 })))
	}) })

	mat_get : LinearAlgebra.Matrix, I64, I64 -> I64
	mat_get = |m, row, col| (List.get(m.mat_data, I64.to_u64_wrap(((row * m.mat_cols) + col))) ?? crash("list-at out of range"))

	mat_set : LinearAlgebra.Matrix, I64, I64, I64 -> LinearAlgebra.Matrix
	mat_set = |m, row, col, val| { ..m, mat_data: (List.set(m.mat_data, I64.to_u64_wrap(((row * m.mat_cols) + col)), val) ?? crash("list-set-at past the end")) }

	mat_add : LinearAlgebra.Matrix, LinearAlgebra.Matrix -> LinearAlgebra.Matrix
	mat_add = |a, b| { mat_rows: a.mat_rows, mat_cols: a.mat_cols, mat_data: mat_zip_op(a.mat_data, b.mat_data, 0, U64.to_i64_wrap(List.len(a.mat_data)), [], 1) }

	mat_sub : LinearAlgebra.Matrix, LinearAlgebra.Matrix -> LinearAlgebra.Matrix
	mat_sub = |a, b| { mat_rows: a.mat_rows, mat_cols: a.mat_cols, mat_data: mat_zip_op(a.mat_data, b.mat_data, 0, U64.to_i64_wrap(List.len(a.mat_data)), [], 0) }

	mat_zip_op : List(I64), List(I64), I64, I64, List(I64), I64 -> List(I64)
	mat_zip_op = |a, b, i, len, acc, is_add| (if (i >= len) { acc } else { ({
		val = (if (is_add == 1) { ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) + (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) } else { ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) })
		mat_zip_op(a, b, (i + 1), len, List.append(acc, val), is_add)
	}) })

	mat_scale : LinearAlgebra.Matrix, I64 -> LinearAlgebra.Matrix
	mat_scale = |m, s| { mat_rows: m.mat_rows, mat_cols: m.mat_cols, mat_data: ListUtils.map_list(({
		dev__1 = s
		|dev__2| lam_0(dev__1, dev__2)
	}), m.mat_data) }

	mat_mul : LinearAlgebra.Matrix, LinearAlgebra.Matrix -> LinearAlgebra.Matrix
	mat_mul = |a, b| { mat_rows: a.mat_rows, mat_cols: b.mat_cols, mat_data: mat_mul_data(a, b, 0, (a.mat_rows * b.mat_cols), []) }

	mat_mul_data : LinearAlgebra.Matrix, LinearAlgebra.Matrix, I64, I64, List(I64) -> List(I64)
	mat_mul_data = |a, b, i, total, acc| (if (i >= total) { acc } else { ({
		row = I64.div_trunc_by(i, b.mat_cols)
		col = (i - (row * b.mat_cols))
		val = mat_dot_row_col(a, b, row, col, 0, a.mat_cols, 0)
		mat_mul_data(a, b, (i + 1), total, List.append(acc, val))
	}) })

	mat_dot_row_col : LinearAlgebra.Matrix, LinearAlgebra.Matrix, I64, I64, I64, I64, I64 -> I64
	mat_dot_row_col = |a, b, row, col, k, n, acc| (if (k >= n) { acc } else { ({
		val = I64.div_trunc_by((mat_get(a, row, k) * mat_get(b, k, col)), 1000)
		mat_dot_row_col(a, b, row, col, (k + 1), n, (acc + val))
	}) })

	mat_transpose : LinearAlgebra.Matrix -> LinearAlgebra.Matrix
	mat_transpose = |m| { mat_rows: m.mat_cols, mat_cols: m.mat_rows, mat_data: mat_trans_data(m, 0, (m.mat_rows * m.mat_cols), []) }

	mat_trans_data : LinearAlgebra.Matrix, I64, I64, List(I64) -> List(I64)
	mat_trans_data = |m, i, total, acc| (if (i >= total) { acc } else { ({
		new_row = I64.div_trunc_by(i, m.mat_rows)
		new_col = (i - (new_row * m.mat_rows))
		mat_trans_data(m, (i + 1), total, List.append(acc, mat_get(m, new_col, new_row)))
	}) })

	mat_det : LinearAlgebra.Matrix -> I64
	mat_det = |m| (if (m.mat_rows == 1) { mat_get(m, 0, 0) } else { (if (m.mat_rows == 2) { (I64.div_trunc_by((mat_get(m, 0, 0) * mat_get(m, 1, 1)), 1000) - I64.div_trunc_by((mat_get(m, 0, 1) * mat_get(m, 1, 0)), 1000)) } else { mat_det_expansion(m, 0, m.mat_cols, 0, 1) }) })

	mat_det_expansion : LinearAlgebra.Matrix, I64, I64, I64, I64 -> I64
	mat_det_expansion = |m, col, n, acc, sign| (if (col >= n) { acc } else { ({
		cofactor = I64.div_trunc_by((mat_get(m, 0, col) * mat_det(mat_minor(m, 0, col))), 1000)
		mat_det_expansion(m, (col + 1), n, (acc + (sign * cofactor)), (0 - sign))
	}) })

	mat_minor : LinearAlgebra.Matrix, I64, I64 -> LinearAlgebra.Matrix
	mat_minor = |m, skip_row, skip_col| ({
		n = (m.mat_rows - 1)
		{ mat_rows: n, mat_cols: n, mat_data: mat_minor_data(m, skip_row, skip_col, 0, 0, m.mat_rows, m.mat_cols, []) }
	})

	mat_minor_data : LinearAlgebra.Matrix, I64, I64, I64, I64, I64, I64, List(I64) -> List(I64)
	mat_minor_data = |m, sr, sc, r, c, rows, cols, acc| (if (r >= rows) { acc } else { (if (r == sr) { mat_minor_data(m, sr, sc, (r + 1), 0, rows, cols, acc) } else { (if (c >= cols) { mat_minor_data(m, sr, sc, (r + 1), 0, rows, cols, acc) } else { (if (c == sc) { mat_minor_data(m, sr, sc, r, (c + 1), rows, cols, acc) } else { mat_minor_data(m, sr, sc, r, (c + 1), rows, cols, List.append(acc, mat_get(m, r, c))) }) }) }) })

	mat_solve : LinearAlgebra.Matrix, List(I64) -> List(I64)
	mat_solve = |a, b| ({
		n = a.mat_rows
		aug = mat_augment(a, b)
		reduced = mat_forward_elim(aug, n, 0)
		mat_back_sub(reduced, n)
	})

	mat_augment : LinearAlgebra.Matrix, List(I64) -> LinearAlgebra.Matrix
	mat_augment = |m, b| ({
		cols = (m.mat_cols + 1)
		{ mat_rows: m.mat_rows, mat_cols: cols, mat_data: mat_aug_data(m, b, 0, m.mat_rows, []) }
	})

	mat_aug_data : LinearAlgebra.Matrix, List(I64), I64, I64, List(I64) -> List(I64)
	mat_aug_data = |m, b, row, n, acc| (if (row >= n) { acc } else { ({
		row_data = mat_copy_row(m, row, 0, m.mat_cols, [])
		mat_aug_data(m, b, (row + 1), n, List.concat(List.concat(acc, row_data), [(List.get(b, I64.to_u64_wrap(row)) ?? crash("list-at out of range"))]))
	}) })

	mat_copy_row : LinearAlgebra.Matrix, I64, I64, I64, List(I64) -> List(I64)
	mat_copy_row = |m, row, col, cols, acc| (if (col >= cols) { acc } else { mat_copy_row(m, row, (col + 1), cols, List.append(acc, mat_get(m, row, col))) })

	mat_forward_elim : LinearAlgebra.Matrix, I64, I64 -> LinearAlgebra.Matrix
	mat_forward_elim = |m, n, pivot| (if (pivot >= n) { m } else { ({
		m2 = mat_elim_column(m, n, pivot, (pivot + 1))
		mat_forward_elim(m2, n, (pivot + 1))
	}) })

	mat_elim_column : LinearAlgebra.Matrix, I64, I64, I64 -> LinearAlgebra.Matrix
	mat_elim_column = |m, n, pivot, row| (if (row >= n) { m } else { ({
		factor = I64.div_trunc_by((mat_get(m, row, pivot) * 1000), mat_get(m, pivot, pivot))
		m2 = mat_row_reduce(m, row, pivot, factor, m.mat_cols, 0)
		mat_elim_column(m2, n, pivot, (row + 1))
	}) })

	mat_row_reduce : LinearAlgebra.Matrix, I64, I64, I64, I64, I64 -> LinearAlgebra.Matrix
	mat_row_reduce = |m, row, pivot, factor, cols, col| (if (col >= cols) { m } else { ({
		val = (mat_get(m, row, col) - I64.div_trunc_by((factor * mat_get(m, pivot, col)), 1000))
		mat_row_reduce(mat_set(m, row, col, val), row, pivot, factor, cols, (col + 1))
	}) })

	mat_back_sub : LinearAlgebra.Matrix, I64 -> List(I64)
	mat_back_sub = |m, n| mat_back_loop(m, n, (n - 1), mat_zeros(n, 0, []))

	mat_back_loop : LinearAlgebra.Matrix, I64, I64, List(I64) -> List(I64)
	mat_back_loop = |m, n, row, x| (if (row < 0) { x } else { ({
		sum = mat_back_sum(m, x, row, (row + 1), n, 0)
		val = I64.div_trunc_by(((mat_get(m, row, n) - sum) * 1000), mat_get(m, row, row))
		mat_back_loop(m, n, (row - 1), (List.set(x, I64.to_u64_wrap(row), val) ?? crash("list-set-at past the end")))
	}) })

	mat_back_sum : LinearAlgebra.Matrix, List(I64), I64, I64, I64, I64 -> I64
	mat_back_sum = |m, x, row, col, n, acc| (if (col >= n) { acc } else { mat_back_sum(m, x, row, (col + 1), n, (acc + I64.div_trunc_by((mat_get(m, row, col) * (List.get(x, I64.to_u64_wrap(col)) ?? crash("list-at out of range"))), 1000))) })

	lam_0 : I64, I64 -> I64
	lam_0 = |s, v| I64.div_trunc_by((v * s), 1000)
}
