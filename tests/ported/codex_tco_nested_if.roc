# tco-nested-if
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tco-nested-if.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     arm-then: 15
#     after-arm: 17
#     base: 999

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# TcoNestedIf -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mark : I64 -> I64
mark = |x| x

ptl : I64, I64 -> I64
ptl = |n, s| (if (n <= 0) { 999 } else { (if (s == 1) { ptl((n - 1), s) } else { (if (s == 2) { ptl((n - 1), s) } else { (if (s == 3) { ptl((n - 1), s) } else { (if (s == 4) { ptl((n - 1), s) } else { (if (s == 5) { ptl((n - 1), s) } else { (if (s == 6) { (if (n == 3) { mark(15) } else { ptl((n - 1), s) }) } else { (if (s == 7) { mark(17) } else { 400 }) }) }) }) }) }) }) })

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([15, 21, 26, 73, 14, 20, 13, 18, 69, 2], Text.show_int(ptl(3, 6)))))
	line!(Text.printed(List.concat([15, 28, 14, 13, 21, 73, 15, 21, 26, 69, 2], Text.show_int(ptl(1, 7)))))
	line!(Text.printed(List.concat([32, 15, 19, 13, 69, 2], Text.show_int(ptl(0, 6)))))
	Ok({})
}
