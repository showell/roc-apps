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

	text_ends_with : CceText, CceText -> Bool
	text_ends_with = |s, suffix| ({
		slen : I64
		slen = CceText.len(s)
		plen : I64
		plen = CceText.len(suffix)
		(if (plen > slen) { False } else { str_prefix_match_at(s, suffix, (slen - plen), 0, plen) })
	})

	str_prefix_match_at : CceText, CceText, I64, I64, I64 -> Bool
	str_prefix_match_at = |s, prefix, offset, i, len| (if (i >= len) { True } else { (if (CceText.char_at(s, (offset + i)) != CceText.char_at(prefix, i)) { False } else { str_prefix_match_at(s, prefix, offset, (i + 1), len) }) })
}
