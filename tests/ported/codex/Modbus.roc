# Modbus -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Modbus :: [].{

	modbus_fc_read_coils : I64
	modbus_fc_read_coils = 1

	modbus_fc_read_discrete_inputs : I64
	modbus_fc_read_discrete_inputs = 2

	modbus_fc_read_holding_registers : I64
	modbus_fc_read_holding_registers = 3

	modbus_fc_read_input_registers : I64
	modbus_fc_read_input_registers = 4

	modbus_fc_write_single_coil : I64
	modbus_fc_write_single_coil = 5

	modbus_fc_write_single_register : I64
	modbus_fc_write_single_register = 6

	modbus_fc_write_multiple_coils : I64
	modbus_fc_write_multiple_coils = 15

	modbus_fc_write_multiple_registers : I64
	modbus_fc_write_multiple_registers = 16

	modbus_fc_read_exception_status : I64
	modbus_fc_read_exception_status = 7

	modbus_fc_diagnostics : I64
	modbus_fc_diagnostics = 8

	modbus_fc_mask_write_register : I64
	modbus_fc_mask_write_register = 22

	modbus_fc_read_write_multiple_registers : I64
	modbus_fc_read_write_multiple_registers = 23

	modbus_ex_illegal_function : I64
	modbus_ex_illegal_function = 1

	modbus_ex_illegal_data_address : I64
	modbus_ex_illegal_data_address = 2

	modbus_ex_illegal_data_value : I64
	modbus_ex_illegal_data_value = 3

	modbus_ex_server_device_failure : I64
	modbus_ex_server_device_failure = 4

	modbus_u16 : I64 -> List(I64)
	modbus_u16 = |v| [I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)]

	modbus_crc16 : List(I64) -> I64
	modbus_crc16 = |bs| modbus_crc16_update(65535, bs, 0, U64.to_i64_wrap(List.len(bs)))

	modbus_crc16_update : I64, List(I64), I64, I64 -> I64
	modbus_crc16_update = |crc, bs, i, len| (if (i >= len) { crc } else { modbus_crc16_update(modbus_crc16_byte(I64.bitwise_xor(crc, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), 0), bs, (i + 1), len) })

	modbus_crc16_byte : I64, I64 -> I64
	modbus_crc16_byte = |crc, k| (if (k >= 8) { crc } else { (if (I64.bitwise_and(crc, 1) == 1) { modbus_crc16_byte(I64.bitwise_xor(I64.shr_zf_wrap(crc, I64.to_u8_wrap(1)), 40961), (k + 1)) } else { modbus_crc16_byte(I64.shr_zf_wrap(crc, I64.to_u8_wrap(1)), (k + 1)) }) })

	modbus_read_coils : I64, I64 -> List(I64)
	modbus_read_coils = |start, qty| List.concat(List.concat([modbus_fc_read_coils], modbus_u16(start)), modbus_u16(qty))

	modbus_read_discrete_inputs : I64, I64 -> List(I64)
	modbus_read_discrete_inputs = |start, qty| List.concat(List.concat([modbus_fc_read_discrete_inputs], modbus_u16(start)), modbus_u16(qty))

	modbus_read_holding_registers : I64, I64 -> List(I64)
	modbus_read_holding_registers = |start, qty| List.concat(List.concat([modbus_fc_read_holding_registers], modbus_u16(start)), modbus_u16(qty))

	modbus_read_input_registers : I64, I64 -> List(I64)
	modbus_read_input_registers = |start, qty| List.concat(List.concat([modbus_fc_read_input_registers], modbus_u16(start)), modbus_u16(qty))

	modbus_write_single_coil : I64, Bool -> List(I64)
	modbus_write_single_coil = |addr, on| List.concat(List.concat([modbus_fc_write_single_coil], modbus_u16(addr)), modbus_u16((if on { 65280 } else { 0 })))

	modbus_write_single_register : I64, I64 -> List(I64)
	modbus_write_single_register = |addr, value| List.concat(List.concat([modbus_fc_write_single_register], modbus_u16(addr)), modbus_u16(value))

	modbus_write_multiple_registers : I64, List(I64) -> List(I64)
	modbus_write_multiple_registers = |start, values| ({
		qty = U64.to_i64_wrap(List.len(values))
		byte_count = (qty * 2)
		List.concat(List.concat(List.concat(List.concat([modbus_fc_write_multiple_registers], modbus_u16(start)), modbus_u16(qty)), [byte_count]), modbus_encode_registers(values, 0, qty, []))
	})

	modbus_encode_registers : List(I64), I64, I64, List(I64) -> List(I64)
	modbus_encode_registers = |values, i, len, acc| (if (i >= len) { acc } else { modbus_encode_registers(values, (i + 1), len, List.concat(acc, modbus_u16((List.get(values, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	modbus_write_multiple_coils : I64, List(Bool) -> List(I64)
	modbus_write_multiple_coils = |start, coils| ({
		qty = U64.to_i64_wrap(List.len(coils))
		byte_count = I64.shr_zf_wrap((qty + 7), I64.to_u8_wrap(3))
		List.concat(List.concat(List.concat(List.concat([modbus_fc_write_multiple_coils], modbus_u16(start)), modbus_u16(qty)), [byte_count]), modbus_pack_coils(coils, 0, byte_count, []))
	})

	modbus_pack_coils : List(Bool), I64, I64, List(I64) -> List(I64)
	modbus_pack_coils = |coils, b, byte_count, acc| (if (b >= byte_count) { acc } else { modbus_pack_coils(coils, (b + 1), byte_count, List.append(acc, modbus_pack_byte(coils, (b * 8), 0, 0, U64.to_i64_wrap(List.len(coils))))) })

	modbus_pack_byte : List(Bool), I64, I64, I64, I64 -> I64
	modbus_pack_byte = |coils, base, bit, acc, qty| (if (bit >= 8) { acc } else { ({
		idx = (base + bit)
		set = (if (idx >= qty) { 0 } else { (if (List.get(coils, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")) { I64.shl_wrap(1, I64.to_u8_wrap(bit)) } else { 0 }) })
		modbus_pack_byte(coils, base, (bit + 1), I64.bitwise_or(acc, set), qty)
	}) })

	modbus_read_exception_status : List(I64)
	modbus_read_exception_status = [modbus_fc_read_exception_status]

	modbus_mask_write_register : I64, I64, I64 -> List(I64)
	modbus_mask_write_register = |addr, and_mask, or_mask| List.concat(List.concat(List.concat([modbus_fc_mask_write_register], modbus_u16(addr)), modbus_u16(and_mask)), modbus_u16(or_mask))

	modbus_read_write_multiple_registers : I64, I64, I64, List(I64) -> List(I64)
	modbus_read_write_multiple_registers = |read_start, read_qty, write_start, write_values| ({
		qty = U64.to_i64_wrap(List.len(write_values))
		List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([modbus_fc_read_write_multiple_registers], modbus_u16(read_start)), modbus_u16(read_qty)), modbus_u16(write_start)), modbus_u16(qty)), [(qty * 2)]), modbus_encode_registers(write_values, 0, qty, []))
	})

	modbus_rtu_frame : I64, List(I64) -> List(I64)
	modbus_rtu_frame = |unit_id, pdu| ({
		body = List.concat([unit_id], pdu)
		crc = modbus_crc16(body)
		List.concat(body, [I64.bitwise_and(crc, 255), I64.bitwise_and(I64.shr_zf_wrap(crc, I64.to_u8_wrap(8)), 255)])
	})

	modbus_rtu_check : List(I64) -> Bool
	modbus_rtu_check = |frame| (modbus_crc16(frame) == 0)

	modbus_sum : List(I64), I64, I64, I64 -> I64
	modbus_sum = |bytes, i, len, acc| (if (i >= len) { acc } else { modbus_sum(bytes, (i + 1), len, (acc + (List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	modbus_lrc : List(I64) -> I64
	modbus_lrc = |bytes| I64.bitwise_and((256 - I64.bitwise_and(modbus_sum(bytes, 0, U64.to_i64_wrap(List.len(bytes)), 0), 255)), 255)

	modbus_ascii_nibble : I64 -> I64
	modbus_ascii_nibble = |n| (if (n < 10) { (n + 48) } else { (n + 55) })

	modbus_ascii_hex_byte : I64 -> List(I64)
	modbus_ascii_hex_byte = |b| [modbus_ascii_nibble(I64.shr_zf_wrap(b, I64.to_u8_wrap(4))), modbus_ascii_nibble(I64.bitwise_and(b, 15))]

	modbus_ascii_hex : List(I64), I64, I64, List(I64) -> List(I64)
	modbus_ascii_hex = |bytes, i, len, acc| (if (i >= len) { acc } else { modbus_ascii_hex(bytes, (i + 1), len, List.concat(acc, modbus_ascii_hex_byte((List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	modbus_ascii_frame : I64, List(I64) -> List(I64)
	modbus_ascii_frame = |unit_id, pdu| ({
		content = List.concat([unit_id], pdu)
		full = List.concat(content, [modbus_lrc(content)])
		List.concat(List.concat([58], modbus_ascii_hex(full, 0, U64.to_i64_wrap(List.len(full)), [])), [13, 10])
	})

	modbus_tcp_frame : I64, I64, List(I64) -> List(I64)
	modbus_tcp_frame = |txn, unit_id, pdu| ({
		length = (U64.to_i64_wrap(List.len(pdu)) + 1)
		List.concat(List.concat(List.concat(List.concat(modbus_u16(txn), [0, 0]), modbus_u16(length)), [unit_id]), pdu)
	})

	modbus_parse_registers : List(I64) -> List(I64)
	modbus_parse_registers = |pdu| ({
		count = (List.get(pdu, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))
		modbus_parse_registers_loop(pdu, 2, (2 + count), [])
	})

	modbus_parse_registers_loop : List(I64), I64, I64, List(I64) -> List(I64)
	modbus_parse_registers_loop = |pdu, i, stop, acc| (if (i >= stop) { acc } else { modbus_parse_registers_loop(pdu, (i + 2), stop, List.append(acc, I64.bitwise_or(I64.shl_wrap((List.get(pdu, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), I64.to_u8_wrap(8)), (List.get(pdu, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range"))))) })

	modbus_parse_coils : List(I64), I64 -> List(Bool)
	modbus_parse_coils = |pdu, quantity| modbus_parse_coils_loop(pdu, quantity, 0, [])

	modbus_parse_coils_loop : List(I64), I64, I64, List(Bool) -> List(Bool)
	modbus_parse_coils_loop = |pdu, quantity, i, acc| (if (i >= quantity) { acc } else { modbus_parse_coils_loop(pdu, quantity, (i + 1), List.append(acc, (I64.bitwise_and(I64.shr_zf_wrap((List.get(pdu, I64.to_u64_wrap((2 + I64.shr_zf_wrap(i, I64.to_u8_wrap(3))))) ?? crash("list-at out of range")), I64.to_u8_wrap(I64.bitwise_and(i, 7))), 1) == 1))) })

	modbus_is_exception : List(I64) -> Bool
	modbus_is_exception = |pdu| ((List.get(pdu, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) >= 128)

	modbus_exception_code : List(I64) -> I64
	modbus_exception_code = |pdu| (List.get(pdu, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))

	modbus_exception_pdu : I64, I64 -> List(I64)
	modbus_exception_pdu = |fc, code| [I64.bitwise_or(fc, 128), code]
}
