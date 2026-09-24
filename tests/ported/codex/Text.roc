# Text -- a Codex Text as its CCE units, written by rocemit
# (rust-codex-compiler) from the compiler's own tables. Do not edit.
#
# A Codex Text is a sequence of units 0..255, as every upstream backend holds
# one: codes 1..127 are one unit per character, and a code outside them is
# framed as 2, 3 or 4 units. Text is its own type over those units, and a
# string literal where a Text is wanted is one (`from_quote`). Each function is the zig plug's text part of the
# same name (`cx_*`), behaving as rust-codex-compiler's interpreter does where
# the two differ. A Str appears only at the edges: `printed` for the console,
# `of_str` for text from the platform.

Text :: List(U8).{
	# The code point each code 0..127 names (`cce_table`); 0 for none.
	points : List(U64)
	points = [
		0, 10, 32, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 101, 116, 97,
		111, 105, 110, 115, 104, 114, 100, 108, 99, 117, 109, 119, 102, 103, 121, 112,
		98, 118, 107, 106, 120, 113, 122, 69, 84, 65, 79, 73, 78, 83, 72, 82,
		68, 76, 67, 85, 77, 87, 70, 71, 89, 80, 66, 86, 75, 74, 88, 81,
		90, 46, 44, 33, 63, 58, 59, 39, 34, 45, 40, 41, 43, 61, 42, 60,
		62, 47, 64, 35, 38, 95, 92, 124, 91, 93, 123, 125, 126, 96, 94, 36,
		37, 233, 232, 234, 235, 225, 224, 226, 228, 243, 244, 246, 250, 252, 241, 231,
		237, 1072, 1086, 1077, 1080, 1085, 1090, 1089, 1088, 1074, 1083, 1082, 1084, 1076, 1087, 1091
	]

	# The code of each code point below 128 (`cx_cp_to_cce`); 68, `?`, where
	# the alphabet names none.
	codes : List(U64)
	codes = [
		0, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1, 68, 68, 68, 68, 68,
		68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68,
		2, 67, 72, 83, 95, 96, 84, 71, 74, 75, 78, 76, 66, 73, 65, 81,
		3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 69, 70, 79, 77, 80, 68,
		82, 41, 58, 50, 48, 39, 54, 55, 46, 43, 61, 60, 49, 52, 44, 42,
		57, 63, 47, 45, 40, 51, 59, 53, 62, 56, 64, 88, 86, 89, 94, 85,
		93, 15, 32, 24, 22, 13, 28, 29, 20, 17, 35, 34, 23, 26, 18, 16,
		31, 37, 21, 19, 14, 25, 33, 27, 36, 30, 38, 90, 87, 91, 92, 68
	]

	# Tier 1 (`cce_t1_code`, `cce_t1_size`, `cce_t1_uni`) and tier 2
	# (`cce_t2_uni`, `cce_t2_size`, cumulative from code 2176).
	t1_code : List(U64)
	t1_code = [128, 384, 512, 640, 768, 896, 1024, 1152, 1280, 1792, 2048]

	t1_size : List(U64)
	t1_size = [256, 128, 128, 128, 128, 128, 128, 128, 512, 256, 128]

	t1_uni : List(U64)
	t1_uni = [128, 1024, 880, 1536, 1424, 2304, 3584, 4352, 19968, 12352, 8704]

	t2_uni : List(U64)
	t2_uni = [12288, 12352, 12448, 19968, 13312, 44032, 3584, 8192, 127744, 9728]

	t2_size : List(U64)
	t2_size = [64, 96, 96, 20992, 6592, 11172, 256, 512, 1024, 256]

	# x86's print tables: the code point starting each 128-code slice of tier 1
	# (`tier1-slice-bases`), and per tier-2 slice the code it ends before and
	# the delta to its code point, added unsigned in a 64-bit register
	# (`tier2-rodata`).
	x86_t1_bases : List(U64)
	x86_t1_bases = [192, 320, 1024, 880, 1536, 1424, 2304, 3584, 4352, 19968, 20096, 20224, 20352, 12352, 12480, 8704]

	x86_t2_end : List(U64)
	x86_t2_end = [2240, 2336, 2432, 23424, 30016, 41188, 41444, 41956, 42980, 43236]

	x86_t2_delta : List(U64)
	x86_t2_delta = [10112, 10112, 10112, 17536, 4294957184, 14016, 4294929692, 4294934044, 85788, 4294934044]

	# **A LITERAL IS A Text** (`from_quote`): a Roc string literal where a Text
	# is wanted is its characters' codes, framed, as `of_str` reads a platform's
	# text, which is what the compiler does with a Codex literal
	# (`charcode::units_of`).
	from_quote : Str -> Try(Text, [BadQuotedBytes(Str)])
	from_quote = |str| Ok(Text.of_str(str))

	# The units themselves, in and out.
	from_units : List(U8) -> Text
	from_units = |us| Text.(us)

	units : Text -> List(U8)
	units = |Text.(us)| us

	# `==` and hashing compare the units.
	is_eq : Text, Text -> Bool
	is_eq = |Text.(a), Text.(b)| a == b

	to_hash : Text, Hasher -> Hasher
	to_hash = |Text.(s), hasher| Hasher.write_bytes(hasher, s)

	# `&` on two texts.
	concat : Text, Text -> Text
	concat = |Text.(a), Text.(b)| Text.(List.concat(a, b))

	# `text-length` (`cx_text_len`): the count of units.
	len : Text -> I64
	len = |Text.(s)| U64.to_i64_wrap(List.len(s))

	# `char-at` (`cx_char_at`): one unit, and no running past the end.
	char_at : Text, I64 -> I64
	char_at = |Text.(s), i|
		if i < 0 { crash("char-at past the end") }
		else { U64.to_i64_wrap(U8.to_u64(List.get(s, I64.to_u64_wrap(i)) ?? crash("char-at past the end"))) }

	# `char-code-at`: one unit, 0 past the end.
	char_code_at : Text, I64 -> I64
	char_code_at = |Text.(s), i| if i < 0 { 0 } else { U64.to_i64_wrap(U8.to_u64(List.get(s, I64.to_u64_wrap(i)) ?? 0)) }

	# `substring` (`cx_substring`), clamped to the text as the interpreter
	# clamps it.
	substring : Text, I64, I64 -> Text
	substring = |Text.(s), start, n| Text.(List.sublist(s, { start: I64.to_u64_wrap(I64.max(start, 0)), len: I64.to_u64_wrap(I64.max(n, 0)) }))

	# `text-compare` (`cx_text_compare`): unsigned unit order, -1, 0 or 1.
	compare : Text, Text -> I64
	compare = |Text.(a), Text.(b)| Text.compare_from(a, b, 0)

	compare_from : List(U8), List(U8), U64 -> I64
	compare_from = |a, b, i| {
		x = List.get(a, i)
		y = List.get(b, i)
		match (x, y) {
			(Err(_), Err(_)) => 0
			(Err(_), Ok(_)) => -1
			(Ok(_), Err(_)) => 1
			(Ok(p), Ok(q)) => if p < q { -1 } else if p > q { 1 } else { Text.compare_from(a, b, i + 1) }
		}
	}

	# `char-to-text` (`cx_char_to_text`): one unit, the code's low byte.
	char_to_text : I64 -> Text
	char_to_text = |c| Text.([I64.to_u8_wrap(c)])

	# `char-encode` (`cx_char_encode`): the code framed as 1 to 4 units.
	char_encode : I64 -> Text
	char_encode = |c| Text.(Text.frame(U64.bitwise_and(I64.to_u64_wrap(c), 4294967295)))

	frame : U64 -> List(U8)
	frame = |u|
		if u < 128 {
			[U64.to_u8_wrap(u)]
		} else if u < 2176 {
			v = u - 128
			[Text.low(192 + U64.div_by(v, 64)), Text.low(128 + U64.bitwise_and(v, 63))]
		} else if u < 67712 {
			v = u - 2176
			[Text.low(224 + U64.div_by(v, 4096)), Text.low(128 + U64.bitwise_and(U64.div_by(v, 64), 63)), Text.low(128 + U64.bitwise_and(v, 63))]
		} else {
			v = u - 67712
			[
				Text.low(240 + U64.div_by(v, 262144)),
				Text.low(128 + U64.bitwise_and(U64.div_by(v, 4096), 63)),
				Text.low(128 + U64.bitwise_and(U64.div_by(v, 64), 63)),
				Text.low(128 + U64.bitwise_and(v, 63)),
			]
		}

	low : U64 -> U8
	low = |v| U64.to_u8_wrap(v)

	# `text-contains`, `text-starts-with`, `text-ends-with`
	# (`cx_text_contains` ...): unit by unit, blind to frames.
	contains : Text, Text -> Bool
	contains = |Text.(h), Text.(n)| Text.find(h, n, 0) >= 0

	starts_with : Text, Text -> Bool
	starts_with = |Text.(s), Text.(p)| List.starts_with(s, p)

	ends_with : Text, Text -> Bool
	ends_with = |Text.(s), Text.(p)| List.ends_with(s, p)

	# The first index from `i` where `n` occurs in `h`, or -1.
	find : List(U8), List(U8), U64 -> I64
	find = |h, n, i|
		if i + List.len(n) > List.len(h) { -1 }
		else if List.sublist(h, { start: i, len: List.len(n) }) == n { U64.to_i64_wrap(i) }
		else { Text.find(h, n, i + 1) }

	# `text-replace` (`cx_text_replace`): every occurrence left to right, and
	# an empty pattern answers the text as it was.
	replace : Text, Text, Text -> Text
	replace = |Text.(s), Text.(a), Text.(b)| if List.len(a) == 0 { Text.(s) } else { Text.(Text.replace_from(s, a, b, 0, [])) }

	replace_from : List(U8), List(U8), List(U8), U64, List(U8) -> List(U8)
	replace_from = |s, a, b, i, acc| {
		p = Text.find(s, a, i)
		if p < 0 {
			List.concat(acc, List.drop_first(s, i))
		} else {
			at = I64.to_u64_wrap(p)
			Text.replace_from(s, a, b, at + List.len(a), List.concat(List.concat(acc, List.sublist(s, { start: i, len: at - i })), b))
		}
	}

	# `text-split` (`cx_text_split`): the pieces between separators; an empty
	# separator answers the text whole.
	split : Text, Text -> List(Text)
	split = |Text.(s), Text.(sep)| if List.len(sep) == 0 { [Text.(s)] } else { Text.split_from(s, sep, 0, []) }

	split_from : List(U8), List(U8), U64, List(Text) -> List(Text)
	split_from = |s, sep, start, acc| {
		p = Text.find(s, sep, start)
		if p < 0 {
			List.append(acc, Text.(List.drop_first(s, start)))
		} else {
			at = I64.to_u64_wrap(p)
			Text.split_from(s, sep, at + List.len(sep), List.append(acc, Text.(List.sublist(s, { start: start, len: at - start }))))
		}
	}

	# `text-concat-list` (`cx_text_concat_list`).
	concat_list : List(Text) -> Text
	concat_list = |l| Text.(List.fold(l, [], |acc, Text.(p)| List.concat(acc, p)))

	# `text-to-integer` (`cx_text_to_integer`): a minus only as the first unit,
	# then decimal digits, units 3..12, until the first unit that is not one,
	# wrapping. So `+7` and ` 42` are 0, and `12abc` is 12.
	to_integer : Text -> I64
	to_integer = |Text.(s)| {
		neg = (List.get(s, 0) ?? 0) == 73
		n = Text.digits_from(s, if neg { 1 } else { 0 }, 0)
		if neg { I64.minus_wrap(0, n) } else { n }
	}

	digits_from : List(U8), U64, I64 -> I64
	digits_from = |s, i, acc| {
		u = Text.at(s, i)
		if u >= 3 and u <= 12 { Text.digits_from(s, i + 1, I64.plus_wrap(I64.times_wrap(acc, 10), U64.to_i64_wrap(u - 3))) } else { acc }
	}

	# `show` of an integer (`cx_show_int`): its decimal digits as units, 3 + d
	# each, and 73 for a minus.
	show_int : I64 -> Text
	show_int = |n| Text.(List.map(Str.to_utf8(I64.to_str(n)), |b| if b == 45 { 73 } else { b - 45 }))

	# `raw-bytes-to-text`: each integer's low byte, a unit as given.
	of_bytes : List(I64) -> Text
	of_bytes = |xs| Text.(List.map(xs, |b| I64.to_u8_wrap(b)))

	# A platform's Str as units (`cx_utf8_to_cce`): each code point's code,
	# framed.
	of_str : Str -> Text
	of_str = |str| Text.(Text.of_utf8(Str.to_utf8(str), 0, []))

	of_utf8 : List(U8), U64, List(U8) -> List(U8)
	of_utf8 = |bytes, i, acc|
		if i >= List.len(bytes) { acc } else {
			b = Text.at(bytes, i)
			width = if b < 128 { 1 } else if b < 224 { 2 } else if b < 240 { 3 } else { 4 }
			point = if width == 1 { b } else { Text.tail(bytes, i + 1, i + width, Text.lead(b, width)) }
			Text.of_utf8(bytes, i + width, List.concat(acc, Text.frame(Text.code_of_point(point))))
		}

	lead : U64, U64 -> U64
	lead = |b, width|
		if width == 2 { U64.bitwise_and(b, 31) }
		else if width == 3 { U64.bitwise_and(b, 15) }
		else { U64.bitwise_and(b, 7) }

	tail : List(U8), U64, U64, U64 -> U64
	tail = |bytes, i, stop, acc|
		if i >= stop { acc } else { Text.tail(bytes, i + 1, stop, acc * 64 + U64.bitwise_and(Text.at(bytes, i), 63)) }

	# A unit as a U64, 0 past the end.
	at : List(U8), U64 -> U64
	at = |s, k| U8.to_u64(List.get(s, k) ?? 0)

	# `cx_cp_to_cce`: the code for a code point, tier 0 first; a point no tier
	# covers is `?`, 68.
	code_of_point : U64 -> U64
	code_of_point = |p|
		if p < 128 { List.get(Text.codes, p) ?? 68 } else { Text.high_code(p, 97) }

	high_code : U64, U64 -> U64
	high_code = |p, c|
		if c > 127 { Text.tier1_code(p, 0) }
		else if (List.get(Text.points, c) ?? 0) == p { c }
		else { Text.high_code(p, c + 1) }

	tier1_code : U64, U64 -> U64
	tier1_code = |p, k|
		if k >= List.len(Text.t1_uni) { Text.tier2_code(p, 0, 2176) } else {
			uni = List.get(Text.t1_uni, k) ?? 0
			size = List.get(Text.t1_size, k) ?? 0
			if p >= uni and p < uni + size { (List.get(Text.t1_code, k) ?? 0) + (p - uni) } else { Text.tier1_code(p, k + 1) }
		}

	tier2_code : U64, U64, U64 -> U64
	tier2_code = |p, k, base|
		if k >= List.len(Text.t2_uni) { 68 } else {
			uni = List.get(Text.t2_uni, k) ?? 0
			size = List.get(Text.t2_size, k) ?? 0
			if p >= uni and p < uni + size { base + (p - uni) } else { Text.tier2_code(p, k + 1, base + size) }
		}

	# **THE UNITS AS x86's PRINT LOOP WRITES THEM** (`emit-print-text-loop`,
	# `__cce_print_multi`), then read as UTF-8 for the platform: a unit below
	# 128 is its tier-0 code point; a unit whose top nibble is 1110 starts a
	# 3-unit tier-2 frame; every other unit from 128 is taken as a 2-unit tier-1
	# frame. Each byte is the low byte of the shifted value, and a unit past the
	# end reads as 0. A sequence x86 writes that is not UTF-8 (an overlong code
	# point from a negative tier-2 delta) arrives as U+FFFD.
	printed : Text -> Str
	printed = |Text.(s)| Str.from_utf8_lossy(Text.print_from(s, 0, []))

	print_from : List(U8), U64, List(U8) -> List(U8)
	print_from = |s, i, out|
		if i >= List.len(s) { out } else {
			b0 = Text.at(s, i)
			if b0 < 128 {
				Text.print_from(s, i + 1, List.concat(out, Text.utf8_3(List.get(Text.points, b0) ?? 0)))
			} else if U64.bitwise_and(b0, 240) == 224 {
				code = 2176 + U64.bitwise_and(b0, 15) * 4096 + U64.bitwise_and(Text.at(s, i + 1), 63) * 64 + U64.bitwise_and(Text.at(s, i + 2), 63)
				Text.print_from(s, i + 3, List.concat(out, Text.utf8_4(Text.x86_t2_point(code, 0))))
			} else {
				v = U64.bitwise_and(b0, 31) * 64 + U64.bitwise_and(Text.at(s, i + 1), 63)
				cp = (List.get(Text.x86_t1_bases, U64.div_by(v, 128)) ?? 0) + U64.bitwise_and(v, 127)
				Text.print_from(s, i + 2, List.concat(out, Text.utf8_3(cp)))
			}
		}

	x86_t2_point : U64, U64 -> U64
	x86_t2_point = |code, k|
		if k >= List.len(Text.x86_t2_end) { 65533 }
		else if code < (List.get(Text.x86_t2_end, k) ?? 0) { code + (List.get(Text.x86_t2_delta, k) ?? 0) }
		else { Text.x86_t2_point(code, k + 1) }

	# A code point in 1, 2 or 3 bytes.
	utf8_3 : U64 -> List(U8)
	utf8_3 = |cp|
		if cp < 128 { [Text.low(cp)] }
		else if cp < 2048 { [Text.low(U64.bitwise_or(U64.div_by(cp, 64), 192)), Text.cont(cp)] }
		else { [Text.low(U64.bitwise_or(U64.div_by(cp, 4096), 224)), Text.cont(U64.div_by(cp, 64)), Text.cont(cp)] }

	# A code point in 3 bytes below 65536 and 4 from there, as x86's tier-2
	# path writes it.
	utf8_4 : U64 -> List(U8)
	utf8_4 = |cp|
		if cp < 65536 { [Text.low(U64.bitwise_or(U64.div_by(cp, 4096), 224)), Text.cont(U64.div_by(cp, 64)), Text.cont(cp)] }
		else { [Text.low(U64.bitwise_or(U64.div_by(cp, 262144), 240)), Text.cont(U64.div_by(cp, 4096)), Text.cont(U64.div_by(cp, 64)), Text.cont(cp)] }

	# A continuation byte: the low six bits, with the top bit set.
	cont : U64 -> U8
	cont = |v| Text.low(U64.bitwise_or(U64.bitwise_and(v, 63), 128))

	# A door's answer whose text comes from the machine, as units.
	answer_units : (a, Str) -> (a, Text)
	answer_units = |pair| (pair.0, Text.of_str(pair.1))
}
