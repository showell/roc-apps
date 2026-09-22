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

import cdx.Text

# TcoFramedAppendTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Step : [Go, Stop]

step_of : I64 -> Step
step_of = |n| (if (n <= 0) { Stop } else { Go })

by_append_text : I64, List(U8) -> List(U8)
by_append_text = |n, acc| (match step_of(n) {
	Stop => acc
	Go => by_append_text((n - 1), List.concat(acc, [36]))
})

eq_Step : Step, Step -> Bool
eq_Step = |ex, ey| (match ex {
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
	line!(Text.printed([3, 4, 2, 19, 14, 15, 21, 14]))
	line!(Text.printed(List.concat([3, 5, 2, 15, 31, 31, 13, 18, 22, 73, 14, 13, 36, 14, 2], Text.show_int(Text.len(by_append_text(4, []))))))
	line!(Text.printed([3, 6, 2, 22, 16, 18, 13]))
	Ok({})
}
