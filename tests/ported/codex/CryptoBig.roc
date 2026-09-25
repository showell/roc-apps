# CryptoBig -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

CryptoBig :: [].{

	cb_base : I64
	cb_base = 65536

	cb_mask : I64
	cb_mask = 65535

	cb_shift : I64
	cb_shift = 16

	cb_zeros : I64 -> List(I64)
	cb_zeros = |n| cb_zeros_loop(n, 0, [])

	cb_zeros_loop : I64, I64, List(I64) -> List(I64)
	cb_zeros_loop = |n, i, acc| (if (i >= n) { acc } else { cb_zeros_loop(n, (i + 1), List.append(acc, 0)) })

	cb_one : I64 -> List(I64)
	cb_one = |n| (List.set(cb_zeros(n), I64.to_u64_wrap(0), 1) ?? crash("list-set-at past the end"))

	cb_from_bytes : List(I64), I64 -> List(I64)
	cb_from_bytes = |bs, n| cb_fb_loop(bs, (U64.to_i64_wrap(List.len(bs)) - 1), 0, cb_zeros(n), n)

	cb_fb_loop : List(I64), I64, I64, List(I64), I64 -> List(I64)
	cb_fb_loop = |bs, bi, li, acc, n| (if (li >= n) { acc } else { (if (bi < 0) { acc } else { cb_fb_step(bs, bi, li, acc, n) }) })

	cb_fb_step : List(I64), I64, I64, List(I64), I64 -> List(I64)
	cb_fb_step = |bs, bi, li, acc, n| ({
		lo : I64
		lo = (List.get(bs, I64.to_u64_wrap(bi)) ?? crash("list-at out of range"))
		hi : I64
		hi = (if ((bi - 1) >= 0) { (List.get(bs, I64.to_u64_wrap((bi - 1))) ?? crash("list-at out of range")) } else { 0 })
		acc_v1 : List(I64)
		acc_v1 = (List.set(acc, I64.to_u64_wrap(li), (lo + (hi * 256))) ?? crash("list-set-at past the end"))
		cb_fb_loop(bs, (bi - 2), (li + 1), acc_v1, n)
	})

	cb_to_bytes : List(I64), I64 -> List(I64)
	cb_to_bytes = |x, nbytes| cb_tb_loop(x, nbytes, 0, [])

	cb_tb_loop : List(I64), I64, I64, List(I64) -> List(I64)
	cb_tb_loop = |x, nbytes, i, acc| (if (i >= nbytes) { acc } else { cb_tb_step(x, nbytes, i, acc) })

	cb_tb_step : List(I64), I64, I64, List(I64) -> List(I64)
	cb_tb_step = |x, nbytes, i, acc| ({
		p : I64
		p = ((nbytes - 1) - i)
		li : I64
		li = I64.div_trunc_by(p, 2)
		limb : I64
		limb = (if (li < U64.to_i64_wrap(List.len(x))) { (List.get(x, I64.to_u64_wrap(li)) ?? crash("list-at out of range")) } else { 0 })
		b : I64
		b = (if (I64.rem_by(p, 2) == 0) { I64.bitwise_and(limb, 255) } else { I64.bitwise_and(I64.shr_zf_wrap(limb, I64.to_u8_wrap(8)), 255) })
		cb_tb_loop(x, nbytes, (i + 1), List.append(acc, b))
	})

	cb_cmp : List(I64), List(I64), I64 -> I64
	cb_cmp = |a, b, n| cb_cmp_loop(a, b, (n - 1))

	cb_cmp_loop : List(I64), List(I64), I64 -> I64
	cb_cmp_loop = |a, b, i| (if (i < 0) { 0 } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) > (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { 1 } else { (if ((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) < (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) { (-1) } else { cb_cmp_loop(a, b, (i - 1)) }) }) })

	cb_sub_into : List(I64), List(I64), I64 -> List(I64)
	cb_sub_into = |a, b, n| cb_sub_loop(a, b, n, 0, 0)

	cb_sub_loop : List(I64), List(I64), I64, I64, I64 -> List(I64)
	cb_sub_loop = |a, b, n, i, borrow| (if (i >= n) { a } else { cb_sub_step(a, b, n, i, borrow, (((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) - (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) - borrow)) })

	cb_sub_step : List(I64), List(I64), I64, I64, I64, I64 -> List(I64)
	cb_sub_step = |a, b, n, i, _borrow, d| (if (d < 0) { ({
		a_v1 : List(I64)
		a_v1 = (List.set(a, I64.to_u64_wrap(i), (d + cb_base)) ?? crash("list-set-at past the end"))
		cb_sub_loop(a_v1, b, n, (i + 1), 1)
	}) } else { ({
		a_v2 : List(I64)
		a_v2 = (List.set(a, I64.to_u64_wrap(i), d) ?? crash("list-set-at past the end"))
		cb_sub_loop(a_v2, b, n, (i + 1), 0)
	}) })

	cb_n0inv : List(I64) -> I64
	cb_n0inv = |m| cb_n0inv_neg(cb_newton((List.get(m, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), 1, 0))

	cb_newton : I64, I64, I64 -> I64
	cb_newton = |n0, inv, k| (if (k >= 5) { inv } else { cb_newton(n0, I64.bitwise_and((inv * (2 - (n0 * inv))), cb_mask), (k + 1)) })

	cb_n0inv_neg : I64 -> I64
	cb_n0inv_neg = |inv| I64.bitwise_and((cb_base - inv), cb_mask)

	cb_mont_mul : List(I64), List(I64), List(I64), I64, I64 -> List(I64)
	cb_mont_mul = |a, b, m, n, n0inv| ({
		cb_mont_outer_v1 = cb_mont_outer(a, b, m, n, n0inv, cb_zeros((n + 2)), 0)
		cb_mont_outer_v1.0
	})

	cb_mont_outer : List(I64), List(I64), List(I64), I64, I64, List(I64), I64 -> (List(I64), List(I64))
	cb_mont_outer = |a, b, m, n, n0inv, t, i| (if (i >= n) { (cb_mont_final(t, m, n), t) } else { cb_mont_round(a, b, m, n, n0inv, t, i) })

	cb_mont_round : List(I64), List(I64), List(I64), I64, I64, List(I64), I64 -> (List(I64), List(I64))
	cb_mont_round = |a, b, m, n, n0inv, t, i| ({
		cb_mul_add_v1 : List(I64)
		cb_mul_add_v1 = cb_mul_add(t, a, (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), n, 0, 0)
		t1 : List(I64)
		t1 = cb_mul_add_v1
		mu : I64
		mu = I64.bitwise_and(((List.get(t1, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) * n0inv), cb_mask)
		cb_red_add_v2 : List(I64)
		cb_red_add_v2 = cb_red_add(t1, m, mu, n, 0, 0)
		t2 : List(I64)
		t2 = cb_red_add_v2
		cb_shift_down_v3 : List(I64)
		cb_shift_down_v3 = cb_shift_down(t2, n, 0)
		cb_mont_outer(a, b, m, n, n0inv, cb_shift_down_v3, (i + 1))
	})

	cb_mul_add : List(I64), List(I64), I64, I64, I64, I64 -> List(I64)
	cb_mul_add = |t, a, bi, n, j, carry| (if (j >= n) { cb_mul_add_tail(t, n, carry) } else { cb_mul_add_step(t, a, bi, n, j, (((List.get(t, I64.to_u64_wrap(j)) ?? crash("list-at out of range")) + ((List.get(a, I64.to_u64_wrap(j)) ?? crash("list-at out of range")) * bi)) + carry)) })

	cb_mul_add_step : List(I64), List(I64), I64, I64, I64, I64 -> List(I64)
	cb_mul_add_step = |t, a, bi, n, j, v| ({
		t_v1 : List(I64)
		t_v1 = (List.set(t, I64.to_u64_wrap(j), I64.bitwise_and(v, cb_mask)) ?? crash("list-set-at past the end"))
		cb_mul_add(t_v1, a, bi, n, (j + 1), I64.shr_zf_wrap(v, I64.to_u8_wrap(cb_shift)))
	})

	cb_mul_add_tail : List(I64), I64, I64 -> List(I64)
	cb_mul_add_tail = |t, n, carry| ({
		v : I64
		v = ((List.get(t, I64.to_u64_wrap(n)) ?? crash("list-at out of range")) + carry)
		t_v1 : List(I64)
		t_v1 = (List.set(t, I64.to_u64_wrap(n), I64.bitwise_and(v, cb_mask)) ?? crash("list-set-at past the end"))
		(List.set(t_v1, I64.to_u64_wrap((n + 1)), ((List.get(t_v1, I64.to_u64_wrap((n + 1))) ?? crash("list-at out of range")) + I64.shr_zf_wrap(v, I64.to_u8_wrap(cb_shift)))) ?? crash("list-set-at past the end"))
	})

	cb_red_add : List(I64), List(I64), I64, I64, I64, I64 -> List(I64)
	cb_red_add = |t, m, mu, n, j, carry| (if (j >= n) { cb_red_add_tail(t, n, carry) } else { cb_red_add_step(t, m, mu, n, j, (((List.get(t, I64.to_u64_wrap(j)) ?? crash("list-at out of range")) + ((List.get(m, I64.to_u64_wrap(j)) ?? crash("list-at out of range")) * mu)) + carry)) })

	cb_red_add_step : List(I64), List(I64), I64, I64, I64, I64 -> List(I64)
	cb_red_add_step = |t, m, mu, n, j, v| ({
		t_v1 : List(I64)
		t_v1 = (List.set(t, I64.to_u64_wrap(j), I64.bitwise_and(v, cb_mask)) ?? crash("list-set-at past the end"))
		cb_red_add(t_v1, m, mu, n, (j + 1), I64.shr_zf_wrap(v, I64.to_u8_wrap(cb_shift)))
	})

	cb_red_add_tail : List(I64), I64, I64 -> List(I64)
	cb_red_add_tail = |t, n, carry| ({
		v : I64
		v = ((List.get(t, I64.to_u64_wrap(n)) ?? crash("list-at out of range")) + carry)
		t_v1 : List(I64)
		t_v1 = (List.set(t, I64.to_u64_wrap(n), I64.bitwise_and(v, cb_mask)) ?? crash("list-set-at past the end"))
		(List.set(t_v1, I64.to_u64_wrap((n + 1)), ((List.get(t_v1, I64.to_u64_wrap((n + 1))) ?? crash("list-at out of range")) + I64.shr_zf_wrap(v, I64.to_u8_wrap(cb_shift)))) ?? crash("list-set-at past the end"))
	})

	cb_shift_down : List(I64), I64, I64 -> List(I64)
	cb_shift_down = |t, n, j| (if (j > n) { (List.set(t, I64.to_u64_wrap((n + 1)), 0) ?? crash("list-set-at past the end")) } else { ({
		t_v2 : List(I64)
		t_v2 = (List.set(t, I64.to_u64_wrap(j), (List.get(t, I64.to_u64_wrap((j + 1))) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end"))
		cb_shift_down(t_v2, n, (j + 1))
	}) })

	cb_mont_final : List(I64), List(I64), I64 -> List(I64)
	cb_mont_final = |t, m, n| ({
		r : List(I64)
		r = cb_take(t, n)
		copyout_v5 = (if ((List.get(t, I64.to_u64_wrap(n)) ?? crash("list-at out of range")) > 0) { ({
			cb_sub_into_v1 : List(I64)
			cb_sub_into_v1 = cb_sub_into(r, m, n)
			(cb_sub_into_v1, cb_sub_into_v1)
		}) } else { ({
			copyout_v3 = (if (cb_cmp(r, m, n) >= 0) { ({
				cb_sub_into_v2 : List(I64)
				cb_sub_into_v2 = cb_sub_into(r, m, n)
				(cb_sub_into_v2, cb_sub_into_v2)
			}) } else { (r, r) })
			r_v4 : List(I64)
			r_v4 = copyout_v3.1
			(copyout_v3.0, r_v4)
		}) })
		_r_v6 = copyout_v5.1
		copyout_v5.0
	})

	cb_take : List(I64), I64 -> List(I64)
	cb_take = |t, n| cb_take_loop(t, n, 0, [])

	cb_take_loop : List(I64), I64, I64, List(I64) -> List(I64)
	cb_take_loop = |t, n, i, acc| (if (i >= n) { acc } else { cb_take_loop(t, n, (i + 1), List.append(acc, (List.get(t, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	cb_r_squared : List(I64), I64 -> List(I64)
	cb_r_squared = |m, n| cb_r2_loop(cb_one(n), m, n, 0, (32 * n))

	cb_r2_loop : List(I64), List(I64), I64, I64, I64 -> List(I64)
	cb_r2_loop = |x, m, n, k, rounds| (if (k >= rounds) { x } else { ({
		cb_dbl_mod_v1 : List(I64)
		cb_dbl_mod_v1 = cb_dbl_mod(x, m, n)
		cb_r2_loop(cb_dbl_mod_v1, m, n, (k + 1), rounds)
	}) })

	cb_dbl_mod : List(I64), List(I64), I64 -> List(I64)
	cb_dbl_mod = |x, m, n| ({
		cb_shl1_v1 = cb_shl1(x, n, 0, 0)
		x_v2 : List(I64)
		x_v2 = cb_shl1_v1.1
		cb_dbl_fix(x_v2, m, n, cb_shl1_v1.0)
	})

	cb_dbl_fix : List(I64), List(I64), I64, I64 -> List(I64)
	cb_dbl_fix = |x, m, n, carry| (if (carry > 0) { cb_sub_into(x, m, n) } else { (if (cb_cmp(x, m, n) >= 0) { cb_sub_into(x, m, n) } else { x }) })

	cb_shl1 : List(I64), I64, I64, I64 -> (I64, List(I64))
	cb_shl1 = |x, n, i, carry| (if (i >= n) { (carry, x) } else { cb_shl1_step(x, n, i, (((List.get(x, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * 2) + carry)) })

	cb_shl1_step : List(I64), I64, I64, I64 -> (I64, List(I64))
	cb_shl1_step = |x, n, i, v| ({
		x_v1 : List(I64)
		x_v1 = (List.set(x, I64.to_u64_wrap(i), I64.bitwise_and(v, cb_mask)) ?? crash("list-set-at past the end"))
		cb_shl1(x_v1, n, (i + 1), I64.shr_zf_wrap(v, I64.to_u8_wrap(cb_shift)))
	})

	cb_mod_exp : List(I64), List(I64), List(I64) -> List(I64)
	cb_mod_exp = |base_bytes, exp_bytes, mod_bytes| (if (U64.to_i64_wrap(List.len(mod_bytes)) == 0) { [] } else { (if (((cb_octets_ok(base_bytes, 0) == False) or (cb_octets_ok(exp_bytes, 0) == False)) or (cb_octets_ok(mod_bytes, 0) == False)) { [] } else { (if (I64.bitwise_and((List.get(mod_bytes, I64.to_u64_wrap((U64.to_i64_wrap(List.len(mod_bytes)) - 1))) ?? crash("list-at out of range")), 1) == 0) { [] } else { cb_exp_setup(base_bytes, exp_bytes, mod_bytes, I64.div_trunc_by((U64.to_i64_wrap(List.len(mod_bytes)) + 1), 2)) }) }) })

	cb_octets_ok : List(I64), I64 -> Bool
	cb_octets_ok = |bytes, i| (if (i >= U64.to_i64_wrap(List.len(bytes))) { True } else { (if (((List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) < 0) or ((List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) > 255)) { False } else { cb_octets_ok(bytes, (i + 1)) }) })

	cb_exp_setup : List(I64), List(I64), List(I64), I64 -> List(I64)
	cb_exp_setup = |base_bytes, exp_bytes, mod_bytes, n| ({
		m : List(I64)
		m = cb_from_bytes(mod_bytes, n)
		(if (cb_cmp(m, cb_one(n), n) == 0) { cb_zeros(n) } else { ({
			a : List(I64)
			a = (if (U64.to_i64_wrap(List.len(base_bytes)) <= (n * 2)) { cb_from_bytes(base_bytes, n) } else { ({
				cb_reduce_base_v1 = cb_reduce_base(base_bytes, m, n, ((U64.to_i64_wrap(List.len(base_bytes)) * 8) - 1), cb_zeros(n))
				cb_reduce_base_v1.0
			}) })
			cb_exp_go(a, exp_bytes, m, n, cb_n0inv(m), cb_r_squared(m, n))
		}) })
	})

	cb_reduce_base : List(I64), List(I64), I64, I64, List(I64) -> (List(I64), List(I64))
	cb_reduce_base = |bytes, m, n, i, acc| (if (i < 0) { (acc, acc) } else { ({
		cb_dbl_mod_v1 : List(I64)
		cb_dbl_mod_v1 = cb_dbl_mod(acc, m, n)
		doubled : List(I64)
		doubled = cb_dbl_mod_v1
		copyout_v3 = (if (cb_bit_at(bytes, i) == 0) { (doubled, doubled) } else { ({
			cb_add_one_mod_v2 : List(I64)
			cb_add_one_mod_v2 = cb_add_one_mod(doubled, m, n)
			(cb_add_one_mod_v2, cb_add_one_mod_v2)
		}) })
		acc_v4 : List(I64)
		acc_v4 = copyout_v3.1
		next : List(I64)
		next = copyout_v3.0
		cb_reduce_base_v5 = cb_reduce_base(bytes, m, n, (i - 1), next)
		_next_v6 = cb_reduce_base_v5.1
		(cb_reduce_base_v5.0, acc_v4)
	}) })

	cb_add_one_mod : List(I64), List(I64), I64 -> List(I64)
	cb_add_one_mod = |acc, m, n| ({
		cb_add_one_v1 : List(I64)
		cb_add_one_v1 = cb_add_one(acc, n, 0)
		increased : List(I64)
		increased = cb_add_one_v1
		(if (cb_cmp(increased, m, n) >= 0) { cb_sub_into(increased, m, n) } else { increased })
	})

	cb_add_one : List(I64), I64, I64 -> List(I64)
	cb_add_one = |acc, n, i| (if (i >= n) { acc } else { ({
		value : I64
		value = ((List.get(acc, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) + 1)
		acc_v1 : List(I64)
		acc_v1 = (List.set(acc, I64.to_u64_wrap(i), I64.bitwise_and(value, cb_mask)) ?? crash("list-set-at past the end"))
		updated : List(I64)
		updated = acc_v1
		(if (value < cb_base) { updated } else { cb_add_one(updated, n, (i + 1)) })
	}) })

	cb_exp_go : List(I64), List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	cb_exp_go = |a, exp_bytes, m, n, n0inv, r2| ({
		a_mont : List(I64)
		a_mont = cb_mont_mul(a, r2, m, n, n0inv)
		one_mont : List(I64)
		one_mont = cb_mont_mul(cb_one(n), r2, m, n, n0inv)
		cb_exp_out(cb_exp_bits(a_mont, one_mont, exp_bytes, m, n, n0inv, cb_top_bit(exp_bytes)), m, n, n0inv)
	})

	cb_exp_out : List(I64), List(I64), I64, I64 -> List(I64)
	cb_exp_out = |acc, m, n, n0inv| cb_mont_mul(acc, cb_one(n), m, n, n0inv)

	cb_top_bit : List(I64) -> I64
	cb_top_bit = |bs| cb_top_loop(bs, ((U64.to_i64_wrap(List.len(bs)) * 8) - 1))

	cb_top_loop : List(I64), I64 -> I64
	cb_top_loop = |bs, i| (if (i < 0) { (-1) } else { (if (cb_bit_at(bs, i) == 1) { i } else { cb_top_loop(bs, (i - 1)) }) })

	cb_bit_at : List(I64), I64 -> I64
	cb_bit_at = |bs, i| ({
		byte_from_end : I64
		byte_from_end = I64.div_trunc_by(i, 8)
		idx : I64
		idx = ((U64.to_i64_wrap(List.len(bs)) - 1) - byte_from_end)
		(if (idx < 0) { 0 } else { I64.bitwise_and(I64.shr_zf_wrap((List.get(bs, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")), I64.to_u8_wrap(I64.rem_by(i, 8))), 1) })
	})

	cb_exp_bits : List(I64), List(I64), List(I64), List(I64), I64, I64, I64 -> List(I64)
	cb_exp_bits = |a_mont, acc, exp_bytes, m, n, n0inv, i| (if (i < 0) { acc } else { cb_exp_step(a_mont, cb_mont_mul(acc, acc, m, n, n0inv), exp_bytes, m, n, n0inv, i) })

	cb_exp_step : List(I64), List(I64), List(I64), List(I64), I64, I64, I64 -> List(I64)
	cb_exp_step = |a_mont, sq, exp_bytes, m, n, n0inv, i| (if (cb_bit_at(exp_bytes, i) == 1) { cb_exp_bits(a_mont, cb_mont_mul(sq, a_mont, m, n, n0inv), exp_bytes, m, n, n0inv, (i - 1)) } else { cb_exp_bits(a_mont, sq, exp_bytes, m, n, n0inv, (i - 1)) })

	cb_mod_exp_bytes : List(I64), List(I64), List(I64) -> List(I64)
	cb_mod_exp_bytes = |base_bytes, exp_bytes, mod_bytes| ({
		result : List(I64)
		result = cb_mod_exp(base_bytes, exp_bytes, mod_bytes)
		(if (U64.to_i64_wrap(List.len(result)) == 0) { [] } else { cb_to_bytes(result, U64.to_i64_wrap(List.len(mod_bytes))) })
	})
}
