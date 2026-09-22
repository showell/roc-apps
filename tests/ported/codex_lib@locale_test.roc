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

import cdx.Locale
import cdx.Text

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
			line!(Text.printed(List.concat([25, 19, 73, 18, 25, 26, 77], Locale.locale_format_number(us, 1234567))))
			line!(Text.printed(List.concat([22, 13, 73, 18, 25, 26, 77], Locale.locale_format_number(de, 1234567))))
			line!(Text.printed(List.concat([19, 26, 15, 23, 23, 77], Locale.locale_format_number(us, 42))))
			line!(Text.printed(List.concat([18, 13, 29, 77], Locale.locale_format_number(us, (0 - 9876)))))
			line!(Text.printed(List.concat([25, 19, 73, 22, 15, 14, 13, 77], Locale.locale_format_date(us, 2026, 5, 8))))
			line!(Text.printed(List.concat([22, 13, 73, 22, 15, 14, 13, 77], Locale.locale_format_date(de, 2026, 5, 8))))
			line!(Text.printed(List.concat([35, 15, 73, 22, 15, 14, 13, 77], Locale.locale_format_date(ja, 2026, 5, 8))))
			line!(Text.printed(List.concat([25, 19, 73, 22, 17, 21, 77], (if Locale.locale_is_rtl(us) { [21, 14, 23] } else { [23, 14, 21] }))))
			line!(Text.printed(List.concat([15, 21, 73, 22, 17, 21, 77], (if Locale.locale_is_rtl(ar) { [21, 14, 23] } else { [23, 14, 21] }))))
			line!(Text.printed(List.concat([22, 13, 73, 19, 13, 31, 77], Locale.locale_decimal_sep(de))))
			line!(Text.printed(List.concat([22, 13, 73, 14, 20, 16, 25, 77], Locale.locale_thousands_sep(de))))
		})
	})
	Ok({})
}
