# TextScan -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceChar
import CceText

TextScan :: [].{

	text_fold_indexed : CceText, a, (a, CceChar, I64 -> a) -> a
	text_fold_indexed = |s, init, f| text_fold_indexed_loop(s, init, f, 0, CceText.len(s))

	text_fold_indexed_loop : CceText, a, (a, CceChar, I64 -> a), I64, I64 -> a
	text_fold_indexed_loop = |s, acc, f, i, len| (if (i >= len) { acc } else { text_fold_indexed_loop(s, f(acc, CceText.char_at(s, i), i), f, (i + 1), len) })

	text_fold_back : CceText, a, (a, CceChar, I64 -> a) -> a
	text_fold_back = |s, init, f| text_fold_back_loop(s, init, f, (CceText.len(s) - 1))

	text_fold_back_loop : CceText, a, (a, CceChar, I64 -> a), I64 -> a
	text_fold_back_loop = |s, acc, f, i| (if (i < 0) { acc } else { text_fold_back_loop(s, f(acc, CceText.char_at(s, i), i), f, (i - 1)) })

	text_map_chars : CceText, (CceChar -> CceChar) -> CceText
	text_map_chars = |s, f| text_map_chars_loop(s, f, 0, CceText.len(s), "")

	text_map_chars_loop : CceText, (CceChar -> CceChar), I64, I64, CceText -> CceText
	text_map_chars_loop = |s, f, i, len, acc| (if (i >= len) { acc } else { text_map_chars_loop(s, f, (i + 1), len, CceText.concat(acc, CceText.char_to_text(f(CceText.char_at(s, i))))) })

	text_find_char : CceText, (CceChar -> Bool) -> I64
	text_find_char = |s, pred| text_find_char_from(s, pred, 0)

	text_find_char_from : CceText, (CceChar -> Bool), I64 -> I64
	text_find_char_from = |s, pred, start| text_find_char_loop(s, pred, start, CceText.len(s))

	text_find_char_loop : CceText, (CceChar -> Bool), I64, I64 -> I64
	text_find_char_loop = |s, pred, i, len| (if (i >= len) { (-1) } else { (if pred(CceText.char_at(s, i)) { i } else { text_find_char_loop(s, pred, (i + 1), len) }) })

	text_match_at : CceText, CceText, I64 -> Bool
	text_match_at = |haystack, needle, offset| ({
		nlen : I64
		nlen = CceText.len(needle)
		(if ((offset + nlen) > CceText.len(haystack)) { False } else { text_match_at_loop(haystack, needle, offset, 0, nlen) })
	})

	text_match_at_loop : CceText, CceText, I64, I64, I64 -> Bool
	text_match_at_loop = |haystack, needle, offset, i, nlen| (if (i >= nlen) { True } else { (if (CceText.char_at(haystack, (offset + i)) != CceText.char_at(needle, i)) { False } else { text_match_at_loop(haystack, needle, offset, (i + 1), nlen) }) })

	text_repeat : CceText, I64 -> CceText
	text_repeat = |s, n| text_repeat_loop(s, n, 0, "")

	text_repeat_loop : CceText, I64, I64, CceText -> CceText
	text_repeat_loop = |s, n, i, acc| (if (i >= n) { acc } else { text_repeat_loop(s, n, (i + 1), CceText.concat(acc, s)) })

	text_pad_left_char : CceText, I64, CceChar -> CceText
	text_pad_left_char = |s, width, pad_char| ({
		slen : I64
		slen = CceText.len(s)
		(if (slen >= width) { s } else { CceText.concat(text_repeat(CceText.char_to_text(pad_char), (width - slen)), s) })
	})
}
