# Loss -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Loss :: [].{

	loss_mse : List(I64), List(I64) -> I64
	loss_mse = |pred, target| ({
		n = U64.to_i64_wrap(List.len(pred))
		(if (n == 0) { 0 } else { I64.div_trunc_by(loss_mse_loop(pred, target, 0, n, 0), n) })
	})

	loss_mse_loop : List(I64), List(I64), I64, I64, I64 -> I64
	loss_mse_loop = |pred, target, i, len, acc| (if (i >= len) { acc } else { ({
		diff = ((List.get(pred, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - (List.get(target, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		loss_mse_loop(pred, target, (i + 1), len, (acc + I64.div_trunc_by((diff * diff), 1000)))
	}) })

	loss_cross_entropy : List(I64), List(I64) -> I64
	loss_cross_entropy = |pred, target| ({
		n = U64.to_i64_wrap(List.len(pred))
		(if (n == 0) { 0 } else { (0 - I64.div_trunc_by(loss_ce_loop(pred, target, 0, n, 0), n)) })
	})

	loss_ce_loop : List(I64), List(I64), I64, I64, I64 -> I64
	loss_ce_loop = |pred, target, i, len, acc| (if (i >= len) { acc } else { ({
		p = loss_clamp((List.get(pred, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1, 999)
		t = (List.get(target, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		loss_ce_loop(pred, target, (i + 1), len, (acc + I64.div_trunc_by((t * loss_log(p)), 1000)))
	}) })

	loss_binary_ce : List(I64), List(I64) -> I64
	loss_binary_ce = |pred, target| ({
		n = U64.to_i64_wrap(List.len(pred))
		(if (n == 0) { 0 } else { (0 - I64.div_trunc_by(loss_bce_loop(pred, target, 0, n, 0), n)) })
	})

	loss_bce_loop : List(I64), List(I64), I64, I64, I64 -> I64
	loss_bce_loop = |pred, target, i, len, acc| (if (i >= len) { acc } else { ({
		p = loss_clamp((List.get(pred, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1, 999)
		t = (List.get(target, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		term = (I64.div_trunc_by((t * loss_log(p)), 1000) + I64.div_trunc_by(((1000 - t) * loss_log((1000 - p))), 1000))
		loss_bce_loop(pred, target, (i + 1), len, (acc + term))
	}) })

	loss_hinge : List(I64), List(I64) -> I64
	loss_hinge = |pred, target| ({
		n = U64.to_i64_wrap(List.len(pred))
		(if (n == 0) { 0 } else { I64.div_trunc_by(loss_hinge_loop(pred, target, 0, n, 0), n) })
	})

	loss_hinge_loop : List(I64), List(I64), I64, I64, I64 -> I64
	loss_hinge_loop = |pred, target, i, len, acc| (if (i >= len) { acc } else { ({
		margin = (1000 - I64.div_trunc_by(((List.get(target, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * (List.get(pred, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 1000))
		h = (if (margin > 0) { margin } else { 0 })
		loss_hinge_loop(pred, target, (i + 1), len, (acc + h))
	}) })

	loss_kl_divergence : List(I64), List(I64) -> I64
	loss_kl_divergence = |p, q| ({
		n = U64.to_i64_wrap(List.len(p))
		(if (n == 0) { 0 } else { loss_kl_loop(p, q, 0, n, 0) })
	})

	loss_kl_loop : List(I64), List(I64), I64, I64, I64 -> I64
	loss_kl_loop = |p, q, i, len, acc| (if (i >= len) { acc } else { ({
		pi = loss_clamp((List.get(p, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1, 999)
		qi = loss_clamp((List.get(q, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), 1, 999)
		loss_kl_loop(p, q, (i + 1), len, (acc + I64.div_trunc_by((pi * (loss_log(pi) - loss_log(qi))), 1000)))
	}) })

	loss_huber : List(I64), List(I64), I64 -> I64
	loss_huber = |pred, target, delta| ({
		n = U64.to_i64_wrap(List.len(pred))
		(if (n == 0) { 0 } else { I64.div_trunc_by(loss_huber_loop(pred, target, delta, 0, n, 0), n) })
	})

	loss_huber_loop : List(I64), List(I64), I64, I64, I64, I64 -> I64
	loss_huber_loop = |pred, target, delta, i, len, acc| (if (i >= len) { acc } else { ({
		diff = ((List.get(pred, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - (List.get(target, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		abs_diff = (if (diff < 0) { (0 - diff) } else { diff })
		h = (if (abs_diff <= delta) { I64.div_trunc_by((diff * diff), (2 * 1000)) } else { I64.div_trunc_by((delta * (abs_diff - I64.div_trunc_by(delta, 2))), 1000) })
		loss_huber_loop(pred, target, delta, (i + 1), len, (acc + h))
	}) })

	loss_log : I64 -> I64
	loss_log = |x| (if (x <= 0) { (0 - 10000) } else { loss_log_approx(x) })

	loss_log_approx : I64 -> I64
	loss_log_approx = |x| ({
		y = I64.div_trunc_by(((x - 1000) * 1000), (x + 1000))
		y2 = I64.div_trunc_by((y * y), 1000)
		(2 * ((y + I64.div_trunc_by((y * y2), (3 * 1000))) + I64.div_trunc_by(((y * y2) * y2), ((5 * 1000) * 1000))))
	})

	loss_clamp : I64, I64, I64 -> I64
	loss_clamp = |x, lo, hi| (if (x < lo) { lo } else { (if (x > hi) { hi } else { x }) })
}
