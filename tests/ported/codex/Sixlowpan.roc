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
		byte0 = I64.bitwise_or(96, I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(tf), U64.pow(2, I64.to_u64_wrap(3)))), I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(nh), U64.pow(2, I64.to_u64_wrap(2)))), hlim)))
		byte1 = I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(cid), U64.pow(2, I64.to_u64_wrap(7)))), I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(sac), U64.pow(2, I64.to_u64_wrap(6)))), I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(sam), U64.pow(2, I64.to_u64_wrap(4)))), I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(m), U64.pow(2, I64.to_u64_wrap(3)))), I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(dac), U64.pow(2, I64.to_u64_wrap(2)))), dam)))))
		[byte0, byte1]
	})

	lowpan_frag1 : I64, I64 -> List(I64)
	lowpan_frag1 = |datagram_size, tag| [I64.bitwise_or(lowpan_dispatch_frag1, I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(datagram_size), U64.pow(2, I64.to_u64_wrap(8)))), 7)), I64.bitwise_and(datagram_size, 255), I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(tag), U64.pow(2, I64.to_u64_wrap(8)))), 255), I64.bitwise_and(tag, 255)]

	lowpan_fragn : I64, I64, I64 -> List(I64)
	lowpan_fragn = |datagram_size, tag, offset| [I64.bitwise_or(lowpan_dispatch_fragn, I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(datagram_size), U64.pow(2, I64.to_u64_wrap(8)))), 7)), I64.bitwise_and(datagram_size, 255), I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(tag), U64.pow(2, I64.to_u64_wrap(8)))), 255), I64.bitwise_and(tag, 255), I64.bitwise_and(offset, 255)]
}
