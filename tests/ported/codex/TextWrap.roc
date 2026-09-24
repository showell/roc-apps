# TextWrap -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

TextWrap :: [].{

	text_wrap : CceText, I64 -> CceText
	text_wrap = |s, width| ({
		words : List(CceText)
		words = CceText.split(s, " ")
		wrap_words(words, width, 0, U64.to_i64_wrap(List.len(words)), 0, "")
	})

	wrap_words : List(CceText), I64, I64, I64, I64, CceText -> CceText
	wrap_words = |words, width, i, n, col, acc| (if (i >= n) { acc } else { ({
		word : CceText
		word = (List.get(words, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		wlen : I64
		wlen = CceText.len(word)
		(if (col == 0) { wrap_words(words, width, (i + 1), n, wlen, CceText.concat(acc, word)) } else { (if (((col + 1) + wlen) > width) { wrap_words(words, width, (i + 1), n, wlen, CceText.concat(CceText.concat(acc, "\n"), word)) } else { wrap_words(words, width, (i + 1), n, ((col + 1) + wlen), CceText.concat(CceText.concat(acc, " "), word)) }) })
	}) })

	text_wrap_lines : CceText, I64 -> List(CceText)
	text_wrap_lines = |s, width| ({
		wrapped : CceText
		wrapped = text_wrap(s, width)
		CceText.split(wrapped, "\n")
	})

	text_truncate : CceText, I64, CceText -> CceText
	text_truncate = |s, max_len, ellipsis| (if (CceText.len(s) <= max_len) { s } else { ({
		elen : I64
		elen = CceText.len(ellipsis)
		CceText.concat(tw_take(s, (max_len - elen)), ellipsis)
	}) })

	tw_take : CceText, I64 -> CceText
	tw_take = |s, n| CceText.substring(s, 0, n)

	text_center : CceText, I64 -> CceText
	text_center = |s, width| ({
		len : I64
		len = CceText.len(s)
		(if (len >= width) { s } else { ({
			pad : I64
			pad = I64.div_trunc_by((width - len), 2)
			CceText.concat(tw_spaces(pad), s)
		}) })
	})

	text_right_align : CceText, I64 -> CceText
	text_right_align = |s, width| ({
		len : I64
		len = CceText.len(s)
		(if (len >= width) { s } else { CceText.concat(tw_spaces((width - len)), s) })
	})

	tw_spaces : I64 -> CceText
	tw_spaces = |n| tw_spaces_loop(n, "")

	tw_spaces_loop : I64, CceText -> CceText
	tw_spaces_loop = |n, acc| (if (n <= 0) { acc } else { tw_spaces_loop((n - 1), CceText.concat(acc, " ")) })

	text_box : CceText, I64 -> CceText
	text_box = |s, width| ({
		border : CceText
		border = tw_repeat_char("-", (width + 2))
		padded : CceText
		padded = tw_pad_line(s, width)
		CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("+", border), "+"), "\n"), "| "), padded), " |"), "\n"), "+"), border), "+")
	})

	tw_pad_line : CceText, I64 -> CceText
	tw_pad_line = |s, width| ({
		len : I64
		len = CceText.len(s)
		(if (len >= width) { s } else { CceText.concat(s, tw_spaces((width - len))) })
	})

	tw_repeat_char : CceText, I64 -> CceText
	tw_repeat_char = |ch, n| tw_rep_loop(ch, n, "")

	tw_rep_loop : CceText, I64, CceText -> CceText
	tw_rep_loop = |ch, n, acc| (if (n <= 0) { acc } else { tw_rep_loop(ch, (n - 1), CceText.concat(acc, ch)) })
}
