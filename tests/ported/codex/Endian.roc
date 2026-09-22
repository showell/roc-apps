# Endian -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Endian :: [].{

	to_big_endian_16 : I64 -> I64
	to_big_endian_16 = |x| I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(x, 255), I64.to_u8_wrap(8)), I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(8)), 255))

	from_big_endian_16 : I64 -> I64
	from_big_endian_16 = |x| I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(x, 255), I64.to_u8_wrap(8)), I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(8)), 255))

	to_big_endian_32 : I64 -> I64
	to_big_endian_32 = |x| ({
		b0 = I64.bitwise_and(x, 255)
		b1 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(8)), 255)
		b2 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(16)), 255)
		b3 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(24)), 255)
		I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(b0, I64.to_u8_wrap(24)), I64.shl_wrap(b1, I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(b2, I64.to_u8_wrap(8)), b3))
	})

	from_big_endian_32 : I64 -> I64
	from_big_endian_32 = |x| to_big_endian_32(x)

	to_big_endian_64 : I64 -> I64
	to_big_endian_64 = |x| ({
		b0 = I64.bitwise_and(x, 255)
		b1 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(8)), 255)
		b2 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(16)), 255)
		b3 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(24)), 255)
		b4 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(32)), 255)
		b5 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(40)), 255)
		b6 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(48)), 255)
		b7 = I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(56)), 255)
		I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(b0, I64.to_u8_wrap(56)), I64.shl_wrap(b1, I64.to_u8_wrap(48))), I64.bitwise_or(I64.shl_wrap(b2, I64.to_u8_wrap(40)), I64.shl_wrap(b3, I64.to_u8_wrap(32)))), I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(b4, I64.to_u8_wrap(24)), I64.shl_wrap(b5, I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(b6, I64.to_u8_wrap(8)), b7)))
	})

	from_big_endian_64 : I64 -> I64
	from_big_endian_64 = |x| to_big_endian_64(x)

	pack_u16_be : I64, I64 -> I64
	pack_u16_be = |hi, lo| I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(hi, 255), I64.to_u8_wrap(8)), I64.bitwise_and(lo, 255))

	pack_u32_be : I64, I64, I64, I64 -> I64
	pack_u32_be = |b3, b2, b1, b0| I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(b3, 255), I64.to_u8_wrap(24)), I64.shl_wrap(I64.bitwise_and(b2, 255), I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(I64.bitwise_and(b1, 255), I64.to_u8_wrap(8)), I64.bitwise_and(b0, 255)))

	unpack_u16_be_hi : I64 -> I64
	unpack_u16_be_hi = |x| I64.bitwise_and(I64.shr_zf_wrap(x, I64.to_u8_wrap(8)), 255)

	unpack_u16_be_lo : I64 -> I64
	unpack_u16_be_lo = |x| I64.bitwise_and(x, 255)
}
