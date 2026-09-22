# call-clobber
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/call-clobber.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     args 132
#     eq False
#     eqtrue True

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# CallClobber -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

cc_mark : I64
cc_mark = 3

cc_three : I64, I64, I64 -> I64
cc_three = |a, b, c| (if (a > 1000) { cc_three((a - 1), b, c) } else { (((a * 100) + (b * 10)) + c) })

cc_add : I64, I64 -> I64
cc_add = |a, b| (a + b)

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([15, 21, 29, 19, 2], Text.show_int(cc_three(1, cc_mark, 2)))))
	line!(Text.printed(List.concat([13, 37, 2], (if (cc_add(5, (5 + 11)) == 15) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	line!(Text.printed(List.concat([13, 37, 14, 21, 25, 13, 2], (if (cc_add(4, (0 + 11)) == 15) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
	Ok({})
}
