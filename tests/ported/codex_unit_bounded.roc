# unit-bounded
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/unit-bounded.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     10
#     0
#     3

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# UnitBounded -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Meter : I64
Span := { m : Meter }.{
	is_eq : Span, Span -> Bool
	is_eq = |a, b| eq_Span(a, b)
}

three : Meter
three = 3

span_of : Meter -> Span
span_of = |x| Span.{ m: x }

eq_Span : Span, Span -> Bool
eq_Span = |ex, ey| (ex.m == ey.m)

# --- Entry ---

main! = |_args| {
	({
		a = Span.{ m: 10 }
		b = span_of(0)
		({
			line!(CceText.printed(CceText.show_int(a.m)))
			line!(CceText.printed(CceText.show_int(b.m)))
			line!(CceText.printed(CceText.show_int(three)))
		})
	})
	Ok({})
}
