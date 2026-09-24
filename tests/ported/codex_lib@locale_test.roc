# lib@locale-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@locale-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     us-num=1,234,567
#     de-num=1.234.567
#     small=42
#     neg=-9,876
#     us-date=05/08/2026
#     de-date=08/05/2026
#     ja-date=2026-05-08
#     us-dir=ltr
#     ar-dir=rtl
#     de-sep=,
#     de-thou=.

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Locale

# LocaleTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		us = Locale.locale_en_us
		de = Locale.locale_de
		ja = Locale.locale_ja
		ar = Locale.locale_ar
		({
			line!(CceText.printed(CceText.concat("us-num=", Locale.locale_format_number(us, 1234567))))
			line!(CceText.printed(CceText.concat("de-num=", Locale.locale_format_number(de, 1234567))))
			line!(CceText.printed(CceText.concat("small=", Locale.locale_format_number(us, 42))))
			line!(CceText.printed(CceText.concat("neg=", Locale.locale_format_number(us, (0 - 9876)))))
			line!(CceText.printed(CceText.concat("us-date=", Locale.locale_format_date(us, 2026, 5, 8))))
			line!(CceText.printed(CceText.concat("de-date=", Locale.locale_format_date(de, 2026, 5, 8))))
			line!(CceText.printed(CceText.concat("ja-date=", Locale.locale_format_date(ja, 2026, 5, 8))))
			line!(CceText.printed(CceText.concat("us-dir=", (if Locale.locale_is_rtl(us) { "rtl" } else { "ltr" }))))
			line!(CceText.printed(CceText.concat("ar-dir=", (if Locale.locale_is_rtl(ar) { "rtl" } else { "ltr" }))))
			line!(CceText.printed(CceText.concat("de-sep=", Locale.locale_decimal_sep(de))))
			line!(CceText.printed(CceText.concat("de-thou=", Locale.locale_thousands_sep(de))))
		})
	})
	Ok({})
}
