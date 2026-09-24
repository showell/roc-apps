# TextWrap -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

TextWrap :: [].{

	text_wrap : Text, I64 -> Text
	text_wrap = |s, width| ({
		words = Text.split(s, " ")
		wrap_words(words, width, 0, U64.to_i64_wrap(List.len(words)), 0, "")
	})

	wrap_words : List(Text), I64, I64, I64, I64, Text -> Text
	wrap_words = |words, width, i, n, col, acc| (if (i >= n) { acc } else { ({
		word = (List.get(words, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		wlen = Text.len(word)
		(if (col == 0) { wrap_words(words, width, (i + 1), n, wlen, Text.concat(acc, word)) } else { (if (((col + 1) + wlen) > width) { wrap_words(words, width, (i + 1), n, wlen, Text.concat(Text.concat(acc, "\n"), word)) } else { wrap_words(words, width, (i + 1), n, ((col + 1) + wlen), Text.concat(Text.concat(acc, " "), word)) }) })
	}) })

	text_wrap_lines : Text, I64 -> List(Text)
	text_wrap_lines = |s, width| ({
		wrapped = text_wrap(s, width)
		Text.split(wrapped, "\n")
	})

	text_truncate : Text, I64, Text -> Text
	text_truncate = |s, max_len, ellipsis| (if (Text.len(s) <= max_len) { s } else { ({
		elen = Text.len(ellipsis)
		Text.concat(tw_take(s, (max_len - elen)), ellipsis)
	}) })

	tw_take : Text, I64 -> Text
	tw_take = |s, n| Text.substring(s, 0, n)

	text_center : Text, I64 -> Text
	text_center = |s, width| ({
		len = Text.len(s)
		(if (len >= width) { s } else { ({
			pad = I64.div_trunc_by((width - len), 2)
			Text.concat(tw_spaces(pad), s)
		}) })
	})

	text_right_align : Text, I64 -> Text
	text_right_align = |s, width| ({
		len = Text.len(s)
		(if (len >= width) { s } else { Text.concat(tw_spaces((width - len)), s) })
	})

	tw_spaces : I64 -> Text
	tw_spaces = |n| tw_spaces_loop(n, "")

	tw_spaces_loop : I64, Text -> Text
	tw_spaces_loop = |n, acc| (if (n <= 0) { acc } else { tw_spaces_loop((n - 1), Text.concat(acc, " ")) })

	text_box : Text, I64 -> Text
	text_box = |s, width| ({
		border = tw_repeat_char("-", (width + 2))
		padded = tw_pad_line(s, width)
		Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat(Text.concat("+", border), "+"), "\n"), "| "), padded), " |"), "\n"), "+"), border), "+")
	})

	tw_pad_line : Text, I64 -> Text
	tw_pad_line = |s, width| ({
		len = Text.len(s)
		(if (len >= width) { s } else { Text.concat(s, tw_spaces((width - len))) })
	})

	tw_repeat_char : Text, I64 -> Text
	tw_repeat_char = |ch, n| tw_rep_loop(ch, n, "")

	tw_rep_loop : Text, I64, Text -> Text
	tw_rep_loop = |ch, n, acc| (if (n <= 0) { acc } else { tw_rep_loop(ch, (n - 1), Text.concat(acc, ch)) })
}
