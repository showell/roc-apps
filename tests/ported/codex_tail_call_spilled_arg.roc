# tail-call-spilled-arg
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/tail-call-spilled-arg.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     loop8 5

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# TailCallSpilledArg -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

has_ : I64 -> Bool
has_ = |i| ((i == 0) or (i == 5))

dist : I64 -> I64
dist = |i| (if (i == 0) { 90 } else { (if (i == 5) { 10 } else { 50 }) })

loop8 : I64, I64, I64, I64, I64, I64, I64, I64 -> I64
loop8 = |a, b, c, home, n, i, best, bd| (if (i >= n) { best } else { (if (i == home) { loop8(a, b, c, home, n, (i + 1), best, bd) } else { ({
	d : I64
	d = dist(i)
	take : Bool
	take = (has_(i) and ((best < 0) or (d < bd)))
	(if take { loop8(a, b, c, home, n, (i + 1), i, d) } else { loop8(a, b, c, home, n, (i + 1), best, bd) })
}) }) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("loop8 ", CceText.show_int(loop8(0, 0, 0, 4, 6, 0, (0 - 1), 0)))))
	Ok({})
}
