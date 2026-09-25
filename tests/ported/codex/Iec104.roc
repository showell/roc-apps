# Iec104 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Iec104 :: [].{

	i104_u16_le : I64 -> List(I64)
	i104_u16_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255)]

	i104_u24_le : I64 -> List(I64)
	i104_u24_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255)]

	i104_f32_le : F32 -> List(I64)
	i104_f32_le = |v| ({
		b : I64
		b = U32.to_i64(F32.to_bits(v))
		[I64.bitwise_and(b, 255), I64.bitwise_and(I64.shr_zf_wrap(b, I64.to_u8_wrap(8)), 255), I64.bitwise_and(I64.shr_zf_wrap(b, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(b, I64.to_u8_wrap(24)), 255)]
	})

	i104_ctrl_i : I64, I64 -> List(I64)
	i104_ctrl_i = |ns, nr| [I64.bitwise_and((ns * 2), 254), I64.bitwise_and(I64.shr_zf_wrap(ns, I64.to_u8_wrap(7)), 255), I64.bitwise_and((nr * 2), 254), I64.bitwise_and(I64.shr_zf_wrap(nr, I64.to_u8_wrap(7)), 255)]

	i104_ctrl_s : I64 -> List(I64)
	i104_ctrl_s = |nr| [1, 0, I64.bitwise_and((nr * 2), 254), I64.bitwise_and(I64.shr_zf_wrap(nr, I64.to_u8_wrap(7)), 255)]

	i104_ctrl_u : I64 -> List(I64)
	i104_ctrl_u = |func| [func, 0, 0, 0]

	i104_u_startdt_act : I64
	i104_u_startdt_act = 7

	i104_u_startdt_con : I64
	i104_u_startdt_con = 11

	i104_u_stopdt_act : I64
	i104_u_stopdt_act = 19

	i104_u_stopdt_con : I64
	i104_u_stopdt_con = 35

	i104_u_testfr_act : I64
	i104_u_testfr_act = 67

	i104_u_testfr_con : I64
	i104_u_testfr_con = 131

	i104_start : I64
	i104_start = 104

	i104_apdu : List(I64), List(I64) -> List(I64)
	i104_apdu = |ctrl, asdu| List.concat(List.concat([i104_start, (4 + U64.to_i64_wrap(List.len(asdu)))], ctrl), asdu)

	i104_frame_i : I64, I64, List(I64) -> List(I64)
	i104_frame_i = |ns, nr, asdu| i104_apdu(i104_ctrl_i(ns, nr), asdu)

	i104_frame_s : I64 -> List(I64)
	i104_frame_s = |nr| i104_apdu(i104_ctrl_s(nr), [])

	i104_frame_u : I64 -> List(I64)
	i104_frame_u = |func| i104_apdu(i104_ctrl_u(func), [])

	i104_vsq : Bool, I64 -> I64
	i104_vsq = |sq, num| I64.bitwise_or((if sq { 128 } else { 0 }), I64.bitwise_and(num, 127))

	i104_asdu_header : I64, I64, I64, I64, I64 -> List(I64)
	i104_asdu_header = |typ, vsq, cot, org, ca| List.concat([typ, vsq, cot, org], i104_u16_le(ca))

	i104_cot_spontaneous : I64
	i104_cot_spontaneous = 3

	i104_cot_request : I64
	i104_cot_request = 5

	i104_cot_activation : I64
	i104_cot_activation = 6

	i104_cot_activation_con : I64
	i104_cot_activation_con = 7

	i104_cot_inrogen : I64
	i104_cot_inrogen = 20

	i104_io_single_point : I64, I64 -> List(I64)
	i104_io_single_point = |ioa, siq| List.concat(i104_u24_le(ioa), [siq])

	i104_io_single_command : I64, I64 -> List(I64)
	i104_io_single_command = |ioa, sco| List.concat(i104_u24_le(ioa), [sco])

	i104_io_measured_short_float : I64, F32, I64 -> List(I64)
	i104_io_measured_short_float = |ioa, value, qds| List.concat(List.concat(i104_u24_le(ioa), i104_f32_le(value)), [qds])

	i104_io_interrogation : I64, I64 -> List(I64)
	i104_io_interrogation = |ioa, qoi| List.concat(i104_u24_le(ioa), [qoi])

	i104_type_single_point : I64
	i104_type_single_point = 1

	i104_type_measured_short_float : I64
	i104_type_measured_short_float = 13

	i104_type_single_command : I64
	i104_type_single_command = 45

	i104_type_interrogation : I64
	i104_type_interrogation = 100

	i104_qoi_station : I64
	i104_qoi_station = 20
}
