# Activation -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import ListUtils
import Tensor

Activation :: [].{

	act_relu : Tensor.Tensor -> Tensor.Tensor
	act_relu = |t| Tensor.Tensor.{ data: ListUtils.map_list(lam_0, t.data), rows: t.rows, cols: t.cols }

	act_leaky_relu : Tensor.Tensor, I64 -> Tensor.Tensor
	act_leaky_relu = |t, alpha| Tensor.Tensor.{ data: ListUtils.map_list(({
		dev__1 = alpha
		|dev__2| lam_1(dev__1, dev__2)
	}), t.data), rows: t.rows, cols: t.cols }

	act_sigmoid : Tensor.Tensor -> Tensor.Tensor
	act_sigmoid = |t| Tensor.Tensor.{ data: ListUtils.map_list(lam_2, t.data), rows: t.rows, cols: t.cols }

	act_sigmoid_val : I64 -> I64
	act_sigmoid_val = |x| (if (x > 16000) { 1000 } else { (if (x < (0 - 16000)) { 0 } else { I64.div_trunc_by(1000000, (1000 + act_exp_approx((0 - x)))) }) })

	act_tanh : Tensor.Tensor -> Tensor.Tensor
	act_tanh = |t| Tensor.Tensor.{ data: ListUtils.map_list(lam_3, t.data), rows: t.rows, cols: t.cols }

	act_tanh_val : I64 -> I64
	act_tanh_val = |x| ((act_sigmoid_val((x * 2)) * 2) - 1000)

	act_gelu : Tensor.Tensor -> Tensor.Tensor
	act_gelu = |t| Tensor.Tensor.{ data: ListUtils.map_list(lam_4, t.data), rows: t.rows, cols: t.cols }

	act_gelu_val : I64 -> I64
	act_gelu_val = |x| ({
		sig = act_sigmoid_val(I64.div_trunc_by((x * 1702), 1000))
		I64.div_trunc_by((x * sig), 1000)
	})

	act_softmax : Tensor.Tensor -> Tensor.Tensor
	act_softmax = |t| ({
		max_val = Tensor.tensor_max(t)
		shifted = ListUtils.map_list(({
			dev__1 = max_val
			|dev__2| lam_5(dev__1, dev__2)
		}), t.data)
		exps = ListUtils.map_list(lam_6, shifted)
		total = act_sum_list(exps, 0, U64.to_i64_wrap(List.len(exps)), 0)
		normed = (if (total == 0) { exps } else { ListUtils.map_list(({
			dev__3 = total
			|dev__4| lam_7(dev__3, dev__4)
		}), exps) })
		Tensor.Tensor.{ data: normed, rows: t.rows, cols: t.cols }
	})

	act_exp_approx : I64 -> I64
	act_exp_approx = |x| (if (x < 0) { I64.div_trunc_by(1000000, act_exp_approx((0 - x))) } else { (if (x > 20000) { 485165195 } else { ({
		k = I64.div_trunc_by(x, 1000)
		I64.div_trunc_by((act_exp_int(k) * act_exp_frac((x - (k * 1000)))), 1000)
	}) }) })

	act_exp_int : I64 -> I64
	act_exp_int = |k| (if (k <= 0) { 1000 } else { I64.div_trunc_by((act_exp_int((k - 1)) * 2718), 1000) })

	act_exp_frac : I64 -> I64
	act_exp_frac = |r| (((((1000 + r) + I64.div_trunc_by((r * r), 2000)) + I64.div_trunc_by(((r * r) * r), 6000000)) + I64.div_trunc_by((((r * r) * r) * r), 24000000000)) + I64.div_trunc_by(((((r * r) * r) * r) * r), 120000000000000))

	act_sum_list : List(I64), I64, I64, I64 -> I64
	act_sum_list = |data, i, len, acc| (if (i >= len) { acc } else { act_sum_list(data, (i + 1), len, (acc + (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	lam_0 : I64 -> I64
	lam_0 = |v| (if (v > 0) { v } else { 0 })

	lam_1 : I64, I64 -> I64
	lam_1 = |alpha, v| (if (v > 0) { v } else { I64.div_trunc_by((v * alpha), 1000) })

	lam_2 : I64 -> I64
	lam_2 = |v| act_sigmoid_val(v)

	lam_3 : I64 -> I64
	lam_3 = |v| act_tanh_val(v)

	lam_4 : I64 -> I64
	lam_4 = |v| act_gelu_val(v)

	lam_5 : I64, I64 -> I64
	lam_5 = |max_val, v| (v - max_val)

	lam_6 : I64 -> I64
	lam_6 = |v| act_exp_approx(v)

	lam_7 : I64, I64 -> I64
	lam_7 = |total, v| I64.div_trunc_by((v * 1000), total)
}
