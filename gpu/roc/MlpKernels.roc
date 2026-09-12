# MlpKernels -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Device

MlpKernels :: [].{

	kernel_matmul_relu : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	kernel_matmul_relu = |dev, weights, input, bias, output, rows, cols| ({
		(dev1, row) = Device.thread_idx_x(dev)
		(if (row < rows) { mlp_matmul_relu_row(dev1, weights, input, bias, output, row, cols) } else { (dev1, 0) })
	})

	mlp_matmul_relu_row : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_matmul_relu_row = |dev, weights, input, bias, output, row, cols| ({
		(dev1, sum) = mlp_dot_row(dev, weights, input, bias, row, cols)
		activated = (if (sum > 0) { sum } else { 0 })
		Device.store(dev1, output, row, activated)
	})

	kernel_matmul : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	kernel_matmul = |dev, weights, input, bias, output, rows, cols| ({
		(dev1, row) = Device.thread_idx_x(dev)
		(if (row < rows) { mlp_matmul_row(dev1, weights, input, bias, output, row, cols) } else { (dev1, 0) })
	})

	mlp_matmul_row : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_matmul_row = |dev, weights, input, bias, output, row, cols| ({
		(dev1, sum) = mlp_dot_row(dev, weights, input, bias, row, cols)
		Device.store(dev1, output, row, sum)
	})

	mlp_dot_row : Device.Device, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_dot_row = |dev, weights, input, bias, row, cols| ({
		(dev1, b) = Device.load(dev, bias, row)
		mlp_dot_accum(dev1, weights, input, row, cols, 0, b)
	})

	mlp_dot_accum : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_dot_accum = |dev, weights, input, row, cols, col, acc| (if (col >= cols) { (dev, acc) } else { ({
		(dev1, w) = Device.load(dev, weights, ((row * cols) + col))
		(dev2, x) = Device.load(dev1, input, col)
		mlp_dot_accum(dev2, weights, input, row, cols, (col + 1), (acc + (w * x)))
	}) })

	kernel_relu_grad : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	kernel_relu_grad = |dev, grad_out, activations, grad_in, n| ({
		(dev1, tid) = Device.thread_idx_x(dev)
		(if (tid < n) { mlp_relu_grad_one(dev1, grad_out, activations, grad_in, tid) } else { (dev1, 0) })
	})

	mlp_relu_grad_one : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_relu_grad_one = |dev, grad_out, activations, grad_in, tid| ({
		(dev1, val) = Device.load(dev, activations, tid)
		(dev2, g) = Device.load(dev1, grad_out, tid)
		result = (if (val > 0) { g } else { 0 })
		Device.store(dev2, grad_in, tid, result)
	})

	kernel_outer_product_add : Device.Device, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	kernel_outer_product_add = |dev, grad_weights, delta, input, rows, cols| ({
		(dev1, tid) = Device.thread_idx_x(dev)
		({
			row = I64.div_trunc_by(tid, cols)
			col = (tid - (row * cols))
			(if (row < rows) { (if (col < cols) { mlp_outer_one(dev1, grad_weights, delta, input, row, col, cols) } else { (dev1, 0) }) } else { (dev1, 0) })
		})
	})

	mlp_outer_one : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_outer_one = |dev, grad_weights, delta, input, row, col, cols| ({
		(dev1, d) = Device.load(dev, delta, row)
		(dev2, x) = Device.load(dev1, input, col)
		(dev3, old) = Device.load(dev2, grad_weights, ((row * cols) + col))
		Device.store(dev3, grad_weights, ((row * cols) + col), (old + (d * x)))
	})

	kernel_bias_grad_add : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	kernel_bias_grad_add = |dev, grad_bias, delta, n| ({
		(dev1, tid) = Device.thread_idx_x(dev)
		(if (tid < n) { mlp_bias_one(dev1, grad_bias, delta, tid) } else { (dev1, 0) })
	})

	mlp_bias_one : Device.Device, I64, I64, I64 -> (Device.Device, I64)
	mlp_bias_one = |dev, grad_bias, delta, tid| ({
		(dev1, old) = Device.load(dev, grad_bias, tid)
		(dev2, d) = Device.load(dev1, delta, tid)
		Device.store(dev2, grad_bias, tid, (old + d))
	})

	kernel_matmul_transpose : Device.Device, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	kernel_matmul_transpose = |dev, weights, delta, output, rows, cols| ({
		(dev1, col) = Device.thread_idx_x(dev)
		(if (col < cols) { mlp_transpose_col(dev1, weights, delta, output, rows, cols, col) } else { (dev1, 0) })
	})

	mlp_transpose_col : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_transpose_col = |dev, weights, delta, output, rows, cols, col| ({
		(dev1, sum) = mlp_transpose_accum(dev, weights, delta, col, rows, cols, 0, 0)
		Device.store(dev1, output, col, sum)
	})

	mlp_transpose_accum : Device.Device, I64, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_transpose_accum = |dev, weights, delta, col, rows, cols, row, acc| (if (row >= rows) { (dev, acc) } else { ({
		(dev1, w) = Device.load(dev, weights, ((row * cols) + col))
		(dev2, d) = Device.load(dev1, delta, row)
		mlp_transpose_accum(dev2, weights, delta, col, rows, cols, (row + 1), (acc + (w * d)))
	}) })

	kernel_adam_update : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	kernel_adam_update = |dev, params, grads, m_buf, v_buf, n, batch_size| ({
		(dev1, tid) = Device.thread_idx_x(dev)
		(if (tid < n) { mlp_adam_one(dev1, params, grads, m_buf, v_buf, tid, batch_size) } else { (dev1, 0) })
	})

	mlp_adam_one : Device.Device, I64, I64, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_adam_one = |dev, params, grads, m_buf, v_buf, tid, batch_size| ({
		(dev1, g) = Device.load(dev, grads, tid)
		(dev2, m_old) = Device.load(dev1, m_buf, tid)
		(dev3, v_old) = Device.load(dev2, v_buf, tid)
		(dev4, p_old) = Device.load(dev3, params, tid)
		g_scaled = I64.div_trunc_by(g, batch_size)
		m_new = (I64.div_trunc_by((m_old * 9), 10) + I64.div_trunc_by(g_scaled, 10))
		v_new = (I64.div_trunc_by((v_old * 999), 1000) + I64.div_trunc_by((g_scaled * g_scaled), 1000))
		update = I64.div_trunc_by(m_new, (v_new + 1))
		p_new = (p_old - update)
		(dev5, _) = Device.store(dev4, m_buf, tid, m_new)
		(dev6, _) = Device.store(dev5, v_buf, tid, v_new)
		Device.store(dev6, params, tid, p_new)
	})

	kernel_zero_fill : Device.Device, I64, I64 -> (Device.Device, I64)
	kernel_zero_fill = |dev, buf, n| ({
		(dev1, tid) = Device.thread_idx_x(dev)
		(if (tid < n) { Device.store(dev1, buf, tid, 0) } else { (dev1, 0) })
	})

	kernel_mse_loss : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	kernel_mse_loss = |dev, predicted, target, loss_out, n| ({
		(dev1, tid) = Device.thread_idx_x(dev)
		(if (tid < n) { mlp_mse_one(dev1, predicted, target, loss_out, tid) } else { (dev1, 0) })
	})

	mlp_mse_one : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_mse_one = |dev, predicted, target, loss_out, tid| ({
		(dev1, p) = Device.load(dev, predicted, tid)
		(dev2, t) = Device.load(dev1, target, tid)
		diff = (p - t)
		Device.store(dev2, loss_out, tid, (diff * diff))
	})

	kernel_mse_grad : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	kernel_mse_grad = |dev, predicted, target, grad_out, n| ({
		(dev1, tid) = Device.thread_idx_x(dev)
		(if (tid < n) { mlp_mse_grad_one(dev1, predicted, target, grad_out, tid) } else { (dev1, 0) })
	})

	mlp_mse_grad_one : Device.Device, I64, I64, I64, I64 -> (Device.Device, I64)
	mlp_mse_grad_one = |dev, predicted, target, grad_out, tid| ({
		(dev1, p) = Device.load(dev, predicted, tid)
		(dev2, t) = Device.load(dev1, target, tid)
		Device.store(dev2, grad_out, tid, (2 * (p - t)))
	})
}
