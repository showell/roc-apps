# Locale -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

Locale :: [].{
	TextDirection : [DirLTR, DirRTL]
	Locale := { lang_tag : CceText, direction : Locale.TextDirection, decimal_sep : CceText, thousands_sep : CceText, date_order : Locale.DateOrder }.{
		is_eq : Locale.Locale, Locale.Locale -> Bool
		is_eq = |a, b| a.lang_tag == b.lang_tag and a.direction == b.direction and a.decimal_sep == b.decimal_sep and a.thousands_sep == b.thousands_sep and a.date_order == b.date_order
	}
	DateOrder : [DateYMD, DateMDY, DateDMY]

	locale_en_us : Locale.Locale
	locale_en_us = Locale.Locale.{ lang_tag: "en-US", direction: DirLTR, decimal_sep: ".", thousands_sep: ",", date_order: DateMDY }

	locale_en_gb : Locale.Locale
	locale_en_gb = Locale.Locale.{ lang_tag: "en-GB", direction: DirLTR, decimal_sep: ".", thousands_sep: ",", date_order: DateDMY }

	locale_de : Locale.Locale
	locale_de = Locale.Locale.{ lang_tag: "de", direction: DirLTR, decimal_sep: ",", thousands_sep: ".", date_order: DateDMY }

	locale_ja : Locale.Locale
	locale_ja = Locale.Locale.{ lang_tag: "ja", direction: DirLTR, decimal_sep: ".", thousands_sep: ",", date_order: DateYMD }

	locale_ar : Locale.Locale
	locale_ar = Locale.Locale.{ lang_tag: "ar", direction: DirRTL, decimal_sep: ".", thousands_sep: ",", date_order: DateDMY }

	locale_new : CceText -> Locale.Locale
	locale_new = |tag| (if (tag == "en-US") { locale_en_us } else { (if (tag == "en-GB") { locale_en_gb } else { (if (tag == "de") { locale_de } else { (if (tag == "ja") { locale_ja } else { (if (tag == "ar") { locale_ar } else { locale_en_us }) }) }) }) })

	locale_direction : Locale.Locale -> Locale.TextDirection
	locale_direction = |loc| loc.direction

	locale_decimal_sep : Locale.Locale -> CceText
	locale_decimal_sep = |loc| loc.decimal_sep

	locale_thousands_sep : Locale.Locale -> CceText
	locale_thousands_sep = |loc| loc.thousands_sep

	locale_is_rtl : Locale.Locale -> Bool
	locale_is_rtl = |loc| (match loc.direction {
		DirRTL => True
		DirLTR => False
	})

	locale_format_number : Locale.Locale, I64 -> CceText
	locale_format_number = |loc, n| (if (n < 0) { CceText.concat("-", locale_format_positive(loc, (0 - n))) } else { locale_format_positive(loc, n) })

	locale_format_positive : Locale.Locale, I64 -> CceText
	locale_format_positive = |loc, n| ({
		raw : CceText
		raw = CceText.show_int(n)
		(if (CceText.len(loc.thousands_sep) == 0) { raw } else { locale_insert_thousands(raw, loc.thousands_sep) })
	})

	locale_insert_thousands : CceText, CceText -> CceText
	locale_insert_thousands = |raw, sep| ({
		len : I64
		len = CceText.len(raw)
		(if (len <= 3) { raw } else { locale_insert_loop(raw, sep, (len - 1), 0, "") })
	})

	locale_insert_loop : CceText, CceText, I64, I64, CceText -> CceText
	locale_insert_loop = |raw, sep, i, count, acc| (if (i < 0) { acc } else { ({
		c : CceText
		c = CceText.char_to_text(CceText.char_at(raw, i))
		s : CceText
		s = (if (count > 0) { (if ((count - (I64.div_trunc_by(count, 3) * 3)) == 0) { sep } else { "" }) } else { "" })
		locale_insert_loop(raw, sep, (i - 1), (count + 1), CceText.concat(CceText.concat(c, s), acc))
	}) })

	locale_format_date : Locale.Locale, I64, I64, I64 -> CceText
	locale_format_date = |loc, year, month, day| ({
		y : CceText
		y = CceText.show_int(year)
		m : CceText
		m = locale_two_digit(month)
		d : CceText
		d = locale_two_digit(day)
		(match loc.date_order {
			DateYMD => CceText.concat(CceText.concat(CceText.concat(CceText.concat(y, "-"), m), "-"), d)
			DateMDY => CceText.concat(CceText.concat(CceText.concat(CceText.concat(m, "/"), d), "/"), y)
			DateDMY => CceText.concat(CceText.concat(CceText.concat(CceText.concat(d, "/"), m), "/"), y)
		})
	})

	locale_two_digit : I64 -> CceText
	locale_two_digit = |n| (if (n < 10) { CceText.concat("0", CceText.show_int(n)) } else { CceText.show_int(n) })

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
