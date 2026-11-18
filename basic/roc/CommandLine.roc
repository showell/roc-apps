# A batch command's texts, as basic-run and basic-check take them.
#
# Each text is cleaned: a carriage return is dropped, a newline and a tab are
# kept, and any other byte outside printable ASCII becomes a space.
CommandLine :: [].{
	clean : Str -> Str
	clean = |text| Str.from_utf8(CommandLine.clean_bytes(text.to_utf8(), 0, [])) ?? ""

	clean_bytes : List(U8), U64, List(U8) -> List(U8)
	clean_bytes = |b, i, acc|
		if i >= b.len() {
			acc
		} else {
			c = b.get(i) ?? 32
			next = if c == 13 {
				acc
			} else if c == 10 or c == 9 {
				acc.append(c)
			} else if c < 32 or c > 126 {
				acc.append(32)
			} else {
				acc.append(c)
			}
			CommandLine.clean_bytes(b, i + 1, next)
		}

	# The replies split on newlines. A final newline ends the last line rather
	# than starting an empty one.
	lines_of : Str -> List(Str)
	lines_of = |text| CommandLine.lines_from(text.to_utf8(), 0, 0, [])

	lines_from : List(U8), U64, U64, List(Str) -> List(Str)
	lines_from = |b, from, i, acc|
		if i >= b.len() {
			if i > from {
				acc.append(CommandLine.piece(b, from, i))
			} else {
				acc
			}
		} else if (b.get(i) ?? 0) == 10 {
			CommandLine.lines_from(b, i + 1, i + 1, acc.append(CommandLine.piece(b, from, i)))
		} else {
			CommandLine.lines_from(b, from, i + 1, acc)
		}

	piece : List(U8), U64, U64 -> Str
	piece = |b, from, i| Str.from_utf8(b.sublist({ start: from, len: i - from })) ?? ""
}
