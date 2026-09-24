# Hart -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Hart :: [].{

	hart_delim_stx_short : I64
	hart_delim_stx_short = 2

	hart_delim_ack_short : I64
	hart_delim_ack_short = 6

	hart_delim_stx_long : I64
	hart_delim_stx_long = 130

	hart_delim_ack_long : I64
	hart_delim_ack_long = 134

	hart_preamble : I64 -> List(I64)
	hart_preamble = |n| hart_preamble_loop(n, [])

	hart_preamble_loop : I64, List(I64) -> List(I64)
	hart_preamble_loop = |n, acc| (if (n <= 0) { acc } else { hart_preamble_loop((n - 1), List.append(acc, 255)) })

	hart_checksum : List(I64) -> I64
	hart_checksum = |bytes| hart_xor_loop(bytes, 0, U64.to_i64_wrap(List.len(bytes)), 0)

	hart_xor_loop : List(I64), I64, I64, I64 -> I64
	hart_xor_loop = |bytes, i, len, acc| (if (i >= len) { acc } else { hart_xor_loop(bytes, (i + 1), len, I64.bitwise_xor(acc, (List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	hart_short_address : I64, Bool -> I64
	hart_short_address = |poll_addr, master| I64.bitwise_or((if master { 128 } else { 0 }), I64.bitwise_and(poll_addr, 15))

	hart_cmd_read_unique_id : I64
	hart_cmd_read_unique_id = 0

	hart_cmd_read_pv : I64
	hart_cmd_read_pv = 1

	hart_cmd_read_current_and_pv : I64
	hart_cmd_read_current_and_pv = 2

	hart_cmd_read_dynamic_vars : I64
	hart_cmd_read_dynamic_vars = 3

	hart_cmd_set_polling_address : I64
	hart_cmd_set_polling_address = 6

	hart_short_frame : I64, I64, List(I64) -> List(I64)
	hart_short_frame = |address, command, data| ({
		core : List(I64)
		core = List.concat([hart_delim_stx_short, address, command, U64.to_i64_wrap(List.len(data))], data)
		List.concat(List.concat(hart_preamble(5), core), [hart_checksum(core)])
	})

	hart_long_frame : List(I64), I64, List(I64) -> List(I64)
	hart_long_frame = |uid, command, data| ({
		core : List(I64)
		core = List.concat(List.concat(List.concat([hart_delim_stx_long], uid), [command, U64.to_i64_wrap(List.len(data))]), data)
		List.concat(List.concat(hart_preamble(5), core), [hart_checksum(core)])
	})
}
