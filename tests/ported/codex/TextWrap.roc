# TextWrap -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

TextWrap :: [].{

	text_wrap : List(U8), I64 -> List(U8)
	text_wrap = |s, width| ({
		words = Text.split(s, [2])
		wrap_words(words, width, 0, U64.to_i64_wrap(List.len(words)), 0, [])
	})

	wrap_words : List(List(U8)), I64, I64, I64, I64, List(U8) -> List(U8)
	wrap_words = |words, width, i, n, col, acc| (if (i >= n) { acc } else { ({
		word = (List.get(words, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		wlen = Text.len(word)
		(if (col == 0) { wrap_words(words, width, (i + 1), n, wlen, List.concat(acc, word)) } else { (if (((col + 1) + wlen) > width) { wrap_words(words, width, (i + 1), n, wlen, List.concat(List.concat(acc, [1]), word)) } else { wrap_words(words, width, (i + 1), n, ((col + 1) + wlen), List.concat(List.concat(acc, [2]), word)) }) })
	}) })

	text_wrap_lines : List(U8), I64 -> List(List(U8))
	text_wrap_lines = |s, width| ({
		wrapped = text_wrap(s, width)
		Text.split(wrapped, [1])
	})

	text_truncate : List(U8), I64, List(U8) -> List(U8)
	text_truncate = |s, max_len, ellipsis| (if (Text.len(s) <= max_len) { s } else { ({
		elen = Text.len(ellipsis)
		List.concat(tw_take(s, (max_len - elen)), ellipsis)
	}) })

	tw_take : List(U8), I64 -> List(U8)
	tw_take = |s, n| Text.substring(s, 0, n)

	text_center : List(U8), I64 -> List(U8)
	text_center = |s, width| ({
		len = Text.len(s)
		(if (len >= width) { s } else { ({
			pad = I64.div_trunc_by((width - len), 2)
			List.concat(tw_spaces(pad), s)
		}) })
	})

	text_right_align : List(U8), I64 -> List(U8)
	text_right_align = |s, width| ({
		len = Text.len(s)
		(if (len >= width) { s } else { List.concat(tw_spaces((width - len)), s) })
	})

	tw_spaces : I64 -> List(U8)
	tw_spaces = |n| tw_spaces_loop(n, [])

	tw_spaces_loop : I64, List(U8) -> List(U8)
	tw_spaces_loop = |n, acc| (if (n <= 0) { acc } else { tw_spaces_loop((n - 1), List.concat(acc, [2])) })

	text_box : List(U8), I64 -> List(U8)
	text_box = |s, width| ({
		border = tw_repeat_char([73], (width + 2))
		padded = tw_pad_line(s, width)
		List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([76], border), [76]), [1]), [87, 2]), padded), [2, 87]), [1]), [76]), border), [76])
	})

	tw_pad_line : List(U8), I64 -> List(U8)
	tw_pad_line = |s, width| ({
		len = Text.len(s)
		(if (len >= width) { s } else { List.concat(s, tw_spaces((width - len))) })
	})

	tw_repeat_char : List(U8), I64 -> List(U8)
	tw_repeat_char = |ch, n| tw_rep_loop(ch, n, [])

	tw_rep_loop : List(U8), I64, List(U8) -> List(U8)
	tw_rep_loop = |ch, n, acc| (if (n <= 0) { acc } else { tw_rep_loop(ch, (n - 1), List.concat(acc, ch)) })
}
