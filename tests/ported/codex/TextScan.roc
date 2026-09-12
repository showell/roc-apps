# TextScan -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Cce

TextScan :: [].{

	text_fold_indexed : Str, a, (a, I64, I64 -> a) -> a
	text_fold_indexed = |s, init, f| text_fold_indexed_loop(s, init, f, 0, Cce.length(s))

	text_fold_indexed_loop : Str, a, (a, I64, I64 -> a), I64, I64 -> a
	text_fold_indexed_loop = |s, acc, f, i, len| (if (i >= len) { acc } else { text_fold_indexed_loop(s, f(acc, Cce.at_or_crash(s, i), i), f, (i + 1), len) })

	text_fold_back : Str, a, (a, I64, I64 -> a) -> a
	text_fold_back = |s, init, f| text_fold_back_loop(s, init, f, (Cce.length(s) - 1))

	text_fold_back_loop : Str, a, (a, I64, I64 -> a), I64 -> a
	text_fold_back_loop = |s, acc, f, i| (if (i < 0) { acc } else { text_fold_back_loop(s, f(acc, Cce.at_or_crash(s, i), i), f, (i - 1)) })

	text_map_chars : Str, (I64 -> I64) -> Str
	text_map_chars = |s, f| text_map_chars_loop(s, f, 0, Cce.length(s), "")

	text_map_chars_loop : Str, (I64 -> I64), I64, I64, Str -> Str
	text_map_chars_loop = |s, f, i, len, acc| (if (i >= len) { acc } else { text_map_chars_loop(s, f, (i + 1), len, Str.concat(acc, Cce.text(f(Cce.at_or_crash(s, i))))) })

	text_find_char : Str, (I64 -> Bool) -> I64
	text_find_char = |s, pred| text_find_char_from(s, pred, 0)

	text_find_char_from : Str, (I64 -> Bool), I64 -> I64
	text_find_char_from = |s, pred, start| text_find_char_loop(s, pred, start, Cce.length(s))

	text_find_char_loop : Str, (I64 -> Bool), I64, I64 -> I64
	text_find_char_loop = |s, pred, i, len| (if (i >= len) { (-1) } else { (if pred(Cce.at_or_crash(s, i)) { i } else { text_find_char_loop(s, pred, (i + 1), len) }) })

	text_match_at : Str, Str, I64 -> Bool
	text_match_at = |haystack, needle, offset| ({
		nlen = Cce.length(needle)
		(if ((offset + nlen) > Cce.length(haystack)) { False } else { text_match_at_loop(haystack, needle, offset, 0, nlen) })
	})

	text_match_at_loop : Str, Str, I64, I64, I64 -> Bool
	text_match_at_loop = |haystack, needle, offset, i, nlen| (if (i >= nlen) { True } else { (if (Cce.at_or_crash(haystack, (offset + i)) != Cce.at_or_crash(needle, i)) { False } else { text_match_at_loop(haystack, needle, offset, (i + 1), nlen) }) })

	text_repeat : Str, I64 -> Str
	text_repeat = |s, n| text_repeat_loop(s, n, 0, "")

	text_repeat_loop : Str, I64, I64, Str -> Str
	text_repeat_loop = |s, n, i, acc| (if (i >= n) { acc } else { text_repeat_loop(s, n, (i + 1), Str.concat(acc, s)) })

	text_pad_left_char : Str, I64, I64 -> Str
	text_pad_left_char = |s, width, pad_char| ({
		slen = Cce.length(s)
		(if (slen >= width) { s } else { Str.concat(text_repeat(Cce.text(pad_char), (width - slen)), s) })
	})
}
