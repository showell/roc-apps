# lib@decimal-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@decimal-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     a=12.50
#     b=3.25
#     a+b=15.75
#     a-b=9.25
#     a*b=40.6250
#     a/b=3.84
#     neg=-12.50
#     round=3.5
#     floor=7
#     cmp=1
#     eq=true
#     lt=true
#     zero=true
#     parsed=42.75

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Decimal

# DecimalTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		a = Decimal.dec_from_parts(12, 50, 2)
		b = Decimal.dec_from_parts(3, 25, 2)
		({
			line!(CceText.printed(CceText.concat("a=", Decimal.dec_to_text(a))))
			line!(CceText.printed(CceText.concat("b=", Decimal.dec_to_text(b))))
			line!(CceText.printed(CceText.concat("a+b=", Decimal.dec_to_text(Decimal.dec_add(a, b)))))
			line!(CceText.printed(CceText.concat("a-b=", Decimal.dec_to_text(Decimal.dec_sub(a, b)))))
			line!(CceText.printed(CceText.concat("a*b=", Decimal.dec_to_text(Decimal.dec_mul(a, b)))))
			line!(CceText.printed(CceText.concat("a/b=", Decimal.dec_to_text(Decimal.dec_div(a, b)))))
			line!(CceText.printed(CceText.concat("neg=", Decimal.dec_to_text(Decimal.dec_negate(a)))))
			line!(CceText.printed(CceText.concat("round=", Decimal.dec_to_text(Decimal.dec_round(Decimal.dec_from_parts(3, 456, 3), 1)))))
			line!(CceText.printed(CceText.concat("floor=", Decimal.dec_to_text(Decimal.dec_floor(Decimal.dec_from_parts(7, 99, 2))))))
			line!(CceText.printed(CceText.concat("cmp=", CceText.show_int(Decimal.dec_compare(a, b)))))
			line!(CceText.printed(CceText.concat("eq=", (if Decimal.dec_eq(a, a) { "true" } else { "false" }))))
			line!(CceText.printed(CceText.concat("lt=", (if Decimal.dec_lt(b, a) { "true" } else { "false" }))))
			line!(CceText.printed(CceText.concat("zero=", (if Decimal.dec_is_zero(Decimal.dec_zero) { "true" } else { "false" }))))
			({
				parsed = Decimal.dec_from_text("42.75", 2)
				line!(CceText.printed(CceText.concat("parsed=", Decimal.dec_to_text(parsed))))
			})
		})
	})
	Ok({})
}
