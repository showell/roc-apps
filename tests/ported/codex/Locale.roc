# Locale -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Text

Locale :: [].{
	TextDirection : [DirLTR, DirRTL]
	Locale : { lang_tag : List(U8), direction : Locale.TextDirection, decimal_sep : List(U8), thousands_sep : List(U8), date_order : Locale.DateOrder }
	DateOrder : [DateYMD, DateMDY, DateDMY]

	locale_en_us : Locale.Locale
	locale_en_us = { lang_tag: [13, 18, 73, 51, 45], direction: DirLTR, decimal_sep: [65], thousands_sep: [66], date_order: DateMDY }

	locale_en_gb : Locale.Locale
	locale_en_gb = { lang_tag: [13, 18, 73, 55, 58], direction: DirLTR, decimal_sep: [65], thousands_sep: [66], date_order: DateDMY }

	locale_de : Locale.Locale
	locale_de = { lang_tag: [22, 13], direction: DirLTR, decimal_sep: [66], thousands_sep: [65], date_order: DateDMY }

	locale_ja : Locale.Locale
	locale_ja = { lang_tag: [35, 15], direction: DirLTR, decimal_sep: [65], thousands_sep: [66], date_order: DateYMD }

	locale_ar : Locale.Locale
	locale_ar = { lang_tag: [15, 21], direction: DirRTL, decimal_sep: [65], thousands_sep: [66], date_order: DateDMY }

	locale_new : List(U8) -> Locale.Locale
	locale_new = |tag| (if (tag == [13, 18, 73, 51, 45]) { locale_en_us } else { (if (tag == [13, 18, 73, 55, 58]) { locale_en_gb } else { (if (tag == [22, 13]) { locale_de } else { (if (tag == [35, 15]) { locale_ja } else { (if (tag == [15, 21]) { locale_ar } else { locale_en_us }) }) }) }) })

	locale_direction : Locale.Locale -> Locale.TextDirection
	locale_direction = |loc| loc.direction

	locale_decimal_sep : Locale.Locale -> List(U8)
	locale_decimal_sep = |loc| loc.decimal_sep

	locale_thousands_sep : Locale.Locale -> List(U8)
	locale_thousands_sep = |loc| loc.thousands_sep

	locale_is_rtl : Locale.Locale -> Bool
	locale_is_rtl = |loc| (match loc.direction {
		DirRTL => True
		DirLTR => False
	})

	locale_format_number : Locale.Locale, I64 -> List(U8)
	locale_format_number = |loc, n| (if (n < 0) { List.concat([73], locale_format_positive(loc, (0 - n))) } else { locale_format_positive(loc, n) })

	locale_format_positive : Locale.Locale, I64 -> List(U8)
	locale_format_positive = |loc, n| ({
		raw = Text.show_int(n)
		(if (Text.len(loc.thousands_sep) == 0) { raw } else { locale_insert_thousands(raw, loc.thousands_sep) })
	})

	locale_insert_thousands : List(U8), List(U8) -> List(U8)
	locale_insert_thousands = |raw, sep| ({
		len = Text.len(raw)
		(if (len <= 3) { raw } else { locale_insert_loop(raw, sep, (len - 1), 0, []) })
	})

	locale_insert_loop : List(U8), List(U8), I64, I64, List(U8) -> List(U8)
	locale_insert_loop = |raw, sep, i, count, acc| (if (i < 0) { acc } else { ({
		c = Text.char_to_text(Text.char_at(raw, i))
		s = (if (count > 0) { (if ((count - (I64.div_trunc_by(count, 3) * 3)) == 0) { sep } else { [] }) } else { [] })
		locale_insert_loop(raw, sep, (i - 1), (count + 1), List.concat(List.concat(c, s), acc))
	}) })

	locale_format_date : Locale.Locale, I64, I64, I64 -> List(U8)
	locale_format_date = |loc, year, month, day| ({
		y = Text.show_int(year)
		m = locale_two_digit(month)
		d = locale_two_digit(day)
		(match loc.date_order {
			DateYMD => List.concat(List.concat(List.concat(List.concat(y, [73]), m), [73]), d)
			DateMDY => List.concat(List.concat(List.concat(List.concat(m, [81]), d), [81]), y)
			DateDMY => List.concat(List.concat(List.concat(List.concat(d, [81]), m), [81]), y)
		})
	})

	locale_two_digit : I64 -> List(U8)
	locale_two_digit = |n| (if (n < 10) { List.concat([3], Text.show_int(n)) } else { Text.show_int(n) })

	eq_TextDirection : Locale.TextDirection, Locale.TextDirection -> Bool
	eq_TextDirection = |ex, ey| (match ex {
		DirLTR => (match ey {
			DirLTR => True
			_ => False
		})
		DirRTL => (match ey {
			DirRTL => True
			_ => False
		})
	})

	eq_DateOrder : Locale.DateOrder, Locale.DateOrder -> Bool
	eq_DateOrder = |ex, ey| (match ex {
		DateYMD => (match ey {
			DateYMD => True
			_ => False
		})
		DateMDY => (match ey {
			DateMDY => True
			_ => False
		})
		DateDMY => (match ey {
			DateDMY => True
			_ => False
		})
	})
}
