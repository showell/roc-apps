# Fins -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Fins :: [].{

	fins_u16_be : I64 -> List(I64)
	fins_u16_be = |v| [I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)]

	fins_header : I64, I64, I64 -> List(I64)
	fins_header = |dest_node, src_node, sid| [128, 0, 2, 0, dest_node, 0, 0, src_node, 0, sid]

	fins_cmd_mem_read : I64
	fins_cmd_mem_read = 257

	fins_cmd_mem_write : I64
	fins_cmd_mem_write = 258

	fins_area_cio : I64
	fins_area_cio = 176

	fins_area_work : I64
	fins_area_work = 177

	fins_area_hold : I64
	fins_area_hold = 178

	fins_area_dm : I64
	fins_area_dm = 130

	fins_mem_read : I64, I64, I64, I64, I64, I64 -> List(I64)
	fins_mem_read = |dest_node, src_node, sid, area, address, count| List.concat(List.concat(List.concat(List.concat(List.concat(fins_header(dest_node, src_node, sid), fins_u16_be(fins_cmd_mem_read)), [area]), fins_u16_be(address)), [0]), fins_u16_be(count))

	fins_words_be : List(I64) -> List(I64)
	fins_words_be = |words| fins_words_loop(words, 0, U64.to_i64_wrap(List.len(words)), [])

	fins_words_loop : List(I64), I64, I64, List(I64) -> List(I64)
	fins_words_loop = |words, i, len, acc| (if (i >= len) { acc } else { fins_words_loop(words, (i + 1), len, List.concat(acc, fins_u16_be((List.get(words, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	fins_mem_write : I64, I64, I64, I64, I64, List(I64) -> List(I64)
	fins_mem_write = |dest_node, src_node, sid, area, address, words| List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(fins_header(dest_node, src_node, sid), fins_u16_be(fins_cmd_mem_write)), [area]), fins_u16_be(address)), [0]), fins_u16_be(U64.to_i64_wrap(List.len(words)))), fins_words_be(words))
}
