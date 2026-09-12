# Dnp3 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Dnp3 :: [].{

	dnp3_crc16 : List(I64) -> I64
	dnp3_crc16 = |bs| I64.bitwise_xor(dnp3_crc_loop(0, bs, 0, U64.to_i64_wrap(List.len(bs))), 65535)

	dnp3_crc_loop : I64, List(I64), I64, I64 -> I64
	dnp3_crc_loop = |crc, bs, i, len| (if (i >= len) { crc } else { dnp3_crc_loop(dnp3_crc_byte(I64.bitwise_xor(crc, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 0), bs, (i + 1), len) })

	dnp3_crc_byte : I64, I64 -> I64
	dnp3_crc_byte = |crc, k| (if (k >= 8) { crc } else { (if (I64.bitwise_and(crc, 1) == 1) { dnp3_crc_byte(I64.bitwise_xor(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(crc), U64.pow(2, I64.to_u64_wrap(1)))), 42684), (k + 1)) } else { dnp3_crc_byte(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(crc), U64.pow(2, I64.to_u64_wrap(1)))), (k + 1)) }) })

	dnp3_u16_le : I64 -> List(I64)
	dnp3_u16_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(v), U64.pow(2, I64.to_u64_wrap(8)))), 255)]

	dnp3_crc_suffix : List(I64) -> List(I64)
	dnp3_crc_suffix = |bs| dnp3_u16_le(dnp3_crc16(bs))

	dnp3_slice : List(I64), I64, I64 -> List(I64)
	dnp3_slice = |data, off, count| dnp3_slice_loop(data, off, count, 0, [])

	dnp3_slice_loop : List(I64), I64, I64, I64, List(I64) -> List(I64)
	dnp3_slice_loop = |data, off, count, i, acc| (if (i >= count) { acc } else { dnp3_slice_loop(data, off, count, (i + 1), List.append(acc, (List.get(data, I64.to_u64_wrap((off + i))) ?? crash("list-at out of range")))) })

	dnp3_ctrl_reset_link : I64
	dnp3_ctrl_reset_link = 192

	dnp3_ctrl_test_link : I64
	dnp3_ctrl_test_link = 194

	dnp3_ctrl_confirmed_data : I64
	dnp3_ctrl_confirmed_data = 195

	dnp3_ctrl_unconfirmed_data : I64
	dnp3_ctrl_unconfirmed_data = 196

	dnp3_ctrl_request_status : I64
	dnp3_ctrl_request_status = 201

	dnp3_start_1 : I64
	dnp3_start_1 = 5

	dnp3_start_2 : I64
	dnp3_start_2 = 100

	dnp3_header : I64, I64, I64, I64 -> List(I64)
	dnp3_header = |ctrl, dest, src, datalen| List.concat(List.concat([dnp3_start_1, dnp3_start_2, (5 + datalen), ctrl], dnp3_u16_le(dest)), dnp3_u16_le(src))

	dnp3_header_block : I64, I64, I64, I64 -> List(I64)
	dnp3_header_block = |ctrl, dest, src, datalen| ({
		h = dnp3_header(ctrl, dest, src, datalen)
		List.concat(h, dnp3_crc_suffix(h))
	})

	dnp3_data_blocks : List(I64) -> List(I64)
	dnp3_data_blocks = |data| dnp3_data_loop(data, 0, U64.to_i64_wrap(List.len(data)), [])

	dnp3_data_loop : List(I64), I64, I64, List(I64) -> List(I64)
	dnp3_data_loop = |data, off, len, acc| (if (off >= len) { acc } else { ({
		count = (if ((len - off) < 16) { (len - off) } else { 16 })
		chunk = dnp3_slice(data, off, count)
		dnp3_data_loop(data, (off + 16), len, List.concat(List.concat(acc, chunk), dnp3_crc_suffix(chunk)))
	}) })

	dnp3_app_fc_read : I64
	dnp3_app_fc_read = 1

	dnp3_app_fc_write : I64
	dnp3_app_fc_write = 2

	dnp3_app_fc_select : I64
	dnp3_app_fc_select = 3

	dnp3_app_fc_operate : I64
	dnp3_app_fc_operate = 4

	dnp3_app_fc_direct_operate : I64
	dnp3_app_fc_direct_operate = 5

	dnp3_app_fc_cold_restart : I64
	dnp3_app_fc_cold_restart = 13

	dnp3_app_header : I64, I64 -> List(I64)
	dnp3_app_header = |seq, function| [I64.bitwise_or(192, seq), function]

	dnp3_obj_all : I64, I64 -> List(I64)
	dnp3_obj_all = |group, variation| [group, variation, 6]

	dnp3_obj_range8 : I64, I64, I64, I64 -> List(I64)
	dnp3_obj_range8 = |group, variation, start, stop| [group, variation, 0, start, stop]

	dnp3_read_class : I64, I64 -> List(I64)
	dnp3_read_class = |seq, class_variation| List.concat(dnp3_app_header(seq, dnp3_app_fc_read), dnp3_obj_all(60, class_variation))

	dnp3_read_range : I64, I64, I64, I64, I64 -> List(I64)
	dnp3_read_range = |seq, group, variation, start, stop| List.concat(dnp3_app_header(seq, dnp3_app_fc_read), dnp3_obj_range8(group, variation, start, stop))

	dnp3_build_frame : I64, I64, I64, List(I64) -> List(I64)
	dnp3_build_frame = |ctrl, dest, src, data| List.concat(dnp3_header_block(ctrl, dest, src, U64.to_i64_wrap(List.len(data))), dnp3_data_blocks(data))
}
