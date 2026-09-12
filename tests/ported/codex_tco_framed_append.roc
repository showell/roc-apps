# tco-framed-append
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tco-framed-append.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     01 start
#     02 append-text 4
#     03 done

app [main!] { cdx: "./codex/main.roc" }

import cdx.Cce

# TcoFramedAppendTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Step : [Go, Stop]

step_of : I64 -> Step
step_of = |n| (if (n <= 0) { Stop } else { Go })

by_append_text : I64, Str -> Str
by_append_text = |n, acc| (match step_of(n) {
	Stop => acc
	Go => by_append_text((n - 1), Str.concat(acc, "x"))
})

eq_step : Step, Step -> Bool
eq_step = |ex, ey| (match ex {
	Go => (match ey {
		Go => True
		_ => False
	})
	Stop => (match ey {
		Stop => True
		_ => False
	})
})

# --- Entry ---

main! = |_args| {
	line!("01 start")
	line!(Str.concat("02 append-text ", I64.to_str(Cce.length(by_append_text(4, "")))))
	line!("03 done")
	Ok({})
}
