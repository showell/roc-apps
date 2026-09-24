# Sixlowpan -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Sixlowpan :: [].{

	lowpan_dispatch_nalp : I64
	lowpan_dispatch_nalp = 0

	lowpan_dispatch_ipv6 : I64
	lowpan_dispatch_ipv6 = 65

	lowpan_dispatch_frag1 : I64
	lowpan_dispatch_frag1 = 192

	lowpan_dispatch_fragn : I64
	lowpan_dispatch_fragn = 224

	lowpan_dispatch_mesh : I64
	lowpan_dispatch_mesh = 128

	lowpan_iphc : I64, I64, I64, I64, I64, I64, I64, I64, I64 -> List(I64)
	lowpan_iphc = |tf, nh, hlim, cid, sac, sam, m, dac, dam| ({
		byte0 : I64
		byte0 = I64.bitwise_or(96, I64.bitwise_or(I64.shl_wrap(tf, I64.to_u8_wrap(3)), I64.bitwise_or(I64.shl_wrap(nh, I64.to_u8_wrap(2)), hlim)))
		byte1 : I64
		byte1 = I64.bitwise_or(I64.shl_wrap(cid, I64.to_u8_wrap(7)), I64.bitwise_or(I64.shl_wrap(sac, I64.to_u8_wrap(6)), I64.bitwise_or(I64.shl_wrap(sam, I64.to_u8_wrap(4)), I64.bitwise_or(I64.shl_wrap(m, I64.to_u8_wrap(3)), I64.bitwise_or(I64.shl_wrap(dac, I64.to_u8_wrap(2)), dam)))))
		[byte0, byte1]
	})

	lowpan_frag1 : I64, I64 -> List(I64)
	lowpan_frag1 = |datagram_size, tag| [I64.bitwise_or(lowpan_dispatch_frag1, I64.bitwise_and(I64.shr_zf_wrap(datagram_size, I64.to_u8_wrap(8)), 7)), I64.bitwise_and(datagram_size, 255), I64.bitwise_and(I64.shr_zf_wrap(tag, I64.to_u8_wrap(8)), 255), I64.bitwise_and(tag, 255)]

	lowpan_fragn : I64, I64, I64 -> List(I64)
	lowpan_fragn = |datagram_size, tag, offset| [I64.bitwise_or(lowpan_dispatch_fragn, I64.bitwise_and(I64.shr_zf_wrap(datagram_size, I64.to_u8_wrap(8)), 7)), I64.bitwise_and(datagram_size, 255), I64.bitwise_and(I64.shr_zf_wrap(tag, I64.to_u8_wrap(8)), 255), I64.bitwise_and(tag, 255), I64.bitwise_and(offset, 255)]
}
