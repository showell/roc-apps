# Format -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

Format :: [].{

	fmt_pad_left : CceText, I64, CceText -> CceText
	fmt_pad_left = |s, width, fill| ({
		deficit = (width - CceText.len(s))
		(if (deficit <= 0) { s } else { CceText.concat(fmt_repeat(fill, deficit), s) })
	})

	fmt_pad_right : CceText, I64, CceText -> CceText
	fmt_pad_right = |s, width, fill| ({
		deficit = (width - CceText.len(s))
		(if (deficit <= 0) { s } else { CceText.concat(s, fmt_repeat(fill, deficit)) })
	})

	fmt_center : CceText, I64, CceText -> CceText
	fmt_center = |s, width, fill| ({
		deficit = (width - CceText.len(s))
		(if (deficit <= 0) { s } else { ({
			left = I64.div_trunc_by(deficit, 2)
			right = (deficit - left)
			CceText.concat(CceText.concat(fmt_repeat(fill, left), s), fmt_repeat(fill, right))
		}) })
	})

	fmt_repeat : CceText, I64 -> CceText
	fmt_repeat = |s, n| fmt_repeat_loop(s, n, "")

	fmt_repeat_loop : CceText, I64, CceText -> CceText
	fmt_repeat_loop = |s, n, acc| (if (n <= 0) { acc } else { fmt_repeat_loop(s, (n - 1), CceText.concat(acc, s)) })

	fmt_join : List(CceText), CceText -> CceText
	fmt_join = |xs, sep| fmt_join_loop(xs, sep, 0, U64.to_i64_wrap(List.len(xs)), "")

	fmt_join_loop : List(CceText), CceText, I64, I64, CceText -> CceText
	fmt_join_loop = |xs, sep, i, len, acc| (if (i >= len) { acc } else { ({
		prefix = (if (i == 0) { "" } else { sep })
		fmt_join_loop(xs, sep, (i + 1), len, CceText.concat(CceText.concat(acc, prefix), (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))
	}) })

	fmt_join_ints : List(I64), CceText -> CceText
	fmt_join_ints = |xs, sep| fmt_join_ints_loop(xs, sep, 0, U64.to_i64_wrap(List.len(xs)), "")

	fmt_join_ints_loop : List(I64), CceText, I64, I64, CceText -> CceText
	fmt_join_ints_loop = |xs, sep, i, len, acc| (if (i >= len) { acc } else { ({
		prefix = (if (i == 0) { "" } else { sep })
		fmt_join_ints_loop(xs, sep, (i + 1), len, CceText.concat(CceText.concat(acc, prefix), CceText.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })

	fmt_commas : I64 -> CceText
	fmt_commas = |n| (if (n < 0) { CceText.concat("-", fmt_commas((0 - n))) } else { ({
		raw = CceText.show_int(n)
		fmt_insert_commas(raw)
	}) })

	fmt_insert_commas : CceText -> CceText
	fmt_insert_commas = |s| ({
		len = CceText.len(s)
		(if (len <= 3) { s } else { fmt_comma_loop(s, (len - 1), 0, "") })
	})

	fmt_comma_loop : CceText, I64, I64, CceText -> CceText
	fmt_comma_loop = |s, i, count, acc| (if (i < 0) { acc } else { ({
		c = CceText.char_to_text(CceText.char_at(s, i))
		sep = (if (count > 0) { (if ((count - (I64.div_trunc_by(count, 3) * 3)) == 0) { "," } else { "" }) } else { "" })
		fmt_comma_loop(s, (i - 1), (count + 1), CceText.concat(CceText.concat(c, sep), acc))
	}) })

	fmt_fixed_width : I64, I64 -> CceText
	fmt_fixed_width = |n, width| fmt_pad_left(CceText.show_int(n), width, " ")

	fmt_hex : I64 -> CceText
	fmt_hex = |n| (if (n == 0) { "0" } else { (if (n < 0) { CceText.concat("-", fmt_hex((0 - n))) } else { fmt_hex_loop(n, "") }) })

	fmt_hex_loop : I64, CceText -> CceText
	fmt_hex_loop = |n, acc| (if (n == 0) { acc } else { ({
		digit = I64.bitwise_and(n, 15)
		c = fmt_hex_digit(digit)
		fmt_hex_loop(I64.shr_zf_wrap(n, I64.to_u8_wrap(4)), CceText.concat(c, acc))
	}) })

	fmt_hex_digit : I64 -> CceText
	fmt_hex_digit = |d| (if (d < 10) { CceText.show_int(d) } else { (if (d == 10) { "a" } else { (if (d == 11) { "b" } else { (if (d == 12) { "c" } else { (if (d == 13) { "d" } else { (if (d == 14) { "e" } else { "f" }) }) }) }) }) })

	fmt_hex_pad : I64, I64 -> CceText
	fmt_hex_pad = |n, width| fmt_pad_left(fmt_hex(n), width, "0")

	fmt_bool : Bool -> CceText
	fmt_bool = |b| (if b { "true" } else { "false" })

	fmt_yes_no : Bool -> CceText
	fmt_yes_no = |b| (if b { "yes" } else { "no" })
}
