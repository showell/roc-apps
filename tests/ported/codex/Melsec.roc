# Melsec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Melsec :: [].{

	melsec_u16_le : I64 -> List(I64)
	melsec_u16_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255)]

	melsec_u24_le : I64 -> List(I64)
	melsec_u24_le = |v| [I64.bitwise_and(v, 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255)]

	melsec_cmd_batch_read : I64
	melsec_cmd_batch_read = 1025

	melsec_cmd_batch_write : I64
	melsec_cmd_batch_write = 5121

	melsec_sub_word : I64
	melsec_sub_word = 0

	melsec_sub_bit : I64
	melsec_sub_bit = 1

	melsec_dev_d : I64
	melsec_dev_d = 168

	melsec_dev_m : I64
	melsec_dev_m = 144

	melsec_dev_x : I64
	melsec_dev_x = 156

	melsec_dev_y : I64
	melsec_dev_y = 157

	melsec_dev_w : I64
	melsec_dev_w = 180

	melsec_dev_r : I64
	melsec_dev_r = 175

	melsec_request : I64, I64, List(I64) -> List(I64)
	melsec_request = |command, subcommand, payload| ({
		body : List(I64)
		body = List.concat(List.concat(List.concat(melsec_u16_le(16), melsec_u16_le(command)), melsec_u16_le(subcommand)), payload)
		List.concat(List.concat(List.concat(List.concat([80, 0, 0, 255], melsec_u16_le(1023)), [0]), melsec_u16_le(U64.to_i64_wrap(List.len(body)))), body)
	})

	melsec_device : I64, I64, I64 -> List(I64)
	melsec_device = |dev_code, head, count| List.concat(List.concat(melsec_u24_le(head), [dev_code]), melsec_u16_le(count))

	melsec_words_le : List(I64) -> List(I64)
	melsec_words_le = |words| melsec_words_loop(words, 0, U64.to_i64_wrap(List.len(words)), [])

	melsec_words_loop : List(I64), I64, I64, List(I64) -> List(I64)
	melsec_words_loop = |words, i, len, acc| (if (i >= len) { acc } else { melsec_words_loop(words, (i + 1), len, List.concat(acc, melsec_u16_le((List.get(words, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	melsec_batch_read_words : I64, I64, I64 -> List(I64)
	melsec_batch_read_words = |dev_code, head, count| melsec_request(melsec_cmd_batch_read, melsec_sub_word, melsec_device(dev_code, head, count))

	melsec_batch_write_words : I64, I64, List(I64) -> List(I64)
	melsec_batch_write_words = |dev_code, head, words| melsec_request(melsec_cmd_batch_write, melsec_sub_word, List.concat(melsec_device(dev_code, head, U64.to_i64_wrap(List.len(words))), melsec_words_le(words)))
}
