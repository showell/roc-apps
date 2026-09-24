# Mbus -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Mbus :: [].{

	mbus_c_snd_nke : I64
	mbus_c_snd_nke = 64

	mbus_c_snd_ud : I64
	mbus_c_snd_ud = 83

	mbus_c_req_ud2 : I64
	mbus_c_req_ud2 = 91

	mbus_c_rsp_ud : I64
	mbus_c_rsp_ud = 8

	mbus_ci_data_send : I64
	mbus_ci_data_send = 81

	mbus_ci_selection : I64
	mbus_ci_selection = 82

	mbus_start_short : I64
	mbus_start_short = 16

	mbus_start_long : I64
	mbus_start_long = 104

	mbus_stop : I64
	mbus_stop = 22

	mbus_ack : I64
	mbus_ack = 229

	mbus_sum : List(I64), I64, I64, I64 -> I64
	mbus_sum = |bytes, i, len, acc| (if (i >= len) { acc } else { mbus_sum(bytes, (i + 1), len, (acc + (List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	mbus_checksum : List(I64) -> I64
	mbus_checksum = |bytes| I64.bitwise_and(mbus_sum(bytes, 0, U64.to_i64_wrap(List.len(bytes)), 0), 255)

	mbus_ack_frame : List(I64)
	mbus_ack_frame = [mbus_ack]

	mbus_short_frame : I64, I64 -> List(I64)
	mbus_short_frame = |c, a| [mbus_start_short, c, a, I64.bitwise_and((c + a), 255), mbus_stop]

	mbus_long_frame : I64, I64, I64, List(I64) -> List(I64)
	mbus_long_frame = |c, a, ci, data| ({
		body : List(I64)
		body = List.concat([c, a, ci], data)
		len : I64
		len = U64.to_i64_wrap(List.len(body))
		List.concat(List.concat([mbus_start_long, len, len, mbus_start_long], body), [mbus_checksum(body), mbus_stop])
	})
}
