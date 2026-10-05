# StringUtils -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

StringUtils :: [].{

	text_starts_with : CceText, CceText -> Bool
	text_starts_with = |s, prefix| ({
		plen : I64
		plen = CceText.len(prefix)
		(if (plen > CceText.len(s)) { False } else { str_prefix_match(s, prefix, 0, plen) })
	})

	str_prefix_match : CceText, CceText, I64, I64 -> Bool
	str_prefix_match = |s, prefix, i, len| (if (i >= len) { True } else { (if (CceText.char_at(s, i) != CceText.char_at(prefix, i)) { False } else { str_prefix_match(s, prefix, (i + 1), len) }) })

	str_prefix_match_at : CceText, CceText, I64, I64, I64 -> Bool
	str_prefix_match_at = |s, prefix, offset, i, len| (if (i >= len) { True } else { (if (CceText.char_at(s, (offset + i)) != CceText.char_at(prefix, i)) { False } else { str_prefix_match_at(s, prefix, offset, (i + 1), len) }) })

	text_contains : CceText, CceText -> Bool
	text_contains = |s, sub| (text_index_of(s, sub) >= 0)

	text_index_of : CceText, CceText -> I64
	text_index_of = |s, sub| ({
		slen : I64
		slen = CceText.len(s)
		sublen : I64
		sublen = CceText.len(sub)
		(if (sublen > slen) { (0 - 1) } else { str_index_loop(s, sub, 0, ((slen - sublen) + 1), sublen) })
	})

	str_index_loop : CceText, CceText, I64, I64, I64 -> I64
	str_index_loop = |s, sub, i, limit, sublen| (if (i >= limit) { (0 - 1) } else { (if str_prefix_match_at(s, sub, i, 0, sublen) { i } else { str_index_loop(s, sub, (i + 1), limit, sublen) }) })

	text_substring : CceText, I64, I64 -> CceText
	text_substring = |s, start, len| CceText.substring(s, start, len)
}
