# Canopen -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Canopen :: [].{

	co_fc_nmt : I64
	co_fc_nmt = 0

	co_fc_sync : I64
	co_fc_sync = 1

	co_fc_emergency : I64
	co_fc_emergency = 1

	co_fc_time : I64
	co_fc_time = 2

	co_fc_tpdo1 : I64
	co_fc_tpdo1 = 3

	co_fc_rpdo1 : I64
	co_fc_rpdo1 = 4

	co_fc_sdo_tx : I64
	co_fc_sdo_tx = 11

	co_fc_sdo_rx : I64
	co_fc_sdo_rx = 12

	co_fc_heartbeat : I64
	co_fc_heartbeat = 14

	co_cob_id : I64, I64 -> I64
	co_cob_id = |function, node| I64.bitwise_or(I64.shl_wrap(function, I64.to_u8_wrap(7)), node)

	co_nmt_start : I64
	co_nmt_start = 1

	co_nmt_stop : I64
	co_nmt_stop = 2

	co_nmt_pre_operational : I64
	co_nmt_pre_operational = 128

	co_nmt_reset_node : I64
	co_nmt_reset_node = 129

	co_nmt_reset_communication : I64
	co_nmt_reset_communication = 130

	co_nmt_command : I64, I64 -> List(I64)
	co_nmt_command = |command, node| [command, node]

	co_state_boot : I64
	co_state_boot = 0

	co_state_stopped : I64
	co_state_stopped = 4

	co_state_operational : I64
	co_state_operational = 5

	co_state_pre_operational : I64
	co_state_pre_operational = 127

	co_heartbeat : I64 -> List(I64)
	co_heartbeat = |state| [state]

	co_zeros : I64, List(I64) -> List(I64)
	co_zeros = |n, acc| (if (n <= 0) { acc } else { co_zeros((n - 1), List.append(acc, 0)) })

	co_sdo_download_expedited : I64, I64, List(I64) -> List(I64)
	co_sdo_download_expedited = |index, subindex, data| ({
		n = U64.to_i64_wrap(List.len(data))
		command = I64.bitwise_or(35, I64.shl_wrap((4 - n), I64.to_u8_wrap(2)))
		List.concat(List.concat([command, I64.bitwise_and(index, 255), I64.bitwise_and(I64.shr_zf_wrap(index, I64.to_u8_wrap(8)), 255), subindex], data), co_zeros((4 - n), []))
	})
}
