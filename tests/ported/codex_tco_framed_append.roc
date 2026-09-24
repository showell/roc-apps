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

by_append_text : I64, Text -> Text
by_append_text = |n, acc| (match step_of(n) {
	Stop => acc
	Go => by_append_text((n - 1), Text.concat(acc, "x"))
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
	line!(Text.printed("01 start"))
	line!(Text.printed(Text.concat("02 append-text ", Text.show_int(Text.len(by_append_text(4, ""))))))
	line!(Text.printed("03 done"))
	Ok({})
}
