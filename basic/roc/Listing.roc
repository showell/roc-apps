# The load-time check of a listing in ECMA-55: the faults of a program as
# a whole, found before its first statement runs.
#
# ECMA-55 rejects a program for these rather than running the part above
# the fault, and the NBS suite's ERROR programs exist to check that it
# does. A microcomputer BASIC sorted what was typed and ran it, so only the
# ECMA-55 door asks; 26 of the 99 game listings would not get past it.
#
# It reads the raw text, before `Basic.load` sorts the lines and drops what
# it cannot number, because those are exactly the faults.

Listing :: [].{
	Rejection : { why : Str, num : I64 }

	# The first fault in a listing, `why` empty when there is none. `num` is
	# the line it concerns, or the line before it; -1 before any line.
	check : Str -> Rejection
	check = |src| Listing.lines(Str.to_utf8(src), 0, -1, False)

	# `prev` is the last line number seen, `ended` that its line was END.
	lines : List(U8), U64, I64, Bool -> Rejection
	lines = |b, i, prev, ended|
		if i >= List.len(b) {
			if ended { { why: "", num: -1 } } else { { why: "The last line is not END", num: prev } }
		} else {
			e = Listing.eol(b, i)
			# A DOS listing's carriage return is not part of the line.
			stop = if e > i and Listing.byte(b, e - 1) == 13 { e - 1 } else { e }
			s = Listing.skip_ws(b, i)
			d = Listing.digits_end(b, s)
			g = Listing.skip_ws(b, d)
			if s >= stop {
				Listing.lines(b, e + 1, prev, ended)
			} else if d == s {
				{ why: "A line has no line number", num: prev }
			} else {
				n = Listing.digits_val(b, s, d, 0)
				# `2 40 PRINT` would otherwise be line 2 with a statement
				# that starts "40".
				if g > d and g < stop and Listing.is_digit(Listing.byte(b, g)) {
					{ why: "A space inside a line number", num: n }
				} else if d - s > 4 {
					{ why: "A line number longer than four digits", num: n }
				} else if n == 0 {
					{ why: "Line number 0", num: n }
				} else if n == prev {
					{ why: "A line number used twice", num: n }
				} else if n < prev {
					{ why: "A line number out of order", num: n }
				} else if stop - i > 72 {
					{ why: "A line longer than 72 characters", num: n }
				} else if ended {
					{ why: "END is not the last line", num: prev }
				} else {
					Listing.lines(b, e + 1, n, Listing.is_end(b, g, stop))
				}
			}
		}

	is_end : List(U8), U64, U64 -> Bool
	is_end = |b, g, stop| {
		word = Listing.upper(Listing.byte(b, g)) == 69 and Listing.upper(Listing.byte(b, g + 1)) == 78 and Listing.upper(Listing.byte(b, g + 2)) == 68
		word and (g + 3 >= stop or !Listing.is_alpha(Listing.byte(b, g + 3)))
	}

	byte : List(U8), U64 -> U8
	byte = |b, i| List.get(b, i) ?? 0

	eol : List(U8), U64 -> U64
	eol = |b, i| if i >= List.len(b) or Listing.byte(b, i) == 10 { i } else { Listing.eol(b, i + 1) }

	skip_ws : List(U8), U64 -> U64
	skip_ws = |b, i| if Listing.byte(b, i) == 32 or Listing.byte(b, i) == 9 { Listing.skip_ws(b, i + 1) } else { i }

	is_digit : U8 -> Bool
	is_digit = |c| c >= 48 and c <= 57

	is_alpha : U8 -> Bool
	is_alpha = |c| (c >= 65 and c <= 90) or (c >= 97 and c <= 122)

	upper : U8 -> U8
	upper = |c| if c >= 97 and c <= 122 { c - 32 } else { c }

	digits_end : List(U8), U64 -> U64
	digits_end = |b, i| if Listing.is_digit(Listing.byte(b, i)) { Listing.digits_end(b, i + 1) } else { i }

	# Only the first nine digits count: a line number past four is refused
	# by length, and an I64 that `*` overflows is a crash in Roc.
	digits_val : List(U8), U64, U64, I64 -> I64
	digits_val = |b, i, e, acc|
		if i >= e or acc > 99999999 { acc } else { Listing.digits_val(b, i + 1, e, acc * 10 + U8.to_i64(Listing.byte(b, i)) - 48) }
}
