# Lz4 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Wrap64

Lz4 :: [].{
	Lz4LenResult := { length : I64, next : I64 }.{
		is_eq : Lz4.Lz4LenResult, Lz4.Lz4LenResult -> Bool
		is_eq = |a, b| a.length == b.length and a.next == b.next
	}

	lz4_min_match : I64
	lz4_min_match = 4

	lz4_hash_bits : I64
	lz4_hash_bits = 12

	lz4_hash_size : I64
	lz4_hash_size = 4096

	lz4_max_distance : I64
	lz4_max_distance = 65535

	lz4_ml_bits : I64
	lz4_ml_bits = 4

	lz4_ml_mask : I64
	lz4_ml_mask = 15

	lz4_run_mask : I64
	lz4_run_mask = 15

	lz4_compress : List(I64) -> List(I64)
	lz4_compress = |input| ({
		len : I64
		len = U64.to_i64_wrap(List.len(input))
		(if (len == 0) { [] } else { ({
			table : List(I64)
			table = lz4_init_table(lz4_hash_size, 0, [])
			lz4_compress_loop(input, len, table, 0, 0, [])
		}) })
	})

	lz4_compress_loop : List(I64), I64, List(I64), I64, I64, List(I64) -> List(I64)
	lz4_compress_loop = |input, len, table, pos, anchor, acc| (if ((pos + lz4_min_match) > len) { lz4_emit_last_literals(input, anchor, len, acc) } else { ({
		h : I64
		h = lz4_hash4(input, pos)
		ref : I64
		ref = (List.get(table, I64.to_u64_wrap(h)) ?? crash("list-at out of range"))
		table2 : List(I64)
		table2 = (List.set(table, I64.to_u64_wrap(h), pos) ?? crash("list-set-at past the end"))
		(if (ref < 0) { lz4_compress_loop(input, len, table2, (pos + 1), anchor, acc) } else { (if ((pos - ref) > lz4_max_distance) { lz4_compress_loop(input, len, table2, (pos + 1), anchor, acc) } else { (if (lz4_match4(input, pos, ref, len) == False) { lz4_compress_loop(input, len, table2, (pos + 1), anchor, acc) } else { ({
			match_len : I64
			match_len = lz4_extend_match(input, pos, ref, len)
			lit_len : I64
			lit_len = (pos - anchor)
			offset : I64
			offset = (pos - ref)
			acc2 : List(I64)
			acc2 = lz4_emit_sequence(acc, lit_len, input, anchor, offset, match_len)
			lz4_compress_loop(input, len, table2, (pos + match_len), (pos + match_len), acc2)
		}) }) }) })
	}) })

	lz4_hash4 : List(I64), I64 -> I64
	lz4_hash4 = |input, pos| ({
		b0 : I64
		b0 = (List.get(input, I64.to_u64_wrap(pos)) ?? crash("list-at out of range"))
		b1 : I64
		b1 = (List.get(input, I64.to_u64_wrap((pos + 1))) ?? crash("list-at out of range"))
		b2 : I64
		b2 = (List.get(input, I64.to_u64_wrap((pos + 2))) ?? crash("list-at out of range"))
		b3 : I64
		b3 = (List.get(input, I64.to_u64_wrap((pos + 3))) ?? crash("list-at out of range"))
		word : I64
		word = I64.bitwise_or(I64.bitwise_or(b0, I64.shl_wrap(b1, I64.to_u8_wrap(8))), I64.bitwise_or(I64.shl_wrap(b2, I64.to_u8_wrap(16)), I64.shl_wrap(b3, I64.to_u8_wrap(24))))
		v : I64
		v = Wrap64.w64_mul(word, 2654435761)
		positive : I64
		positive = (if (v < 0) { (0 - v) } else { v })
		I64.bitwise_and(I64.shr_zf_wrap(positive, I64.to_u8_wrap((32 - lz4_hash_bits))), (lz4_hash_size - 1))
	})

	lz4_match4 : List(I64), I64, I64, I64 -> Bool
	lz4_match4 = |input, a, b, len| (if ((a + 3) >= len) { False } else { (if ((b + 3) >= len) { False } else { (if ((List.get(input, I64.to_u64_wrap(a)) ?? crash("list-at out of range")) == (List.get(input, I64.to_u64_wrap(b)) ?? crash("list-at out of range"))) { (if ((List.get(input, I64.to_u64_wrap((a + 1))) ?? crash("list-at out of range")) == (List.get(input, I64.to_u64_wrap((b + 1))) ?? crash("list-at out of range"))) { (if ((List.get(input, I64.to_u64_wrap((a + 2))) ?? crash("list-at out of range")) == (List.get(input, I64.to_u64_wrap((b + 2))) ?? crash("list-at out of range"))) { ((List.get(input, I64.to_u64_wrap((a + 3))) ?? crash("list-at out of range")) == (List.get(input, I64.to_u64_wrap((b + 3))) ?? crash("list-at out of range"))) } else { False }) } else { False }) } else { False }) }) })

	lz4_extend_match : List(I64), I64, I64, I64 -> I64
	lz4_extend_match = |input, pos, ref, len| lz4_ext_loop(input, (pos + lz4_min_match), (ref + lz4_min_match), len, lz4_min_match)

	lz4_ext_loop : List(I64), I64, I64, I64, I64 -> I64
	lz4_ext_loop = |input, a, b, len, count| (if (a >= len) { count } else { (if ((List.get(input, I64.to_u64_wrap(a)) ?? crash("list-at out of range")) != (List.get(input, I64.to_u64_wrap(b)) ?? crash("list-at out of range"))) { count } else { lz4_ext_loop(input, (a + 1), (b + 1), len, (count + 1)) }) })

	lz4_emit_sequence : List(I64), I64, List(I64), I64, I64, I64 -> List(I64)
	lz4_emit_sequence = |acc, lit_len, input, lit_start, offset, match_len| ({
		ml_code : I64
		ml_code = (match_len - lz4_min_match)
		token : I64
		token = lz4_make_token(lit_len, ml_code)
		acc2 : List(I64)
		acc2 = List.append(acc, token)
		acc3 : List(I64)
		acc3 = lz4_emit_extra_length(acc2, lit_len)
		acc4 : List(I64)
		acc4 = lz4_copy_literals(acc3, input, lit_start, lit_len, 0)
		acc5 : List(I64)
		acc5 = List.append(List.append(acc4, I64.bitwise_and(offset, 255)), I64.bitwise_and(I64.shr_zf_wrap(offset, I64.to_u8_wrap(8)), 255))
		lz4_emit_extra_length(acc5, ml_code)
	})

	lz4_make_token : I64, I64 -> I64
	lz4_make_token = |lit_len, ml_code| ({
		lit : I64
		lit = (if (lit_len >= 15) { 15 } else { lit_len })
		ml : I64
		ml = (if (ml_code >= 15) { 15 } else { ml_code })
		I64.bitwise_or(I64.shl_wrap(lit, I64.to_u8_wrap(4)), ml)
	})

	lz4_emit_extra_length : List(I64), I64 -> List(I64)
	lz4_emit_extra_length = |acc, len| (if (len < 15) { acc } else { ({
		remaining : I64
		remaining = (len - 15)
		lz4_emit_extra_loop(acc, remaining)
	}) })

	lz4_emit_extra_loop : List(I64), I64 -> List(I64)
	lz4_emit_extra_loop = |acc, remaining| (if (remaining < 255) { List.append(acc, remaining) } else { lz4_emit_extra_loop(List.append(acc, 255), (remaining - 255)) })

	lz4_emit_last_literals : List(I64), I64, I64, List(I64) -> List(I64)
	lz4_emit_last_literals = |input, anchor, len, acc| ({
		lit_len : I64
		lit_len = (len - anchor)
		(if (lit_len == 0) { acc } else { ({
			token : I64
			token = (if (lit_len >= 15) { I64.shl_wrap(15, I64.to_u8_wrap(4)) } else { I64.shl_wrap(lit_len, I64.to_u8_wrap(4)) })
			acc2 : List(I64)
			acc2 = List.append(acc, token)
			acc3 : List(I64)
			acc3 = lz4_emit_extra_length(acc2, lit_len)
			lz4_copy_literals(acc3, input, anchor, lit_len, 0)
		}) })
	})

	lz4_fits : List(I64), I64, I64 -> Bool
	lz4_fits = |input, off, n| (if (off < 0) { False } else { (if (n < 0) { False } else { (off <= (U64.to_i64_wrap(List.len(input)) - n)) }) })

	lz4_copy_literals : List(I64), List(I64), I64, I64, I64 -> List(I64)
	lz4_copy_literals = |acc, input, start, count, i| (if (i >= count) { acc } else { (if (lz4_fits(input, (start + i), 1) == False) { acc } else { lz4_copy_literals(List.append(acc, (List.get(input, I64.to_u64_wrap((start + i))) ?? crash("list-at out of range"))), input, start, count, (i + 1)) }) })

	lz4_decompress : List(I64) -> List(I64)
	lz4_decompress = |input| lz4_decompress_loop(input, 0, U64.to_i64_wrap(List.len(input)), [])

	lz4_decompress_loop : List(I64), I64, I64, List(I64) -> List(I64)
	lz4_decompress_loop = |input, pos, len, acc| (if (pos >= len) { acc } else { ({
		token : I64
		token = (List.get(input, I64.to_u64_wrap(pos)) ?? crash("list-at out of range"))
		lit_len : I64
		lit_len = I64.shr_zf_wrap(token, I64.to_u8_wrap(4))
		ml_code : I64
		ml_code = I64.bitwise_and(token, lz4_ml_mask)
		r = lz4_read_extra_length(input, (pos + 1), len, lit_len)
		acc2 : List(I64)
		acc2 = lz4_copy_literals(acc, input, r.next, r.length, 0)
		after_lit : I64
		after_lit = (r.next + r.length)
		(if (lz4_fits(input, after_lit, 2) == False) { acc2 } else { ({
			offset : I64
			offset = ((List.get(input, I64.to_u64_wrap(after_lit)) ?? crash("list-at out of range")) + I64.shl_wrap((List.get(input, I64.to_u64_wrap((after_lit + 1))) ?? crash("list-at out of range")), I64.to_u8_wrap(8)))
			mr = lz4_read_extra_length(input, (after_lit + 2), len, (ml_code + lz4_min_match))
			acc3 : List(I64)
			acc3 = lz4_copy_match(acc2, offset, mr.length, 0)
			lz4_decompress_loop(input, mr.next, len, acc3)
		}) })
	}) })

	lz4_read_extra_length : List(I64), I64, I64, I64 -> Lz4.Lz4LenResult
	lz4_read_extra_length = |input, pos, len, base| (if (base < 15) { Lz4.Lz4LenResult.{ length: base, next: pos } } else { lz4_read_extra_loop(input, pos, len, (base - 15)) })

	lz4_read_extra_loop : List(I64), I64, I64, I64 -> Lz4.Lz4LenResult
	lz4_read_extra_loop = |input, pos, len, extra| (if (pos >= len) { Lz4.Lz4LenResult.{ length: (15 + extra), next: pos } } else { ({
		b : I64
		b = (List.get(input, I64.to_u64_wrap(pos)) ?? crash("list-at out of range"))
		(if (b < 255) { Lz4.Lz4LenResult.{ length: ((15 + extra) + b), next: (pos + 1) } } else { lz4_read_extra_loop(input, (pos + 1), len, (extra + 255)) })
	}) })

	lz4_copy_match : List(I64), I64, I64, I64 -> List(I64)
	lz4_copy_match = |acc, offset, length, i| (if (i >= length) { acc } else { (if (offset <= 0) { acc } else { ({
		src : I64
		src = (U64.to_i64_wrap(List.len(acc)) - offset)
		(if (src < 0) { acc } else { lz4_copy_match(List.append(acc, (List.get(acc, I64.to_u64_wrap(src)) ?? crash("list-at out of range"))), offset, length, (i + 1)) })
	}) }) })

	lz4_init_table : I64, I64, List(I64) -> List(I64)
	lz4_init_table = |n, i, acc| (if (i >= n) { acc } else { lz4_init_table(n, (i + 1), List.append(acc, (0 - 1))) })
}
