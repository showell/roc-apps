# Cce -- the Codex character alphabet, written from the compiler's own
# tables by rocemit (rust-codex-compiler). Do not edit.
#
# A Codex Char is its CODE in a private frequency-ordered alphabet of
# 1..127: `char-code 'A'` is 41, not 65. Codes 97..127 are accented Latin
# and Cyrillic, which no byte reaches. A Codex Text is a sequence of those
# units, ONE PER CHARACTER, so `text-length` counts characters and
# `char-code-at` indexes them.

Cce :: [].{
	# The code of each of the first 128 Unicode code points; 0 for a point
	# the alphabet does not name.
	codes : List(I64)
	codes = [
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		2, 67, 72, 83, 95, 96, 84, 71, 74, 75, 78, 76, 66, 73, 65, 81,
		3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 69, 70, 79, 77, 80, 68,
		82, 41, 58, 50, 48, 39, 54, 55, 46, 43, 61, 60, 49, 52, 44, 42,
		57, 63, 47, 45, 40, 51, 59, 53, 62, 56, 64, 88, 86, 89, 94, 85,
		93, 15, 32, 24, 22, 13, 28, 29, 20, 17, 35, 34, 23, 26, 18, 16,
		31, 37, 21, 19, 14, 25, 33, 27, 36, 30, 38, 90, 87, 91, 92, 0
	]

	# The code point each code names, indexed by code; 0 for none.
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

	# The code of one Unicode code point, or 0.
	of_point : U64 -> I64
	of_point = |p|
		if p < 128 { List.get(Cce.codes, p) ?? 0 } else { Cce.high_of(p, 97) }

	high_of : U64, I64 -> I64
	high_of = |p, c|
		if c > 127 { 0 }
		else if (List.get(Cce.points, I64.to_u64_wrap(c)) ?? 0) == p { c }
		else { Cce.high_of(p, c + 1) }

	# A text as its codes, one per character.
	codes_of : Str -> List(I64)
	codes_of = |s| Cce.decode(Str.to_utf8(s), 0, [])

	decode : List(U8), U64, List(I64) -> List(I64)
	decode = |bytes, i, acc|
		if i >= List.len(bytes) { acc } else {
			b = U8.to_u64(List.get(bytes, i) ?? 0)
			# The alphabet reaches no further than two UTF-8 bytes, but a
			# text may hold anything; a character the alphabet does not
			# name is code 0, as `char-code` answers.
			width = if b < 128 { 1 } else if b < 224 { 2 } else if b < 240 { 3 } else { 4 }
			point = if width == 1 { b } else {
				Cce.tail(bytes, i + 1, i + width, Cce.lead(b, width))
			}
			Cce.decode(bytes, i + width, List.append(acc, Cce.of_point(point)))
		}

	lead : U64, U64 -> U64
	lead = |b, width|
		if width == 2 { U64.bitwise_and(b, 31) }
		else if width == 3 { U64.bitwise_and(b, 15) }
		else { U64.bitwise_and(b, 7) }

	tail : List(U8), U64, U64, U64 -> U64
	tail = |bytes, i, stop, acc|
		if i >= stop { acc } else {
			b = U8.to_u64(List.get(bytes, i) ?? 0)
			Cce.tail(bytes, i + 1, stop, acc * 64 + U64.bitwise_and(b, 63))
		}

	# `text-length`: the count of characters.
	length : Str -> I64
	length = |s| U64.to_i64_wrap(List.len(Cce.codes_of(s)))

	# `char-code-at`: the code of the i-th character, 0 past the end.
	at : Str, I64 -> I64
	at = |s, i| if i < 0 { 0 } else { List.get(Cce.codes_of(s), I64.to_u64_wrap(i)) ?? 0 }

	# `char-at` answers a character and refuses to run past the end.
	at_or_crash : Str, I64 -> I64
	at_or_crash = |s, i|
		if i < 0 { crash("char-at past the end") }
		else { List.get(Cce.codes_of(s), I64.to_u64_wrap(i)) ?? crash("char-at past the end") }

	# `char-to-text`, and what `show` of a Char prints.
	text : I64 -> Str
	text = |c| Str.from_utf8(Cce.utf8(Cce.to_point(c))) ?? ""

	to_point : I64 -> U64
	to_point = |c| if c < 0 or c > 127 { 0 } else { List.get(Cce.points, I64.to_u64_wrap(c)) ?? 0 }

	utf8 : U64 -> List(U8)
	utf8 = |p|
		if p < 128 { [U64.to_u8_wrap(p)] }
		else if p < 2048 { [U64.to_u8_wrap(192 + U64.div_by(p, 64)), U64.to_u8_wrap(128 + U64.bitwise_and(p, 63))] }
		else { [
			U64.to_u8_wrap(224 + U64.div_by(p, 4096)),
			U64.to_u8_wrap(128 + U64.bitwise_and(U64.div_by(p, 64), 63)),
			U64.to_u8_wrap(128 + U64.bitwise_and(p, 63)),
		] }

	# `text-compare` is over CCE units, which is this alphabet's order and
	# not ASCII's: -1, 0 or 1.
	compare : Str, Str -> I64
	compare = |a, b| Cce.compare_codes(Cce.codes_of(a), Cce.codes_of(b), 0)

	compare_codes : List(I64), List(I64), U64 -> I64
	compare_codes = |xs, ys, i| {
		x = List.get(xs, i)
		y = List.get(ys, i)
		match (x, y) {
			(Err(_), Err(_)) => 0
			(Err(_), Ok(_)) => -1
			(Ok(_), Err(_)) => 1
			(Ok(a), Ok(b)) => if a < b { -1 } else if a > b { 1 } else { Cce.compare_codes(xs, ys, i + 1) }
		}
	}

	# `substring`, over characters.
	substring : Str, I64, I64 -> Str
	substring = |s, start, len| Cce.str_of(List.sublist(Cce.codes_of(s), { start: I64.to_u64_wrap(I64.max(start, 0)), len: I64.to_u64_wrap(I64.max(len, 0)) }))

	str_of : List(I64) -> Str
	str_of = |cs| List.fold(cs, "", |acc, c| Str.concat(acc, Cce.text(c)))
}
