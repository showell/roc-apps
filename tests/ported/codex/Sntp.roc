# Sntp -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Sntp :: [].{

	sntp_mode_client : I64
	sntp_mode_client = 3

	sntp_mode_server : I64
	sntp_mode_server = 4

	sntp_version_4 : I64
	sntp_version_4 = 4

	sntp_flags_client : I64
	sntp_flags_client = 35

	sntp_ntp_epoch_offset : I64
	sntp_ntp_epoch_offset = 2208988800

	sntp_flags : I64, I64, I64 -> I64
	sntp_flags = |li, version, mode| I64.bitwise_or(I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(li), U64.pow(2, I64.to_u64_wrap(6)))), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap(version), U64.pow(2, I64.to_u64_wrap(3))))), mode)

	sntp_zeros : I64, List(I64) -> List(I64)
	sntp_zeros = |n, acc| (if (n <= 0) { acc } else { sntp_zeros((n - 1), List.append(acc, 0)) })

	sntp_u32_be : I64 -> List(I64)
	sntp_u32_be = |v| [I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(v), U64.pow(2, I64.to_u64_wrap(24)))), 255), I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(v), U64.pow(2, I64.to_u64_wrap(16)))), 255), I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap(v), U64.pow(2, I64.to_u64_wrap(8)))), 255), I64.bitwise_and(v, 255)]

	sntp_read_u32_be : List(I64), I64 -> I64
	sntp_read_u32_be = |packet, off| I64.bitwise_or(I64.bitwise_or(I64.bitwise_or(U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap((List.get(packet, I64.to_u64_wrap(off)) ?? crash("list-at out of range"))), U64.pow(2, I64.to_u64_wrap(24)))), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap((List.get(packet, I64.to_u64_wrap((off + 1))) ?? crash("list-at out of range"))), U64.pow(2, I64.to_u64_wrap(16))))), U64.to_i64_wrap(U64.times_wrap(I64.to_u64_wrap((List.get(packet, I64.to_u64_wrap((off + 2))) ?? crash("list-at out of range"))), U64.pow(2, I64.to_u64_wrap(8))))), (List.get(packet, I64.to_u64_wrap((off + 3))) ?? crash("list-at out of range")))

	sntp_build_request : I64 -> List(I64)
	sntp_build_request = |transmit_seconds| List.concat(List.concat(List.concat([sntp_flags_client], sntp_zeros(39, [])), sntp_u32_be(transmit_seconds)), sntp_zeros(4, []))

	sntp_mode : List(I64) -> I64
	sntp_mode = |packet| I64.bitwise_and((List.get(packet, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), 7)

	sntp_version : List(I64) -> I64
	sntp_version = |packet| I64.bitwise_and(U64.to_i64_wrap(U64.div_by(I64.to_u64_wrap((List.get(packet, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), U64.pow(2, I64.to_u64_wrap(3)))), 7)

	sntp_stratum : List(I64) -> I64
	sntp_stratum = |packet| (List.get(packet, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))

	sntp_transmit_seconds : List(I64) -> I64
	sntp_transmit_seconds = |packet| sntp_read_u32_be(packet, 40)

	sntp_ntp_to_unix : I64 -> I64
	sntp_ntp_to_unix = |ntp_seconds| (ntp_seconds - sntp_ntp_epoch_offset)

	sntp_unix_to_ntp : I64 -> I64
	sntp_unix_to_ntp = |unix_seconds| (unix_seconds + sntp_ntp_epoch_offset)
}
