# J1939 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

J1939 :: [].{

	j1939_can_id : I64, I64, I64, I64 -> I64
	j1939_can_id = |priority, pf, ps, source_addr| I64.bitwise_or(I64.bitwise_or(I64.shl_wrap(priority, I64.to_u8_wrap(26)), I64.shl_wrap(pf, I64.to_u8_wrap(16))), I64.bitwise_or(I64.shl_wrap(ps, I64.to_u8_wrap(8)), source_addr))

	j1939_pgn_pdu2 : I64, I64 -> I64
	j1939_pgn_pdu2 = |pf, ps| I64.bitwise_or(I64.shl_wrap(pf, I64.to_u8_wrap(8)), ps)

	j1939_pgn_pdu1 : I64 -> I64
	j1939_pgn_pdu1 = |pf| I64.shl_wrap(pf, I64.to_u8_wrap(8))

	j1939_is_pdu1 : I64 -> Bool
	j1939_is_pdu1 = |pf| (pf < 240)

	j1939_priority : I64 -> I64
	j1939_priority = |can_id| I64.bitwise_and(I64.shr_zf_wrap(can_id, I64.to_u8_wrap(26)), 7)

	j1939_pf : I64 -> I64
	j1939_pf = |can_id| I64.bitwise_and(I64.shr_zf_wrap(can_id, I64.to_u8_wrap(16)), 255)

	j1939_ps : I64 -> I64
	j1939_ps = |can_id| I64.bitwise_and(I64.shr_zf_wrap(can_id, I64.to_u8_wrap(8)), 255)

	j1939_source_addr : I64 -> I64
	j1939_source_addr = |can_id| I64.bitwise_and(can_id, 255)

	j1939_pgn : I64 -> I64
	j1939_pgn = |can_id| ({
		pf = j1939_pf(can_id)
		(if j1939_is_pdu1(pf) { j1939_pgn_pdu1(pf) } else { j1939_pgn_pdu2(pf, j1939_ps(can_id)) })
	})

	j1939_pgn_request : I64
	j1939_pgn_request = 59904

	j1939_pgn_tp_cm : I64
	j1939_pgn_tp_cm = 60416

	j1939_pgn_tp_dt : I64
	j1939_pgn_tp_dt = 60160

	j1939_pgn_address_claim : I64
	j1939_pgn_address_claim = 60928

	j1939_pgn_engine_hours : I64
	j1939_pgn_engine_hours = 65253

	j1939_pgn_engine_temp : I64
	j1939_pgn_engine_temp = 65262

	j1939_addr_global : I64
	j1939_addr_global = 255

	j1939_addr_null : I64
	j1939_addr_null = 254
}
