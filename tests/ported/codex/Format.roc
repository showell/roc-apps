# Format -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

Format :: [].{

	fmt_pad_left : Text, I64, Text -> Text
	fmt_pad_left = |s, width, fill| ({
		deficit = (width - Text.len(s))
		(if (deficit <= 0) { s } else { Text.concat(fmt_repeat(fill, deficit), s) })
	})

	fmt_pad_right : Text, I64, Text -> Text
	fmt_pad_right = |s, width, fill| ({
		deficit = (width - Text.len(s))
		(if (deficit <= 0) { s } else { Text.concat(s, fmt_repeat(fill, deficit)) })
	})

	fmt_center : Text, I64, Text -> Text
	fmt_center = |s, width, fill| ({
		deficit = (width - Text.len(s))
		(if (deficit <= 0) { s } else { ({
			left = I64.div_trunc_by(deficit, 2)
			right = (deficit - left)
			Text.concat(Text.concat(fmt_repeat(fill, left), s), fmt_repeat(fill, right))
		}) })
	})

	fmt_repeat : Text, I64 -> Text
	fmt_repeat = |s, n| fmt_repeat_loop(s, n, "")

	fmt_repeat_loop : Text, I64, Text -> Text
	fmt_repeat_loop = |s, n, acc| (if (n <= 0) { acc } else { fmt_repeat_loop(s, (n - 1), Text.concat(acc, s)) })

	fmt_join : List(Text), Text -> Text
	fmt_join = |xs, sep| fmt_join_loop(xs, sep, 0, U64.to_i64_wrap(List.len(xs)), "")

	fmt_join_loop : List(Text), Text, I64, I64, Text -> Text
	fmt_join_loop = |xs, sep, i, len, acc| (if (i >= len) { acc } else { ({
		prefix = (if (i == 0) { "" } else { sep })
		fmt_join_loop(xs, sep, (i + 1), len, Text.concat(Text.concat(acc, prefix), (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))
	}) })

	fmt_join_ints : List(I64), Text -> Text
	fmt_join_ints = |xs, sep| fmt_join_ints_loop(xs, sep, 0, U64.to_i64_wrap(List.len(xs)), "")

	fmt_join_ints_loop : List(I64), Text, I64, I64, Text -> Text
	fmt_join_ints_loop = |xs, sep, i, len, acc| (if (i >= len) { acc } else { ({
		prefix = (if (i == 0) { "" } else { sep })
		fmt_join_ints_loop(xs, sep, (i + 1), len, Text.concat(Text.concat(acc, prefix), Text.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })

	fmt_commas : I64 -> Text
	fmt_commas = |n| (if (n < 0) { Text.concat("-", fmt_commas((0 - n))) } else { ({
		raw = Text.show_int(n)
		fmt_insert_commas(raw)
	}) })

	fmt_insert_commas : Text -> Text
	fmt_insert_commas = |s| ({
		len = Text.len(s)
		(if (len <= 3) { s } else { fmt_comma_loop(s, (len - 1), 0, "") })
	})

	fmt_comma_loop : Text, I64, I64, Text -> Text
	fmt_comma_loop = |s, i, count, acc| (if (i < 0) { acc } else { ({
		c = Text.char_to_text(Text.char_at(s, i))
		sep = (if (count > 0) { (if ((count - (I64.div_trunc_by(count, 3) * 3)) == 0) { "," } else { "" }) } else { "" })
		fmt_comma_loop(s, (i - 1), (count + 1), Text.concat(Text.concat(c, sep), acc))
	}) })

	fmt_fixed_width : I64, I64 -> Text
	fmt_fixed_width = |n, width| fmt_pad_left(Text.show_int(n), width, " ")

	fmt_hex : I64 -> Text
	fmt_hex = |n| (if (n == 0) { "0" } else { (if (n < 0) { Text.concat("-", fmt_hex((0 - n))) } else { fmt_hex_loop(n, "") }) })

	fmt_hex_loop : I64, Text -> Text
	fmt_hex_loop = |n, acc| (if (n == 0) { acc } else { ({
		digit = I64.bitwise_and(n, 15)
		c = fmt_hex_digit(digit)
		fmt_hex_loop(I64.shr_zf_wrap(n, I64.to_u8_wrap(4)), Text.concat(c, acc))
	}) })

	fmt_hex_digit : I64 -> Text
	fmt_hex_digit = |d| (if (d < 10) { Text.show_int(d) } else { (if (d == 10) { "a" } else { (if (d == 11) { "b" } else { (if (d == 12) { "c" } else { (if (d == 13) { "d" } else { (if (d == 14) { "e" } else { "f" }) }) }) }) }) })

	fmt_hex_pad : I64, I64 -> Text
	fmt_hex_pad = |n, width| fmt_pad_left(fmt_hex(n), width, "0")

	fmt_bool : Bool -> Text
	fmt_bool = |b| (if b { "true" } else { "false" })

	fmt_yes_no : Bool -> Text
	fmt_yes_no = |b| (if b { "yes" } else { "no" })
}
