# TextScan -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

TextScan :: [].{

	text_fold_indexed : Text, a, (a, I64, I64 -> a) -> a
	text_fold_indexed = |s, init, f| text_fold_indexed_loop(s, init, f, 0, Text.len(s))

	text_fold_indexed_loop : Text, a, (a, I64, I64 -> a), I64, I64 -> a
	text_fold_indexed_loop = |s, acc, f, i, len| (if (i >= len) { acc } else { text_fold_indexed_loop(s, f(acc, Text.char_at(s, i), i), f, (i + 1), len) })

	text_fold_back : Text, a, (a, I64, I64 -> a) -> a
	text_fold_back = |s, init, f| text_fold_back_loop(s, init, f, (Text.len(s) - 1))

	text_fold_back_loop : Text, a, (a, I64, I64 -> a), I64 -> a
	text_fold_back_loop = |s, acc, f, i| (if (i < 0) { acc } else { text_fold_back_loop(s, f(acc, Text.char_at(s, i), i), f, (i - 1)) })

	text_map_chars : Text, (I64 -> I64) -> Text
	text_map_chars = |s, f| text_map_chars_loop(s, f, 0, Text.len(s), "")

	text_map_chars_loop : Text, (I64 -> I64), I64, I64, Text -> Text
	text_map_chars_loop = |s, f, i, len, acc| (if (i >= len) { acc } else { text_map_chars_loop(s, f, (i + 1), len, Text.concat(acc, Text.char_to_text(f(Text.char_at(s, i))))) })

	text_find_char : Text, (I64 -> Bool) -> I64
	text_find_char = |s, pred| text_find_char_from(s, pred, 0)

	text_find_char_from : Text, (I64 -> Bool), I64 -> I64
	text_find_char_from = |s, pred, start| text_find_char_loop(s, pred, start, Text.len(s))

	text_find_char_loop : Text, (I64 -> Bool), I64, I64 -> I64
	text_find_char_loop = |s, pred, i, len| (if (i >= len) { (-1) } else { (if pred(Text.char_at(s, i)) { i } else { text_find_char_loop(s, pred, (i + 1), len) }) })

	text_match_at : Text, Text, I64 -> Bool
	text_match_at = |haystack, needle, offset| ({
		nlen = Text.len(needle)
		(if ((offset + nlen) > Text.len(haystack)) { False } else { text_match_at_loop(haystack, needle, offset, 0, nlen) })
	})

	text_match_at_loop : Text, Text, I64, I64, I64 -> Bool
	text_match_at_loop = |haystack, needle, offset, i, nlen| (if (i >= nlen) { True } else { (if (Text.char_at(haystack, (offset + i)) != Text.char_at(needle, i)) { False } else { text_match_at_loop(haystack, needle, offset, (i + 1), nlen) }) })

	text_repeat : Text, I64 -> Text
	text_repeat = |s, n| text_repeat_loop(s, n, 0, "")

	text_repeat_loop : Text, I64, I64, Text -> Text
	text_repeat_loop = |s, n, i, acc| (if (i >= n) { acc } else { text_repeat_loop(s, n, (i + 1), Text.concat(acc, s)) })

	text_pad_left_char : Text, I64, I64 -> Text
	text_pad_left_char = |s, width, pad_char| ({
		slen = Text.len(s)
		(if (slen >= width) { s } else { Text.concat(text_repeat(Text.char_to_text(pad_char), (width - slen)), s) })
	})
}
