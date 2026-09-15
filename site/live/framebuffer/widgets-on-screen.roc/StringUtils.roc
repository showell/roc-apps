# StringUtils -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import Cce

StringUtils :: [].{

	text_starts_with : Str, Str -> Bool
	text_starts_with = |s, prefix| ({
		plen = Cce.length(prefix)
		(if (plen > Cce.length(s)) { False } else { str_prefix_match(s, prefix, 0, plen) })
	})

	str_prefix_match : Str, Str, I64, I64 -> Bool
	str_prefix_match = |s, prefix, i, len| (if (i >= len) { True } else { (if (Cce.at_or_crash(s, i) != Cce.at_or_crash(prefix, i)) { False } else { str_prefix_match(s, prefix, (i + 1), len) }) })

	text_ends_with : Str, Str -> Bool
	text_ends_with = |s, suffix| ({
		slen = Cce.length(s)
		plen = Cce.length(suffix)
		(if (plen > slen) { False } else { str_prefix_match_at(s, suffix, (slen - plen), 0, plen) })
	})

	str_prefix_match_at : Str, Str, I64, I64, I64 -> Bool
	str_prefix_match_at = |s, prefix, offset, i, len| (if (i >= len) { True } else { (if (Cce.at_or_crash(s, (offset + i)) != Cce.at_or_crash(prefix, i)) { False } else { str_prefix_match_at(s, prefix, offset, (i + 1), len) }) })

	text_contains : Str, Str -> Bool
	text_contains = |s, sub| (text_index_of(s, sub) >= 0)

	text_index_of : Str, Str -> I64
	text_index_of = |s, sub| ({
		slen = Cce.length(s)
		sublen = Cce.length(sub)
		(if (sublen > slen) { (0 - 1) } else { str_index_loop(s, sub, 0, ((slen - sublen) + 1), sublen) })
	})

	str_index_loop : Str, Str, I64, I64, I64 -> I64
	str_index_loop = |s, sub, i, limit, sublen| (if (i >= limit) { (0 - 1) } else { (if str_prefix_match_at(s, sub, i, 0, sublen) { i } else { str_index_loop(s, sub, (i + 1), limit, sublen) }) })

	text_count : Str, Str -> I64
	text_count = |s, sub| str_count_loop(s, sub, 0, Cce.length(s), Cce.length(sub), 0)

	str_count_loop : Str, Str, I64, I64, I64, I64 -> I64
	str_count_loop = |s, sub, i, slen, sublen, acc| (if (i > (slen - sublen)) { acc } else { (if str_prefix_match_at(s, sub, i, 0, sublen) { str_count_loop(s, sub, (i + sublen), slen, sublen, (acc + 1)) } else { str_count_loop(s, sub, (i + 1), slen, sublen, acc) }) })

	text_replace : Str, Str, Str -> Str
	text_replace = |s, old, new| (if (Cce.length(old) == 0) { s } else { str_replace_loop(s, old, new, 0, Cce.length(s), Cce.length(old), "") })

	str_replace_loop : Str, Str, Str, I64, I64, I64, Str -> Str
	str_replace_loop = |s, old, new, i, slen, oldlen, acc| (if (i >= slen) { acc } else { (if (i <= (slen - oldlen)) { (if str_prefix_match_at(s, old, i, 0, oldlen) { str_replace_loop(s, old, new, (i + oldlen), slen, oldlen, Str.concat(acc, new)) } else { str_replace_loop(s, old, new, (i + 1), slen, oldlen, Str.concat(acc, Cce.text(Cce.at_or_crash(s, i)))) }) } else { str_replace_loop(s, old, new, (i + 1), slen, oldlen, Str.concat(acc, Cce.text(Cce.at_or_crash(s, i)))) }) })

	text_reverse : Str -> Str
	text_reverse = |s| str_rev_loop(s, (Cce.length(s) - 1), "")

	str_rev_loop : Str, I64, Str -> Str
	str_rev_loop = |s, i, acc| (if (i < 0) { acc } else { str_rev_loop(s, (i - 1), Str.concat(acc, Cce.text(Cce.at_or_crash(s, i)))) })

	text_to_upper : Str -> Str
	text_to_upper = |s| str_case_loop(s, CCE.to_upper, 0, Cce.length(s), "")

	text_to_lower : Str -> Str
	text_to_lower = |s| str_case_loop(s, CCE.to_lower, 0, Cce.length(s), "")

	str_case_loop : Str, (I64 -> I64), I64, I64, Str -> Str
	str_case_loop = |s, f, i, len, acc| (if (i >= len) { acc } else { str_case_loop(s, f, (i + 1), len, Str.concat(acc, Cce.text(f(Cce.at_or_crash(s, i))))) })

	text_pad_left : Str, I64, Str -> Str
	text_pad_left = |s, width, fill| (if (Cce.length(s) >= width) { s } else { text_pad_left(Str.concat(fill, s), width, fill) })

	text_pad_right : Str, I64, Str -> Str
	text_pad_right = |s, width, fill| (if (Cce.length(s) >= width) { s } else { text_pad_right(Str.concat(s, fill), width, fill) })

	text_substring : Str, I64, I64 -> Str
	text_substring = |s, start, len| Cce.substring(s, start, len)

	text_take : Str, I64 -> Str
	text_take = |s, n| Cce.substring(s, 0, n)

	text_drop : Str, I64 -> Str
	text_drop = |s, n| Cce.substring(s, n, (Cce.length(s) - n))

	text_join : Str, List(Str) -> Str
	text_join = |sep, parts| str_join_loop(sep, parts, 0, U64.to_i64_wrap(List.len(parts)), "")

	str_join_loop : Str, List(Str), I64, I64, Str -> Str
	str_join_loop = |sep, parts, i, n, acc| (if (i >= n) { acc } else { ({
		prefix = (if (i == 0) { "" } else { sep })
		str_join_loop(sep, parts, (i + 1), n, Str.concat(Str.concat(acc, prefix), (List.get(parts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))
	}) })
}
