# S7comm -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

S7comm :: [].{

	s7_u16_be : I64 -> List(I64)
	s7_u16_be = |v| [I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)]

	s7_tpkt : List(I64) -> List(I64)
	s7_tpkt = |payload| List.concat(List.concat([3, 0], s7_u16_be((4 + U64.to_i64_wrap(List.len(payload))))), payload)

	s7_cotp_dt : List(I64)
	s7_cotp_dt = [2, 240, 128]

	s7_cotp_cr_params : I64, List(I64), List(I64) -> List(I64)
	s7_cotp_cr_params = |tpdu_size, src_tsap, dst_tsap| List.concat(List.concat(List.concat(List.concat([192, 1, tpdu_size], [193, U64.to_i64_wrap(List.len(src_tsap))]), src_tsap), [194, U64.to_i64_wrap(List.len(dst_tsap))]), dst_tsap)

	s7_cotp_cr : I64, I64, I64, List(I64), List(I64) -> List(I64)
	s7_cotp_cr = |src_ref, dst_ref, tpdu_size, src_tsap, dst_tsap| ({
		body = List.concat(List.concat(List.concat(List.concat([224], s7_u16_be(dst_ref)), s7_u16_be(src_ref)), [0]), s7_cotp_cr_params(tpdu_size, src_tsap, dst_tsap))
		List.concat([U64.to_i64_wrap(List.len(body))], body)
	})

	s7_rosctr_job : I64
	s7_rosctr_job = 1

	s7_header : I64, I64, I64, I64 -> List(I64)
	s7_header = |rosctr, pdu_ref, param_len, data_len| List.concat(List.concat(List.concat(List.concat([50, rosctr], s7_u16_be(0)), s7_u16_be(pdu_ref)), s7_u16_be(param_len)), s7_u16_be(data_len))

	s7_setup : I64, I64, I64, I64 -> List(I64)
	s7_setup = |pdu_ref, max_called, max_calling, pdu_size| ({
		param = List.concat(List.concat(List.concat([240, 0], s7_u16_be(max_called)), s7_u16_be(max_calling)), s7_u16_be(pdu_size))
		List.concat(s7_header(s7_rosctr_job, pdu_ref, U64.to_i64_wrap(List.len(param)), 0), param)
	})

	s7_area_input : I64
	s7_area_input = 129

	s7_area_output : I64
	s7_area_output = 130

	s7_area_flag : I64
	s7_area_flag = 131

	s7_area_db : I64
	s7_area_db = 132

	s7_addr3 : I64 -> List(I64)
	s7_addr3 = |bit_addr| [I64.bitwise_and(I64.shr_zf_wrap(bit_addr, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(bit_addr, I64.to_u8_wrap(8)), 255), I64.bitwise_and(bit_addr, 255)]

	s7_read_item : I64, I64, I64, I64 -> List(I64)
	s7_read_item = |area, db, count, start_byte| List.concat(List.concat(List.concat(List.concat([18, 10, 16, 2], s7_u16_be(count)), s7_u16_be(db)), [area]), s7_addr3((start_byte * 8)))

	s7_read_var_single : I64, List(I64) -> List(I64)
	s7_read_var_single = |pdu_ref, item| ({
		param = List.concat([4, 1], item)
		List.concat(s7_header(s7_rosctr_job, pdu_ref, U64.to_i64_wrap(List.len(param)), 0), param)
	})
}
