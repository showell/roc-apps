# BASIC as a command: the interpreter's batch doors behind one executable,
# built once on Roc's default platform.
#
#   basic-run ecma  "<listing>" "<replies>"
#   basic-run micro "<listing>" "<replies>"
#
# **THE INTERPRETER IS A PURE FUNCTION**, so the command line is all the
# input it needs: a listing and its replies arrive as arguments, the
# transcript leaves by `echo!`. Nothing waits and nothing sleeps -- the
# batch doors take every reply up front, and a SLEEP takes no time.
#
# Each text is cleaned as basic/gen.py cleaned the string literals it
# generated: a carriage return is dropped, a newline and a tab are kept,
# and any other byte outside printable ASCII becomes a space.
import Basic

main! = |args| {
	dialect = List.get(args, 0) ?? ""
	listing = clean(List.get(args, 1) ?? "")
	replies = lines_of(Str.to_utf8(clean(List.get(args, 2) ?? "")), 0, 0, [])
	# A generated app's seed was 1 plus its argument count, and it had none.
	seed = 1
	transcript = if dialect == "ecma" { Basic.run_ecma(listing, replies, seed) } else { Basic.run(listing, replies, seed) }
	echo!(transcript)
	Ok({})
}

clean : Str -> Str
clean = |text| Str.from_utf8(clean_bytes(Str.to_utf8(text), 0, [])) ?? ""

clean_bytes : List(U8), U64, List(U8) -> List(U8)
clean_bytes = |b, i, acc|
	if i >= List.len(b) {
		acc
	} else {
		c = List.get(b, i) ?? 32
		next = if c == 13 { acc } else if c == 10 or c == 9 { List.append(acc, c) } else if c < 32 or c > 126 { List.append(acc, 32) } else { List.append(acc, c) }
		clean_bytes(b, i + 1, next)
	}

# The replies split on newlines. A final newline ends the last line rather
# than starting an empty one.
lines_of : List(U8), U64, U64, List(Str) -> List(Str)
lines_of = |b, from, i, acc|
	if i >= List.len(b) {
		if i > from { List.append(acc, piece(b, from, i)) } else { acc }
	} else if (List.get(b, i) ?? 0) == 10 {
		lines_of(b, i + 1, i + 1, List.append(acc, piece(b, from, i)))
	} else {
		lines_of(b, from, i + 1, acc)
	}

piece : List(U8), U64, U64 -> Str
piece = |b, from, i| Str.from_utf8(List.sublist(b, { start: from, len: i - from })) ?? ""
