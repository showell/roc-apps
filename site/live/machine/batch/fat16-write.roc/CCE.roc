# CCE -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cce
import Prelude

CCE :: [].{
	CharClass : [Whitespace, Digit, Lower, Upper, Punct, Accented, Cyrillic, Other]

	is_whitespace : I64 -> Bool
	is_whitespace = |c| (if (c >= 1) { (c <= 2) } else { False })

	is_digit : I64 -> Bool
	is_digit = |c| (if (c >= 3) { (c <= 12) } else { False })

	digit_value : I64 -> I64
	digit_value = |c| (c - 3)

	is_lower : I64 -> Bool
	is_lower = |c| (if (c >= 97) { (c <= 127) } else { (if (c >= 13) { (c <= 38) } else { False }) })

	is_upper : I64 -> Bool
	is_upper = |c| (if (c >= 39) { (c <= 64) } else { False })

	is_letter : I64 -> Bool
	is_letter = |c| (if (c >= 97) { (c <= 127) } else { (if (c >= 13) { (c <= 64) } else { False }) })

	is_punct : I64 -> Bool
	is_punct = |c| (if (c >= 65) { (c <= 96) } else { False })

	is_accented : I64 -> Bool
	is_accented = |c| (if (c >= 97) { (c <= 112) } else { False })

	is_cyrillic : I64 -> Bool
	is_cyrillic = |c| (if (c >= 113) { (c <= 127) } else { False })

	to_lower : I64 -> I64
	to_lower = |c| (if (c >= 39) { (if (c <= 64) { (c - 26) } else { c }) } else { c })

	to_upper : I64 -> I64
	to_upper = |c| (if (c >= 13) { (if (c <= 38) { (c + 26) } else { c }) } else { c })

	classify : I64 -> CCE.CharClass
	classify = |c| ({
		b = c
		(if (b == 0) { Other } else { (if (b <= 2) { Whitespace } else { (if (b <= 12) { Digit } else { (if (b <= 38) { Lower } else { (if (b <= 64) { Upper } else { (if (b <= 96) { Punct } else { (if (b <= 112) { Accented } else { (if (b <= 127) { Cyrillic } else { Other }) }) }) }) }) }) }) })
	})

	cce_to_unicode_table : List(I64)
	cce_to_unicode_table = [0, 10, 32, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 101, 116, 97, 111, 105, 110, 115, 104, 114, 100, 108, 99, 117, 109, 119, 102, 103, 121, 112, 98, 118, 107, 106, 120, 113, 122, 69, 84, 65, 79, 73, 78, 83, 72, 82, 68, 76, 67, 85, 77, 87, 70, 71, 89, 80, 66, 86, 75, 74, 88, 81, 90, 46, 44, 33, 63, 58, 59, 39, 34, 45, 40, 41, 43, 61, 42, 60, 62, 47, 64, 35, 38, 95, 92, 124, 91, 93, 123, 125, 126, 96, 94, 36, 37, 233, 232, 234, 235, 225, 224, 226, 228, 243, 244, 246, 250, 252, 241, 231, 237, 1072, 1086, 1077, 1080, 1085, 1090, 1089, 1088, 1074, 1083, 1082, 1084, 1076, 1087, 1091]

	cce_encode_length : I64 -> I64
	cce_encode_length = |cp| (if (cp < 128) { 1 } else { (if (cp < 2176) { 2 } else { (if (cp < 67712) { 3 } else { 4 }) }) })

	cce_is_continuation : I64 -> Bool
	cce_is_continuation = |b| (I64.bitwise_and(b, 192) == 128)

	cce_char_start : I64 -> Bool
	cce_char_start = |b| (I64.bitwise_and(b, 192) != 128)

	cce_decode_length : I64 -> I64
	cce_decode_length = |b| (if (I64.bitwise_and(b, 128) == 0) { 1 } else { (if (I64.bitwise_and(b, 224) == 192) { 2 } else { (if (I64.bitwise_and(b, 240) == 224) { 3 } else { (if (I64.bitwise_and(b, 248) == 240) { 4 } else { 1 }) }) }) })

	cce_encode : I64 -> List(I64)
	cce_encode = |cp| cce_encode_into([], cp)

	cce_encode_into : List(I64), I64 -> List(I64)
	cce_encode_into = |acc, cp| (if (cp < 128) { List.append(acc, cp) } else { (if (cp < 2176) { ({
		v = (cp - 128)
		List.append(List.append(acc, I64.bitwise_or(192, I64.shr_zf_wrap(v, I64.to_u8_wrap(6)))), I64.bitwise_or(128, I64.bitwise_and(v, 63)))
	}) } else { (if (cp < 67712) { ({
		v = (cp - 2176)
		List.append(List.append(List.append(acc, I64.bitwise_or(224, I64.shr_zf_wrap(v, I64.to_u8_wrap(12)))), I64.bitwise_or(128, I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(6)), 63))), I64.bitwise_or(128, I64.bitwise_and(v, 63)))
	}) } else { ({
		v = (cp - 67712)
		List.append(List.append(List.append(List.append(acc, I64.bitwise_or(240, I64.shr_zf_wrap(v, I64.to_u8_wrap(18)))), I64.bitwise_or(128, I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(12)), 63))), I64.bitwise_or(128, I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(6)), 63))), I64.bitwise_or(128, I64.bitwise_and(v, 63)))
	}) }) }) })

	cce_decode_at : Str, I64 -> I64
	cce_decode_at = |s, offset| ({
		b0 = Cce.at_or_crash(s, offset)
		(if (I64.bitwise_and(b0, 128) == 0) { b0 } else { (if (I64.bitwise_and(b0, 224) == 192) { ({
			b1 = Cce.at_or_crash(s, (offset + 1))
			((128 + I64.shl_wrap(I64.bitwise_and(b0, 31), I64.to_u8_wrap(6))) + I64.bitwise_and(b1, 63))
		}) } else { (if (I64.bitwise_and(b0, 240) == 224) { ({
			b1 = Cce.at_or_crash(s, (offset + 1))
			b2 = Cce.at_or_crash(s, (offset + 2))
			(((2176 + I64.shl_wrap(I64.bitwise_and(b0, 15), I64.to_u8_wrap(12))) + I64.shl_wrap(I64.bitwise_and(b1, 63), I64.to_u8_wrap(6))) + I64.bitwise_and(b2, 63))
		}) } else { ({
			b1 = Cce.at_or_crash(s, (offset + 1))
			b2 = Cce.at_or_crash(s, (offset + 2))
			b3 = Cce.at_or_crash(s, (offset + 3))
			((((67712 + I64.shl_wrap(I64.bitwise_and(b0, 7), I64.to_u8_wrap(18))) + I64.shl_wrap(I64.bitwise_and(b1, 63), I64.to_u8_wrap(12))) + I64.shl_wrap(I64.bitwise_and(b2, 63), I64.to_u8_wrap(6))) + I64.bitwise_and(b3, 63))
		}) }) }) })
	})

	cce_tier1_block_count : I64
	cce_tier1_block_count = 11

	cce_tier1_block_bases : List(I64)
	cce_tier1_block_bases = [128, 256, 1024, 128, 880, 128, 1536, 128, 1424, 128, 2304, 128, 3584, 128, 4352, 128, 19968, 512, 12352, 256, 8704, 128]

	cce_tier1_block_unicode_base : I64 -> I64
	cce_tier1_block_unicode_base = |block| (List.get(cce_tier1_block_bases, I64.to_u64_wrap((block * 2))) ?? crash("list-at out of range"))

	cce_tier1_block_size : I64 -> I64
	cce_tier1_block_size = |block| (List.get(cce_tier1_block_bases, I64.to_u64_wrap(((block * 2) + 1))) ?? crash("list-at out of range"))

	cce_tier1_block : I64 -> I64
	cce_tier1_block = |cp| ({
		v = (cp - 128)
		(if (v < 256) { 0 } else { (if (v < 384) { 1 } else { (if (v < 512) { 2 } else { (if (v < 640) { 3 } else { (if (v < 768) { 4 } else { (if (v < 896) { 5 } else { (if (v < 1024) { 6 } else { (if (v < 1152) { 7 } else { (if (v < 1664) { 8 } else { (if (v < 1920) { 9 } else { (if (v < 2048) { 10 } else { (-1) }) }) }) }) }) }) }) }) }) }) })
	})

	cce_tier1_offset_in_block : I64 -> I64
	cce_tier1_offset_in_block = |cp| ({
		v = (cp - 128)
		(if (v < 256) { v } else { (if (v < 1152) { Prelude.int_mod((v - 256), 128) } else { (if (v < 1664) { (v - 1152) } else { (if (v < 1920) { (v - 1664) } else { (v - 1920) }) }) }) })
	})

	cce_is_letter_ext : I64 -> Bool
	cce_is_letter_ext = |cp| (if (cp < 128) { is_letter(cp) } else { ({
		block = cce_tier1_block(cp)
		(if (block >= 0) { (block <= 5) } else { False })
	}) })

	cce_is_letter_any : I64 -> Bool
	cce_is_letter_any = |cp| (if (cp < 128) { is_letter(cp) } else { (if (cp < 2176) { cce_is_letter_ext(cp) } else { ((cce_is_cjk(cp) or cce_is_hangul(cp)) or cce_is_kana(cp)) }) })

	cce_script : I64 -> I64
	cce_script = |cp| (if (cp < 128) { 0 } else { cce_tier1_block(cp) })

	text_char_count : Str -> I64
	text_char_count = |s| text_char_count_loop(s, 0, Cce.length(s), 0)

	text_char_count_loop : Str, I64, I64, I64 -> I64
	text_char_count_loop = |s, i, len, count| (if (i >= len) { count } else { (if cce_is_continuation(Cce.at_or_crash(s, i)) { text_char_count_loop(s, (i + 1), len, count) } else { text_char_count_loop(s, (i + 1), len, (count + 1)) }) })

	cce_tier2_base : I64
	cce_tier2_base = 2176

	cce_tier2_block_count : I64
	cce_tier2_block_count = 10

	cce_tier2_block_table : List(I64)
	cce_tier2_block_table = [12288, 64, 12352, 96, 12448, 96, 19968, 20992, 13312, 6592, 44032, 11172, 3584, 256, 8192, 512, 127744, 1024, 9728, 256]

	cce_tier2_block_unicode_base : I64 -> I64
	cce_tier2_block_unicode_base = |block| (List.get(cce_tier2_block_table, I64.to_u64_wrap((block * 2))) ?? crash("list-at out of range"))

	cce_tier2_block_size : I64 -> I64
	cce_tier2_block_size = |block| (List.get(cce_tier2_block_table, I64.to_u64_wrap(((block * 2) + 1))) ?? crash("list-at out of range"))

	cce_tier2_cce_base : I64 -> I64
	cce_tier2_cce_base = |block| cce_tier2_cce_base_loop(block, 0, cce_tier2_base)

	cce_tier2_cce_base_loop : I64, I64, I64 -> I64
	cce_tier2_cce_base_loop = |target, i, acc| (if (i >= target) { acc } else { cce_tier2_cce_base_loop(target, (i + 1), (acc + cce_tier2_block_size(i))) })

	cce_is_cjk : I64 -> Bool
	cce_is_cjk = |cp| ({
		u = to_unicode(cp)
		(if (u >= 19968) { (u <= 40959) } else { (if (u >= 13312) { (u <= 19903) } else { False }) })
	})

	cce_is_hangul : I64 -> Bool
	cce_is_hangul = |cp| ({
		u = to_unicode(cp)
		(if (u >= 44032) { (u <= 55203) } else { False })
	})

	cce_is_kana : I64 -> Bool
	cce_is_kana = |cp| ({
		u = to_unicode(cp)
		(if (u >= 12352) { (u <= 12543) } else { False })
	})

	cce_is_emoji : I64 -> Bool
	cce_is_emoji = |cp| ({
		u = to_unicode(cp)
		(if (u >= 127744) { (u <= 128767) } else { False })
	})

	to_unicode : I64 -> I64
	to_unicode = |cp| to_unicode_with(cce_to_unicode_table, cp)

	to_unicode_with : List(I64), I64 -> I64
	to_unicode_with = |tbl, cp| (if (cp < 0) { 65533 } else { (if (cp < 128) { (List.get(tbl, I64.to_u64_wrap(cp)) ?? crash("list-at out of range")) } else { (if (cp < 2176) { ({
		block = cce_tier1_block(cp)
		(if (block < 0) { 65533 } else { (cce_tier1_block_unicode_base(block) + cce_tier1_offset_in_block(cp)) })
	}) } else { (if (cp < 67712) { to_unicode_tier2(cp, 0) } else { 65533 }) }) }) })

	to_unicode_tier2 : I64, I64 -> I64
	to_unicode_tier2 = |cp, block| (if (block >= cce_tier2_block_count) { 65533 } else { ({
		block_base = cce_tier2_cce_base(block)
		block_size = cce_tier2_block_size(block)
		(if (cp >= block_base) { (if (cp < (block_base + block_size)) { (cce_tier2_block_unicode_base(block) + (cp - block_base)) } else { to_unicode_tier2(cp, (block + 1)) }) } else { to_unicode_tier2(cp, (block + 1)) })
	}) })

	from_unicode : I64 -> I64
	from_unicode = |u| from_unicode_with(cce_to_unicode_table, u)

	from_unicode_with : List(I64), I64 -> I64
	from_unicode_with = |tbl, u| ({
		t0 = from_unicode_tier0(tbl, u, 0, 128)
		(if (t0 >= 0) { t0 } else { ({
			t1 = from_unicode_tier1(u, 0)
			(if (t1 >= 0) { t1 } else { from_unicode_tier2(u, 0) })
		}) })
	})

	from_unicode_tier0 : List(I64), I64, I64, I64 -> I64
	from_unicode_tier0 = |tbl, u, i, len| (if (i >= len) { (-1) } else { (if ((List.get(tbl, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == u) { i } else { from_unicode_tier0(tbl, u, (i + 1), len) }) })

	from_unicode_tier1 : I64, I64 -> I64
	from_unicode_tier1 = |u, block| (if (block >= cce_tier1_block_count) { (-1) } else { ({
		base = cce_tier1_block_unicode_base(block)
		size = cce_tier1_block_size(block)
		(if (u >= base) { (if (u < (base + size)) { ({
			block_start = (if (block == 0) { 128 } else { (if (block < 8) { (256 + (block * 128)) } else { (if (block == 8) { 1280 } else { (if (block == 9) { 1792 } else { (if (block == 10) { 2048 } else { (-1) }) }) }) }) })
			(if (block_start < 0) { (-1) } else { (block_start + (u - base)) })
		}) } else { from_unicode_tier1(u, (block + 1)) }) } else { from_unicode_tier1(u, (block + 1)) })
	}) })

	from_unicode_tier2 : I64, I64 -> I64
	from_unicode_tier2 = |u, block| (if (block >= cce_tier2_block_count) { (-1) } else { ({
		base = cce_tier2_block_unicode_base(block)
		size = cce_tier2_block_size(block)
		(if (u >= base) { (if (u < (base + size)) { (cce_tier2_cce_base(block) + (u - base)) } else { from_unicode_tier2(u, (block + 1)) }) } else { from_unicode_tier2(u, (block + 1)) })
	}) })

	utf8_decode_length : I64 -> I64
	utf8_decode_length = |b| (if (b < 128) { 1 } else { (if (b < 192) { 0 } else { (if (b < 224) { 2 } else { (if (b < 240) { 3 } else { (if (b < 248) { 4 } else { 0 }) }) }) }) })

	utf8_cont : List(I64), I64 -> I64
	utf8_cont = |bytes, i| (if (i >= U64.to_i64_wrap(List.len(bytes))) { (-1) } else { ({
		b = (List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (b < 128) { (-1) } else { (if (b >= 192) { (-1) } else { I64.bitwise_and(b, 63) }) })
	}) })

	utf8_assemble_loop : List(I64), I64, I64, I64 -> I64
	utf8_assemble_loop = |bytes, i, stop, acc| (if (i >= stop) { acc } else { ({
		c = utf8_cont(bytes, i)
		(if (c < 0) { (-1) } else { utf8_assemble_loop(bytes, (i + 1), stop, I64.bitwise_or(I64.shl_wrap(acc, I64.to_u8_wrap(6)), c)) })
	}) })

	utf8_assemble : List(I64), I64, I64, I64 -> I64
	utf8_assemble = |bytes, i, mask, n| (if ((i + n) > U64.to_i64_wrap(List.len(bytes))) { (-1) } else { utf8_assemble_loop(bytes, (i + 1), (i + n), I64.bitwise_and((List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), mask)) })

	utf8_code_point_at : List(I64), I64 -> I64
	utf8_code_point_at = |bytes, i| (if (i >= U64.to_i64_wrap(List.len(bytes))) { (-1) } else { ({
		n = utf8_decode_length((List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if (n == 1) { (List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { (if (n == 2) { utf8_assemble(bytes, i, 31, 2) } else { (if (n == 3) { utf8_assemble(bytes, i, 15, 3) } else { (if (n == 4) { utf8_assemble(bytes, i, 7, 4) } else { (-1) }) }) }) })
	}) })

	cce_join_bytes : List(I64), I64, I64 -> Str
	cce_join_bytes = |bytes, lo, hi| (if (hi <= lo) { "" } else { (if ((hi - lo) == 1) { Cce.text((List.get(bytes, I64.to_u64_wrap(lo)) ?? crash("list-at out of range"))) } else { ({
		mid = (lo + I64.div_trunc_by((hi - lo), 2))
		Str.concat(cce_join_bytes(bytes, lo, mid), cce_join_bytes(bytes, mid, hi))
	}) }) })

	cce_push_encoded : List(I64), List(I64), I64, I64 -> List(I64)
	cce_push_encoded = |acc, bs, i, n| (if (i >= n) { acc } else { cce_push_encoded(List.append(acc, (List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), bs, (i + 1), n) })

	utf8_to_text_loop : List(I64), I64, I64, List(I64) -> List(I64)
	utf8_to_text_loop = |bytes, i, len, acc| (if (i >= len) { acc } else { ({
		n = utf8_decode_length((List.get(bytes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if (n == 0) { utf8_to_text_loop(bytes, (i + 1), len, acc) } else { ({
			u = utf8_code_point_at(bytes, i)
			(if (u < 0) { utf8_to_text_loop(bytes, (i + 1), len, acc) } else { ({
				c = from_unicode(u)
				(if (c < 0) { utf8_to_text_loop(bytes, (i + n), len, acc) } else { ({
					e = cce_encode(c)
					utf8_to_text_loop(bytes, (i + n), len, cce_push_encoded(acc, e, 0, U64.to_i64_wrap(List.len(e))))
				}) })
			}) })
		}) })
	}) })

	utf8_bytes_to_text : List(I64) -> Str
	utf8_bytes_to_text = |bytes| ({
		out = utf8_to_text_loop(bytes, 0, U64.to_i64_wrap(List.len(bytes)), [])
		cce_join_bytes(out, 0, U64.to_i64_wrap(List.len(out)))
	})

	utf8_encode_cp : I64 -> List(I64)
	utf8_encode_cp = |u| (if (u < 0) { [] } else { (if (u < 128) { [u] } else { (if (u < 2048) { [I64.bitwise_or(192, I64.shr_zf_wrap(u, I64.to_u8_wrap(6))), I64.bitwise_or(128, I64.bitwise_and(u, 63))] } else { (if (u < 65536) { [I64.bitwise_or(224, I64.shr_zf_wrap(u, I64.to_u8_wrap(12))), I64.bitwise_or(128, I64.bitwise_and(I64.shr_zf_wrap(u, I64.to_u8_wrap(6)), 63)), I64.bitwise_or(128, I64.bitwise_and(u, 63))] } else { [I64.bitwise_or(240, I64.shr_zf_wrap(u, I64.to_u8_wrap(18))), I64.bitwise_or(128, I64.bitwise_and(I64.shr_zf_wrap(u, I64.to_u8_wrap(12)), 63)), I64.bitwise_or(128, I64.bitwise_and(I64.shr_zf_wrap(u, I64.to_u8_wrap(6)), 63)), I64.bitwise_or(128, I64.bitwise_and(u, 63))] }) }) }) })

	utf8_from_text_loop : Str, I64, I64, List(I64) -> List(I64)
	utf8_from_text_loop = |t, i, len, acc| (if (i >= len) { acc } else { ({
		n = cce_decode_length(Cce.at_or_crash(t, i))
		u = to_unicode(cce_decode_at(t, i))
		utf8_from_text_loop(t, (i + n), len, List.concat(acc, utf8_encode_cp(u)))
	}) })

	text_to_utf8_bytes : Str -> List(I64)
	text_to_utf8_bytes = |t| utf8_from_text_loop(t, 0, Cce.length(t), [])

	unicode_from_text_loop : List(I64), Str, I64, I64, List(I64) -> List(I64)
	unicode_from_text_loop = |tbl, t, i, len, acc| (if (i >= len) { acc } else { ({
		n = cce_decode_length(Cce.at(t, i))
		unicode_from_text_loop(tbl, t, (i + n), len, List.append(acc, to_unicode_with(tbl, cce_decode_at(t, i))))
	}) })

	text_to_unicode_bytes : Str -> List(I64)
	text_to_unicode_bytes = |t| unicode_from_text_loop(cce_to_unicode_table, t, 0, Cce.length(t), [])

	unicode_to_text_loop : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	unicode_to_text_loop = |tbl, us, i, len, acc| (if (i >= len) { acc } else { ({
		c = from_unicode_with(tbl, (List.get(us, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))
		(if (c < 0) { unicode_to_text_loop(tbl, us, (i + 1), len, acc) } else { unicode_to_text_loop(tbl, us, (i + 1), len, cce_encode_into(acc, c)) })
	}) })

	unicode_bytes_to_text : List(I64) -> Str
	unicode_bytes_to_text = |us| Cce.str_of(List.map(unicode_to_text_loop(cce_to_unicode_table, us, 0, U64.to_i64_wrap(List.len(us)), []), |b| I64.bitwise_and(b, 255)))

	eq_CharClass : CCE.CharClass, CCE.CharClass -> Bool
	eq_CharClass = |ex, ey| (match ex {
		Whitespace => (match ey {
			Whitespace => True
			_ => False
		})
		Digit => (match ey {
			Digit => True
			_ => False
		})
		Lower => (match ey {
			Lower => True
			_ => False
		})
		Upper => (match ey {
			Upper => True
			_ => False
		})
		Punct => (match ey {
			Punct => True
			_ => False
		})
		Accented => (match ey {
			Accented => True
			_ => False
		})
		Cyrillic => (match ey {
			Cyrillic => True
			_ => False
		})
		Other => (match ey {
			Other => True
			_ => False
		})
	})
}
