# CceChar -- a Codex Char, written by rocemit (rust-codex-compiler). Do not edit.
#
# A Codex Char is a CCE CODE: a position in Cobblestone's frequency-ordered
# alphabet, where 'a' is 15, not the 97 of Unicode. Its own type, not an I64, so
# the Roc says where a Codex Char was: `char-code` and `code-to-char` are `code`
# and `of_code`, and a CceChar is compared and classified only through them.

CceChar :: I64.{
	of_code : I64 -> CceChar
	of_code = |c| CceChar.(c)

	code : CceChar -> I64
	code = |CceChar.(c)| c

	is_eq : CceChar, CceChar -> Bool
	is_eq = |CceChar.(a), CceChar.(b)| a == b

	is_lt : CceChar, CceChar -> Bool
	is_lt = |CceChar.(a), CceChar.(b)| a < b

	is_gt : CceChar, CceChar -> Bool
	is_gt = |CceChar.(a), CceChar.(b)| a > b

	is_lte : CceChar, CceChar -> Bool
	is_lte = |CceChar.(a), CceChar.(b)| a <= b

	is_gte : CceChar, CceChar -> Bool
	is_gte = |CceChar.(a), CceChar.(b)| a >= b

	to_hash : CceChar, Hasher -> Hasher
	to_hash = |CceChar.(c), hasher| Hasher.write_i64(hasher, c)

	# The classifiers are code RANGES, not the host's idea of a letter: the
	# alphabet is frequency-ordered (interp.rs).
	is_letter : CceChar -> Bool
	is_letter = |CceChar.(x)| (x >= 13 and x <= 64) or (x >= 97 and x <= 127)

	is_digit : CceChar -> Bool
	is_digit = |CceChar.(x)| x >= 3 and x <= 12

	is_whitespace : CceChar -> Bool
	is_whitespace = |CceChar.(x)| x >= 1 and x <= 2
}
