# BitOps -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

BitOps :: [].{

	bit_popcount : I64 -> I64
	bit_popcount = |x| ({
		m1 : I64
		m1 = 6148914691236517205
		m2 : I64
		m2 = 3689348814741910323
		m4 : I64
		m4 = 1085102592571150095
		h01 : I64
		h01 = 72340172838076673
		a : I64
		a = (x - I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(1)), m1))
		b : I64
		b = (I64.bitwise_and(a, m2) + I64.bitwise_and(I64.shr_zf_wrap(a, I64.to_u8_wrap(2)), m2))
		c : I64
		c = I64.bitwise_and((b + I64.shr_zf_wrap(b, I64.to_u8_wrap(4))), m4)
		I64.shr_zf_wrap((c * h01), I64.to_u8_wrap(56))
	})

	bit_clz : I64 -> I64
	bit_clz = |x| (if (x == 0) { 64 } else { ({
		n0 : I64
		n0 = 0
		x1 : I64
		x1 = (if (I64.bitwise_and(x, (0 - 4294967296)) == 0) { I64.shl_wrap(x, I64.to_u8_wrap(32)) } else { x })
		n1 : I64
		n1 = (if (I64.bitwise_and(x, (0 - 4294967296)) == 0) { (n0 + 32) } else { n0 })
		x2 : I64
		x2 = (if (I64.bitwise_and(x1, (0 - 281474976710656)) == 0) { I64.shl_wrap(x1, I64.to_u8_wrap(16)) } else { x1 })
		n2 : I64
		n2 = (if (I64.bitwise_and(x1, (0 - 281474976710656)) == 0) { (n1 + 16) } else { n1 })
		x3 : I64
		x3 = (if (I64.bitwise_and(x2, (0 - 72057594037927936)) == 0) { I64.shl_wrap(x2, I64.to_u8_wrap(8)) } else { x2 })
		n3 : I64
		n3 = (if (I64.bitwise_and(x2, (0 - 72057594037927936)) == 0) { (n2 + 8) } else { n2 })
		x4 : I64
		x4 = (if (I64.bitwise_and(x3, (0 - 1152921504606846976)) == 0) { I64.shl_wrap(x3, I64.to_u8_wrap(4)) } else { x3 })
		n4 : I64
		n4 = (if (I64.bitwise_and(x3, (0 - 1152921504606846976)) == 0) { (n3 + 4) } else { n3 })
		x5 : I64
		x5 = (if (I64.bitwise_and(x4, (0 - 4611686018427387904)) == 0) { I64.shl_wrap(x4, I64.to_u8_wrap(2)) } else { x4 })
		n5 : I64
		n5 = (if (I64.bitwise_and(x4, (0 - 4611686018427387904)) == 0) { (n4 + 2) } else { n4 })
		(if (I64.shr_zf_wrap(x5, I64.to_u8_wrap(63)) == 0) { (n5 + 1) } else { n5 })
	}) })

	bit_ctz : I64 -> I64
	bit_ctz = |x| (if (x == 0) { 64 } else { bit_popcount(I64.bitwise_and((x - 1), I64.bitwise_not(x))) })

	is_power_of_two : I64 -> Bool
	is_power_of_two = |x| ((x > 0) and (I64.bitwise_and(x, (x - 1)) == 0))

	next_power_of_two : I64 -> I64
	next_power_of_two = |x| (if (x <= 1) { 1 } else { ({
		v : I64
		v = (x - 1)
		v1 : I64
		v1 = I64.bitwise_or(v, I64.shr_zf_wrap(v, I64.to_u8_wrap(1)))
		v2 : I64
		v2 = I64.bitwise_or(v1, I64.shr_zf_wrap(v1, I64.to_u8_wrap(2)))
		v3 : I64
		v3 = I64.bitwise_or(v2, I64.shr_zf_wrap(v2, I64.to_u8_wrap(4)))
		v4 : I64
		v4 = I64.bitwise_or(v3, I64.shr_zf_wrap(v3, I64.to_u8_wrap(8)))
		v5 : I64
		v5 = I64.bitwise_or(v4, I64.shr_zf_wrap(v4, I64.to_u8_wrap(16)))
		v6 : I64
		v6 = I64.bitwise_or(v5, I64.shr_zf_wrap(v5, I64.to_u8_wrap(32)))
		(v6 + 1)
	}) })

	bit_rotate_left : I64, I64 -> I64
	bit_rotate_left = |x, n| ({
		s : I64
		s = I64.bitwise_and(n, 63)
		I64.bitwise_or(I64.shl_wrap(x, I64.to_u8_wrap(s)), I64.shr_zf_wrap(x, I64.to_u8_wrap((64 - s))))
	})

	bit_rotate_right : I64, I64 -> I64
	bit_rotate_right = |x, n| ({
		s : I64
		s = I64.bitwise_and(n, 63)
		I64.bitwise_or(I64.shr_zf_wrap(x, I64.to_u8_wrap(s)), I64.shl_wrap(x, I64.to_u8_wrap((64 - s))))
	})

	byte_swap_32 : I64 -> I64
	byte_swap_32 = |x| ({
		b0 : I64
		b0 = I64.bitwise_and(x, 255)
		b1 : I64
		b1 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(8)), 255)
		b2 : I64
		b2 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(16)), 255)
		b3 : I64
		b3 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(24)), 255)
		I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(b0, I64.to_u8_wrap(24)), I64.shl_wrap(b1, I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(b2, I64.to_u8_wrap(8)), b3))
	})

	byte_swap_64 : I64 -> I64
	byte_swap_64 = |x| ({
		b0 : I64
		b0 = I64.bitwise_and(x, 255)
		b1 : I64
		b1 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(8)), 255)
		b2 : I64
		b2 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(16)), 255)
		b3 : I64
		b3 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(24)), 255)
		b4 : I64
		b4 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(32)), 255)
		b5 : I64
		b5 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(40)), 255)
		b6 : I64
		b6 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(48)), 255)
		b7 : I64
		b7 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(56)), 255)
		I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(b0, I64.to_u8_wrap(56)), I64.shl_wrap(b1, I64.to_u8_wrap(48))), I64.bitwise_or(I64.shl_wrap(b2, I64.to_u8_wrap(40)), I64.shl_wrap(b3, I64.to_u8_wrap(32)))), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(b4, I64.to_u8_wrap(24)), I64.shl_wrap(b5, I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(b6, I64.to_u8_wrap(8)), b7)))
	})

	extract_byte : I64, I64 -> I64
	extract_byte = |x, n| I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap((n * 8))), 255)
}
