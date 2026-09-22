# Format -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

Format :: [].{

	fmt_pad_left : List(U8), I64, List(U8) -> List(U8)
	fmt_pad_left = |s, width, fill| ({
		deficit = (width - Text.len(s))
		(if (deficit <= 0) { s } else { List.concat(fmt_repeat(fill, deficit), s) })
	})

	fmt_pad_right : List(U8), I64, List(U8) -> List(U8)
	fmt_pad_right = |s, width, fill| ({
		deficit = (width - Text.len(s))
		(if (deficit <= 0) { s } else { List.concat(s, fmt_repeat(fill, deficit)) })
	})

	fmt_center : List(U8), I64, List(U8) -> List(U8)
	fmt_center = |s, width, fill| ({
		deficit = (width - Text.len(s))
		(if (deficit <= 0) { s } else { ({
			left = I64.div_trunc_by(deficit, 2)
			right = (deficit - left)
			List.concat(List.concat(fmt_repeat(fill, left), s), fmt_repeat(fill, right))
		}) })
	})

	fmt_repeat : List(U8), I64 -> List(U8)
	fmt_repeat = |s, n| fmt_repeat_loop(s, n, [])

	fmt_repeat_loop : List(U8), I64, List(U8) -> List(U8)
	fmt_repeat_loop = |s, n, acc| (if (n <= 0) { acc } else { fmt_repeat_loop(s, (n - 1), List.concat(acc, s)) })

	fmt_join : List(List(U8)), List(U8) -> List(U8)
	fmt_join = |xs, sep| fmt_join_loop(xs, sep, 0, U64.to_i64_wrap(List.len(xs)), [])

	fmt_join_loop : List(List(U8)), List(U8), I64, I64, List(U8) -> List(U8)
	fmt_join_loop = |xs, sep, i, len, acc| (if (i >= len) { acc } else { ({
		prefix = (if (i == 0) { [] } else { sep })
		fmt_join_loop(xs, sep, (i + 1), len, List.concat(List.concat(acc, prefix), (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))
	}) })

	fmt_join_ints : List(I64), List(U8) -> List(U8)
	fmt_join_ints = |xs, sep| fmt_join_ints_loop(xs, sep, 0, U64.to_i64_wrap(List.len(xs)), [])

	fmt_join_ints_loop : List(I64), List(U8), I64, I64, List(U8) -> List(U8)
	fmt_join_ints_loop = |xs, sep, i, len, acc| (if (i >= len) { acc } else { ({
		prefix = (if (i == 0) { [] } else { sep })
		fmt_join_ints_loop(xs, sep, (i + 1), len, List.concat(List.concat(acc, prefix), Text.show_int((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })

	fmt_commas : I64 -> List(U8)
	fmt_commas = |n| (if (n < 0) { List.concat([73], fmt_commas((0 - n))) } else { ({
		raw = Text.show_int(n)
		fmt_insert_commas(raw)
	}) })

	fmt_insert_commas : List(U8) -> List(U8)
	fmt_insert_commas = |s| ({
		len = Text.len(s)
		(if (len <= 3) { s } else { fmt_comma_loop(s, (len - 1), 0, []) })
	})

	fmt_comma_loop : List(U8), I64, I64, List(U8) -> List(U8)
	fmt_comma_loop = |s, i, count, acc| (if (i < 0) { acc } else { ({
		c = Text.char_to_text(Text.char_at(s, i))
		sep = (if (count > 0) { (if ((count - (I64.div_trunc_by(count, 3) * 3)) == 0) { [66] } else { [] }) } else { [] })
		fmt_comma_loop(s, (i - 1), (count + 1), List.concat(List.concat(c, sep), acc))
	}) })

	fmt_fixed_width : I64, I64 -> List(U8)
	fmt_fixed_width = |n, width| fmt_pad_left(Text.show_int(n), width, [2])

	fmt_hex : I64 -> List(U8)
	fmt_hex = |n| (if (n == 0) { [3] } else { (if (n < 0) { List.concat([73], fmt_hex((0 - n))) } else { fmt_hex_loop(n, []) }) })

	fmt_hex_loop : I64, List(U8) -> List(U8)
	fmt_hex_loop = |n, acc| (if (n == 0) { acc } else { ({
		digit = I64.bitwise_and(n, 15)
		c = fmt_hex_digit(digit)
		fmt_hex_loop(I64.shr_zf_wrap(n, I64.to_u8_wrap(4)), List.concat(c, acc))
	}) })

	fmt_hex_digit : I64 -> List(U8)
	fmt_hex_digit = |d| (if (d < 10) { Text.show_int(d) } else { (if (d == 10) { [15] } else { (if (d == 11) { [32] } else { (if (d == 12) { [24] } else { (if (d == 13) { [22] } else { (if (d == 14) { [13] } else { [28] }) }) }) }) }) })

	fmt_hex_pad : I64, I64 -> List(U8)
	fmt_hex_pad = |n, width| fmt_pad_left(fmt_hex(n), width, [3])

	fmt_bool : Bool -> List(U8)
	fmt_bool = |b| (if b { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] })

	fmt_yes_no : Bool -> List(U8)
	fmt_yes_no = |b| (if b { [30, 13, 19] } else { [18, 16] })
}
