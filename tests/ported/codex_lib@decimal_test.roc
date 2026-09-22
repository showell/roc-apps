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

import cdx.Decimal
import cdx.Text

# DecimalTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		a = Decimal.dec_from_parts(12, 50, 2)
		b = Decimal.dec_from_parts(3, 25, 2)
		({
			line!(Text.printed(List.concat([15, 77], Decimal.dec_to_text(a))))
			line!(Text.printed(List.concat([32, 77], Decimal.dec_to_text(b))))
			line!(Text.printed(List.concat([15, 76, 32, 77], Decimal.dec_to_text(Decimal.dec_add(a, b)))))
			line!(Text.printed(List.concat([15, 73, 32, 77], Decimal.dec_to_text(Decimal.dec_sub(a, b)))))
			line!(Text.printed(List.concat([15, 78, 32, 77], Decimal.dec_to_text(Decimal.dec_mul(a, b)))))
			line!(Text.printed(List.concat([15, 81, 32, 77], Decimal.dec_to_text(Decimal.dec_div(a, b)))))
			line!(Text.printed(List.concat([18, 13, 29, 77], Decimal.dec_to_text(Decimal.dec_negate(a)))))
			line!(Text.printed(List.concat([21, 16, 25, 18, 22, 77], Decimal.dec_to_text(Decimal.dec_round(Decimal.dec_from_parts(3, 456, 3), 1)))))
			line!(Text.printed(List.concat([28, 23, 16, 16, 21, 77], Decimal.dec_to_text(Decimal.dec_floor(Decimal.dec_from_parts(7, 99, 2))))))
			line!(Text.printed(List.concat([24, 26, 31, 77], Text.show_int(Decimal.dec_compare(a, b)))))
			line!(Text.printed(List.concat([13, 37, 77], (if Decimal.dec_eq(a, a) { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([23, 14, 77], (if Decimal.dec_lt(b, a) { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat([38, 13, 21, 16, 77], (if Decimal.dec_is_zero(Decimal.dec_zero) { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] }))))
			({
				parsed = Decimal.dec_from_text([7, 5, 65, 10, 8], 2)
				line!(Text.printed(List.concat([31, 15, 21, 19, 13, 22, 77], Decimal.dec_to_text(parsed))))
			})
		})
	})
	Ok({})
}
