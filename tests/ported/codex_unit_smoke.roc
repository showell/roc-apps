# unit-smoke
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/unit-smoke.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42
#     100
#     50
#     126
#     True
#     120
#     99

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# UnitSmoke -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Second : I64
Meter : I64
Minute : I64

make_duration : I64 -> Second
make_duration = |n| n

minute_to_Second : Minute -> Second
minute_to_Second = |cv| (cv * 60)

# --- Entry ---

main! = |_args| {
	({
		t1 : Second
		t1 = 42
		t2 : Second
		t2 = 8
		d : Meter
		d = 100
		sum : Second
		sum = (t1 + t2)
		scaled : Second
		scaled = (t1 * 3)
		m : Minute
		m = 2
		s : Second
		s = minute_to_Second(m)
		built : Second
		built = make_duration(99)
		({
			line!(CceText.printed(CceText.show_int(t1)))
			line!(CceText.printed(CceText.show_int(d)))
			line!(CceText.printed(CceText.show_int(sum)))
			line!(CceText.printed(CceText.show_int(scaled)))
			line!(CceText.printed((if (t1 > t2) { "True" } else { "False" })))
			line!(CceText.printed(CceText.show_int(s)))
			line!(CceText.printed(CceText.show_int(built)))
		})
	})
	Ok({})
}
