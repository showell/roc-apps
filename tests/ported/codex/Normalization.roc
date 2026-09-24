# Normalization -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Activation
import MathLib

Normalization :: [].{
	NormParams := { norm_num_groups : I64, norm_num_channels : I64, norm_gamma : List(I64), norm_beta : List(I64), norm_eps : I64 }.{
		is_eq : Normalization.NormParams, Normalization.NormParams -> Bool
		is_eq = |a, b| a.norm_num_groups == b.norm_num_groups and a.norm_num_channels == b.norm_num_channels and a.norm_gamma == b.norm_gamma and a.norm_beta == b.norm_beta and a.norm_eps == b.norm_eps
	}

	group_norm_params : I64, I64, List(I64), List(I64) -> Normalization.NormParams
	group_norm_params = |groups, channels, gamma, beta| Normalization.NormParams.{ norm_num_groups: groups, norm_num_channels: channels, norm_gamma: gamma, norm_beta: beta, norm_eps: 1 }

	layer_norm_params : I64, List(I64), List(I64) -> Normalization.NormParams
	layer_norm_params = |dim, gamma, beta| Normalization.NormParams.{ norm_num_groups: 1, norm_num_channels: dim, norm_gamma: gamma, norm_beta: beta, norm_eps: 1 }

	rms_norm_params : I64, List(I64) -> Normalization.NormParams
	rms_norm_params = |dim, gamma| Normalization.NormParams.{ norm_num_groups: 1, norm_num_channels: dim, norm_gamma: gamma, norm_beta: norm_zeros(dim, 0, []), norm_eps: 1 }

	norm_zeros : I64, I64, List(I64) -> List(I64)
	norm_zeros = |n, i, acc| (if (i >= n) { acc } else { norm_zeros(n, (i + 1), List.append(acc, 0)) })

	group_norm : Normalization.NormParams, List(I64), I64, I64 -> List(I64)
	group_norm = |params, input, h, w| ({
		ch_per_group : I64
		ch_per_group = I64.div_trunc_by(params.norm_num_channels, params.norm_num_groups)
		spatial : I64
		spatial = (h * w)
		gn_process_groups(params, input, spatial, ch_per_group, 0, [])
	})

	gn_process_groups : Normalization.NormParams, List(I64), I64, I64, I64, List(I64) -> List(I64)
	gn_process_groups = |params, input, spatial, ch_per_group, g, acc| (if (g >= params.norm_num_groups) { acc } else { ({
		start_ch : I64
		start_ch = (g * ch_per_group)
		group_size : I64
		group_size = (ch_per_group * spatial)
		mean : I64
		mean = gn_compute_mean(input, start_ch, spatial, ch_per_group, group_size)
		variance : I64
		variance = gn_compute_variance(input, start_ch, spatial, ch_per_group, group_size, mean)
		std : I64
		std = MathLib.math_isqrt(((variance + params.norm_eps) * 1000))
		normed : List(I64)
		normed = gn_normalize_group(params, input, start_ch, spatial, ch_per_group, mean, std, 0, [])
		gn_process_groups(params, input, spatial, ch_per_group, (g + 1), List.concat(acc, normed))
	}) })

	gn_compute_mean : List(I64), I64, I64, I64, I64 -> I64
	gn_compute_mean = |input, start_ch, spatial, ch_per_group, group_size| ({
		total : I64
		total = gn_sum_group(input, start_ch, spatial, ch_per_group, 0, 0)
		I64.div_trunc_by(total, group_size)
	})

	gn_sum_group : List(I64), I64, I64, I64, I64, I64 -> I64
	gn_sum_group = |input, start_ch, spatial, ch_per_group, lc, acc| (if (lc >= ch_per_group) { acc } else { ({
		ch : I64
		ch = (start_ch + lc)
		ch_sum : I64
		ch_sum = gn_sum_spatial(input, (ch * spatial), spatial, 0, 0)
		gn_sum_group(input, start_ch, spatial, ch_per_group, (lc + 1), (acc + ch_sum))
	}) })

	gn_sum_spatial : List(I64), I64, I64, I64, I64 -> I64
	gn_sum_spatial = |input, base, spatial, i, acc| (if (i >= spatial) { acc } else { gn_sum_spatial(input, base, spatial, (i + 1), (acc + (List.get(input, I64.to_u64_wrap((base + i))) ?? crash("list-at out of range")))) })

	gn_compute_variance : List(I64), I64, I64, I64, I64, I64 -> I64
	gn_compute_variance = |input, start_ch, spatial, ch_per_group, group_size, mean| ({
		sq_sum : I64
		sq_sum = gn_sq_diff_group(input, start_ch, spatial, ch_per_group, mean, 0, 0)
		I64.div_trunc_by(sq_sum, group_size)
	})

	gn_sq_diff_group : List(I64), I64, I64, I64, I64, I64, I64 -> I64
	gn_sq_diff_group = |input, start_ch, spatial, ch_per_group, mean, lc, acc| (if (lc >= ch_per_group) { acc } else { ({
		ch : I64
		ch = (start_ch + lc)
		ch_sum : I64
		ch_sum = gn_sq_diff_spatial(input, (ch * spatial), spatial, mean, 0, 0)
		gn_sq_diff_group(input, start_ch, spatial, ch_per_group, mean, (lc + 1), (acc + ch_sum))
	}) })

	gn_sq_diff_spatial : List(I64), I64, I64, I64, I64, I64 -> I64
	gn_sq_diff_spatial = |input, base, spatial, mean, i, acc| (if (i >= spatial) { acc } else { ({
		diff : I64
		diff = ((List.get(input, I64.to_u64_wrap((base + i))) ?? crash("list-at out of range")) - mean)
		gn_sq_diff_spatial(input, base, spatial, mean, (i + 1), (acc + I64.div_trunc_by((diff * diff), 1000)))
	}) })

	gn_normalize_group : Normalization.NormParams, List(I64), I64, I64, I64, I64, I64, I64, List(I64) -> List(I64)
	gn_normalize_group = |params, input, start_ch, spatial, ch_per_group, mean, std, lc, acc| (if (lc >= ch_per_group) { acc } else { ({
		ch : I64
		ch = (start_ch + lc)
		gamma : I64
		gamma = (List.get(params.norm_gamma, I64.to_u64_wrap(ch)) ?? crash("list-at out of range"))
		beta : I64
		beta = (List.get(params.norm_beta, I64.to_u64_wrap(ch)) ?? crash("list-at out of range"))
		normed : List(I64)
		normed = gn_norm_spatial(input, (ch * spatial), spatial, mean, std, gamma, beta, 0, [])
		gn_normalize_group(params, input, start_ch, spatial, ch_per_group, mean, std, (lc + 1), List.concat(acc, normed))
	}) })

	gn_norm_spatial : List(I64), I64, I64, I64, I64, I64, I64, I64, List(I64) -> List(I64)
	gn_norm_spatial = |input, base, spatial, mean, std, gamma, beta, i, acc| (if (i >= spatial) { acc } else { ({
		val : I64
		val = (List.get(input, I64.to_u64_wrap((base + i))) ?? crash("list-at out of range"))
		normed : I64
		normed = I64.div_trunc_by(((val - mean) * 1000), std)
		scaled : I64
		scaled = (I64.div_trunc_by((normed * gamma), 1000) + beta)
		gn_norm_spatial(input, base, spatial, mean, std, gamma, beta, (i + 1), List.append(acc, scaled))
	}) })

	layer_norm_forward : Normalization.NormParams, List(I64) -> List(I64)
	layer_norm_forward = |params, input| ({
		n : I64
		n = U64.to_i64_wrap(List.len(input))
		mean : I64
		mean = ln_mean(input, n)
		variance : I64
		variance = ln_variance(input, n, mean)
		std : I64
		std = MathLib.math_isqrt(((variance + params.norm_eps) * 1000))
		ln_normalize(params, input, mean, std, 0, n, [])
	})

	ln_mean : List(I64), I64 -> I64
	ln_mean = |input, n| I64.div_trunc_by(ln_sum(input, 0, n, 0), n)

	ln_sum : List(I64), I64, I64, I64 -> I64
	ln_sum = |input, i, n, acc| (if (i >= n) { acc } else { ln_sum(input, (i + 1), n, (acc + (List.get(input, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	ln_variance : List(I64), I64, I64 -> I64
	ln_variance = |input, n, mean| I64.div_trunc_by(ln_sq_sum(input, 0, n, mean, 0), n)

	ln_sq_sum : List(I64), I64, I64, I64, I64 -> I64
	ln_sq_sum = |input, i, n, mean, acc| (if (i >= n) { acc } else { ({
		diff : I64
		diff = ((List.get(input, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - mean)
		ln_sq_sum(input, (i + 1), n, mean, (acc + I64.div_trunc_by((diff * diff), 1000)))
	}) })

	ln_normalize : Normalization.NormParams, List(I64), I64, I64, I64, I64, List(I64) -> List(I64)
	ln_normalize = |params, input, mean, std, i, n, acc| (if (i >= n) { acc } else { ({
		val : I64
		val = (List.get(input, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		normed : I64
		normed = I64.div_trunc_by(((val - mean) * 1000), std)
		gamma : I64
		gamma = (if (i < U64.to_i64_wrap(List.len(params.norm_gamma))) { (List.get(params.norm_gamma, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { 1000 })
		beta : I64
		beta = (if (i < U64.to_i64_wrap(List.len(params.norm_beta))) { (List.get(params.norm_beta, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { 0 })
		scaled : I64
		scaled = (I64.div_trunc_by((normed * gamma), 1000) + beta)
		ln_normalize(params, input, mean, std, (i + 1), n, List.append(acc, scaled))
	}) })

	rms_norm_forward : Normalization.NormParams, List(I64) -> List(I64)
	rms_norm_forward = |params, input| ({
		n : I64
		n = U64.to_i64_wrap(List.len(input))
		rms : I64
		rms = rms_compute(input, n)
		inv_rms : I64
		inv_rms = (if (rms == 0) { 1000 } else { I64.div_trunc_by(1000000, rms) })
		rms_normalize(params, input, inv_rms, 0, n, [])
	})

	rms_compute : List(I64), I64 -> I64
	rms_compute = |input, n| ({
		sq_sum : I64
		sq_sum = rms_sq_sum(input, 0, n, 0)
		MathLib.math_isqrt(I64.div_trunc_by(sq_sum, n))
	})

	rms_sq_sum : List(I64), I64, I64, I64 -> I64
	rms_sq_sum = |input, i, n, acc| (if (i >= n) { acc } else { ({
		v : I64
		v = (List.get(input, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		rms_sq_sum(input, (i + 1), n, (acc + I64.div_trunc_by((v * v), 1000)))
	}) })

	rms_normalize : Normalization.NormParams, List(I64), I64, I64, I64, List(I64) -> List(I64)
	rms_normalize = |params, input, inv_rms, i, n, acc| (if (i >= n) { acc } else { ({
		val : I64
		val = (List.get(input, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		normed : I64
		normed = I64.div_trunc_by((val * inv_rms), 1000)
		gamma : I64
		gamma = (if (i < U64.to_i64_wrap(List.len(params.norm_gamma))) { (List.get(params.norm_gamma, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { 1000 })
		scaled : I64
		scaled = I64.div_trunc_by((normed * gamma), 1000)
		rms_normalize(params, input, inv_rms, (i + 1), n, List.append(acc, scaled))
	}) })

	silu_forward : List(I64) -> List(I64)
	silu_forward = |input| silu_loop(input, 0, U64.to_i64_wrap(List.len(input)), [])

	silu_loop : List(I64), I64, I64, List(I64) -> List(I64)
	silu_loop = |input, i, n, acc| (if (i >= n) { acc } else { ({
		x : I64
		x = (List.get(input, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		sig : I64
		sig = silu_sigmoid(x)
		silu_loop(input, (i + 1), n, List.append(acc, I64.div_trunc_by((x * sig), 1000)))
	}) })

	silu_sigmoid : I64 -> I64
	silu_sigmoid = |x| Activation.act_sigmoid_val(x)
}
