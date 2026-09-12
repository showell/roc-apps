# Ieee802154 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Ieee802154 :: [].{

	ieee_type_beacon : I64
	ieee_type_beacon = 0

	ieee_type_data : I64
	ieee_type_data = 1

	ieee_type_ack : I64
	ieee_type_ack = 2

	ieee_type_command : I64
	ieee_type_command = 3

	ieee_addr_none : I64
	ieee_addr_none = 0

	ieee_addr_short : I64
	ieee_addr_short = 2

	ieee_addr_extended : I64
	ieee_addr_extended = 3

	ieee_fcf : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
	ieee_fcf = |ftype, sec, pending, ackreq, pancomp, dest_mode, frame_ver, src_mode| I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(ftype, U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(sec), U64.pow(2, I64.to_u64_wrap(3))))), I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(pending), U64.pow(2, I64.to_u64_wrap(4)))), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(ackreq), U64.pow(2, I64.to_u64_wrap(5)))))), I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(pancomp), U64.pow(2, I64.to_u64_wrap(6)))), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(dest_mode), U64.pow(2, I64.to_u64_wrap(10)))))), I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(frame_ver), U64.pow(2, I64.to_u64_wrap(12)))), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(src_mode), U64.pow(2, I64.to_u64_wrap(14))))))

	ieee_fcs : List(I64) -> I64
	ieee_fcs = |bs| ieee_fcs_loop(0, bs, 0, U64.to_i64_wrap(List.len(bs)))

	ieee_fcs_loop : I64, List(I64), I64, I64 -> I64
	ieee_fcs_loop = |crc, bs, i, len| (if (i >= len) { crc } else { ieee_fcs_loop(ieee_fcs_byte(I64.bitwise_xor(crc, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 0), bs, (i + 1), len) })

	ieee_fcs_byte : I64, I64 -> I64
	ieee_fcs_byte = |crc, k| (if (k >= 8) { crc } else { (if (I64.bitwise_and(crc, 1) == 1) { ieee_fcs_byte(I64.bitwise_xor(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(crc), U64.pow(2, I64.to_u64_wrap(1)))), 33800), (k + 1)) } else { ieee_fcs_byte(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(crc), U64.pow(2, I64.to_u64_wrap(1)))), (k + 1)) }) })

	ieee_u16_le : I64 -> List(I64)
	ieee_u16_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(v), U64.pow(2, I64.to_u64_wrap(8)))), 255)]

	ieee_build_data_short : I64, I64, I64, I64, List(I64) -> List(I64)
	ieee_build_data_short = |seq, dest_pan, dest_addr, src_addr, payload| ({
		fcf = ieee_fcf(ieee_type_data, 0, 0, 0, 1, ieee_addr_short, 0, ieee_addr_short)
		mhr = List.concat(List.concat(List.concat(List.concat(List.concat(ieee_u16_le(fcf), [seq]), ieee_u16_le(dest_pan)), ieee_u16_le(dest_addr)), ieee_u16_le(src_addr)), payload)
		List.concat(mhr, ieee_u16_le(ieee_fcs(mhr)))
	})
}
